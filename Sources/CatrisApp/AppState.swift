import Foundation
import SwiftUI
import CatrisCore

enum AppScreen: Equatable {
    case home
    case mapSelect
    case levelSelect(mapId: String)
    case playing(levelId: Int)
    case catAlbum
}

@MainActor
final class AppState: ObservableObject {
    let catalog: LevelCatalog
    let saveStore: SaveStore
    let sceneController = CatrisSceneController()

    @Published var save: PlayerSaveData
    @Published var screen: AppScreen = .home
    @Published var showSettings = false
    @Published var showSolvedBanner = false
    @Published var isAdmiringSolvedBoard = false
    @Published var hintToast: String? = nil

    @Published var placedCount: Int = 0
    @Published var totalCatsCount: Int = 0
    @Published var canUndo: Bool = false
    @Published var hasSelectedPiece: Bool = false
    @Published var activeLevelId: Int = 1

    var vi: Bool { save.settings.useVietnamese }

    init() {
        let loadedCatalog = (try? LevelCatalog.loadBundled(bundle: .main))
            ?? LevelCatalog(payload: LevelBundlePayload(schemaVersion: 1, maps: [], cats: [], levels: []))
        self.catalog = loadedCatalog
        self.saveStore = SaveStore(directory: SaveStore.defaultDirectory())
        let (loadedSave, _) = saveStore.load()
        self.save = loadedSave
        self.activeLevelId = max(1, min(loadedSave.currentLevelId, max(1, loadedCatalog.levels.count)))

        AudioEngineManager.shared.applySettings(loadedSave.settings)
        HapticManager.shared.isEnabled = loadedSave.settings.hapticsEnabled
        bindSceneCallbacks()
    }

    private func bindSceneCallbacks() {
        sceneController.onBoardChanged = { [weak self] placed, total, undoable, selected in
            Task { @MainActor in
                guard let self else { return }
                self.placedCount = placed
                self.totalCatsCount = total
                self.canUndo = undoable
                self.hasSelectedPiece = (selected != nil)
                self.persistInProgressBoard()
            }
        }

        sceneController.onBoardSolved = { [weak self] levelId in
            Task { @MainActor in
                guard let self else { return }
                self.save.completedLevelIds.insert(levelId)
                // Unlock all cats featured in this board & next level!
                if let board = self.catalog.levelById[levelId] {
                    for cid in board.playableCats { self.save.unlockedCatIds.insert(cid) }
                    for fc in board.fixedCats { self.save.unlockedCatIds.insert(fc.catId) }
                }
                if let next = self.catalog.nextLevel(after: levelId) {
                    self.save.currentLevelId = next.id
                    for cid in next.playableCats { self.save.unlockedCatIds.insert(cid) }
                }
                self.save.activeBoard = nil
                self.persistSave()
                self.showSolvedBanner = true
                self.isAdmiringSolvedBoard = false
            }
        }

        sceneController.onHintMessage = { [weak self] msgVi, msgEn in
            Task { @MainActor in
                guard let self else { return }
                self.hintToast = self.vi ? msgVi : msgEn
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { [weak self] in
                    self?.hintToast = nil
                }
            }
        }

        sceneController.onCatPetted = { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.save.totalPetsGiven += 1
            }
        }
    }

    func startLevel(_ levelId: Int, resumeSaved: Bool = true) {
        guard let board = catalog.levelById[levelId] else { return }
        activeLevelId = levelId
        showSolvedBanner = false
        isAdmiringSolvedBoard = false
        hintToast = nil

        let savedPlacements: [PiecePlacement]? = (resumeSaved && save.activeBoard?.levelId == levelId)
            ? save.activeBoard?.placements
            : nil
        let decorCount = save.unlockedDecorCount(forMap: board.mapId, catalog: catalog)

        for cid in board.playableCats { save.unlockedCatIds.insert(cid) }
        save.currentLevelId = levelId
        persistSave()

        sceneController.loadBoard(
            board,
            catalog: catalog,
            unlockedDecorCount: decorCount,
            savedPlacements: savedPlacements,
            reduceMotion: save.settings.reduceMotion
        )
        screen = .playing(levelId: levelId)
    }

    func continueJourney() {
        let nextUnsolved = catalog.levels.first { !save.completedLevelIds.contains($0.id) }?.id
            ?? save.currentLevelId
        startLevel(nextUnsolved, resumeSaved: true)
    }

    func advanceToNextLevel() {
        if let next = catalog.nextLevel(after: activeLevelId) {
            startLevel(next.id, resumeSaved: false)
        } else {
            screen = .mapSelect
        }
    }

    func updateSettings(_ mutate: (inout GameSettings) -> Void) {
        mutate(&save.settings)
        AudioEngineManager.shared.applySettings(save.settings)
        HapticManager.shared.isEnabled = save.settings.hapticsEnabled
        sceneController.updateReduceMotion(save.settings.reduceMotion)
        persistSave()
    }

    func persistInProgressBoard() {
        guard case .playing(let levelId) = screen else { return }
        save.activeBoard = InProgressBoardSave(
            levelId: levelId,
            placements: sceneController.currentCommittedPlacements(),
            moveCount: sceneController.currentMoveCount()
        )
        persistSave()
    }

    func persistSave() {
        try? saveStore.save(save)
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .background, .inactive:
            sceneController.handleTouchCancelled()
            persistInProgressBoard()
            AudioEngineManager.shared.handleBackground()
        case .active:
            AudioEngineManager.shared.handleForeground()
        @unknown default:
            break
        }
    }
}
