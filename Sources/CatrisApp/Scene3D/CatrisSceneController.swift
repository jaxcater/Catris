import Foundation
import SceneKit
import UIKit
import CatrisCore

/// Master 3D SceneKit runtime controller for Catris portrait gameplay:
/// - Orthographic 78° portrait camera dynamically framing the rug, lower cat tray, and peripheral diorama
/// - Deterministic one-finger touch state machine (Idle -> Pressed -> Dragging -> Commit/Return)
/// - +54 pt upward finger-clearance offset while dragging so the player ALWAYS sees the exact target cells!
/// - Tap-to-rotate, Rotate button, Undo, 3-tier Solver-Aware Hint, Petting & Purring, and Win celebration!
final class CatrisSceneController: NSObject, SCNSceneRendererDelegate {
    let scene = SCNScene()
    private let cameraNode = SCNNode()
    private let dioramaRoot = SCNNode()
    private let boardNode = BoardGridNode()
    private let catsRoot = SCNNode()

    private let dioramaBuilder = DioramaBuilder()
    private var catalog: LevelCatalog!
    private var engine: PackingEngine!
    private var currentBoard: BoardDefinition!
    private var currentMapId: String = "M01"

    private var catNodes: [Int: Cat3DNode] = [:]
    private var lockedCatNodes: [Cat3DNode] = []
    private var traySlots: [Int: (pos: SCNVector3, scale: Float)] = [:]

    // Touch / Interaction State Machine
    private var activePieceIndex: Int? = nil
    private var selectedPieceIndex: Int? = nil
    private var touchStartScreen: CGPoint = .zero
    private var isDragging = false
    private var dragRotation: Int = 0
    private var lastPreviewAnchor: GridPoint? = nil
    private var lastPreviewValid: Bool = false
    private var activeHintCells: [GridPoint] = []
    private var activeHintPiece: Int? = nil
    private var hintTier: Int = 0

    // Callbacks back to SwiftUI AppState
    var onBoardChanged: ((_ placedCount: Int, _ totalCount: Int, _ canUndo: Bool, _ selectedPiece: Int?) -> Void)?
    var onBoardSolved: ((_ levelId: Int) -> Void)?
    var onHintMessage: ((_ messageVi: String, _ messageEn: String) -> Void)?
    var onCatPetted: (() -> Void)?

    private var lastFrameTime: TimeInterval = 0
    private var reduceMotion: Bool = false
    private var boardWorldOffsetZ: Float = -0.22 // Upper-center on portrait screen, leaving generous room for lower cat tray!

    override init() {
        super.init()
        setupCamera()
        scene.rootNode.addChildNode(dioramaRoot)
        scene.rootNode.addChildNode(boardNode)
        scene.rootNode.addChildNode(catsRoot)
        boardNode.position = SCNVector3(0, 0, boardWorldOffsetZ)
    }

    private func setupCamera() {
        let cam = SCNCamera()
        cam.usesOrthographicProjection = true
        cam.orthographicScale = 1.38
        cam.zNear = 0.1
        cam.zFar = 16.0
        cam.wantsHDR = true
        cam.bloomIntensity = 0.14
        cam.bloomThreshold = 1.15
        cam.bloomBlurRadius = 6.0
        cam.wantsExposureAdaptation = false
        cameraNode.camera = cam
        // 78° elevation looking down onto the portrait diorama (shows plush cat thickness & face clearly!)
        cameraNode.position = SCNVector3(0, 4.4, 0.96)
        cameraNode.look(at: SCNVector3(0, 0, 0.04))
        scene.rootNode.addChildNode(cameraNode)
    }

    func loadBoard(
        _ board: BoardDefinition,
        catalog: LevelCatalog,
        unlockedDecorCount: Int,
        savedPlacements: [PiecePlacement]?,
        reduceMotion: Bool
    ) {
        self.catalog = catalog
        self.currentBoard = board
        self.currentMapId = board.mapId
        self.reduceMotion = reduceMotion
        self.engine = PackingEngine(board: board, cats: catalog.catById)

        if let saved = savedPlacements {
            engine.restorePlacements(saved)
        }

        // Reset interaction state
        activePieceIndex = nil
        selectedPieceIndex = nil
        isDragging = false
        clearHint()

        // Adjust orthographic framing cleanly to board dimensions (handles 3x3 up to 6x6 effortlessly!)
        let boardSpanW = Float(board.cols) * BoardGridNode.cellSize + 0.34
        let boardSpanH = Float(board.rows) * BoardGridNode.cellSize + 0.34
        // Portrait aspect ~0.46 -> orthoScale is half vertical span!
        let neededForWidth = (boardSpanW / 0.44) * 0.52
        let neededForHeight = (boardSpanH + 1.05) * 0.54
        let ortho = max(1.26, min(1.88, max(neededForWidth, neededForHeight)))
        cameraNode.camera?.orthographicScale = Double(ortho)
        boardWorldOffsetZ = -ortho * 0.18
        boardNode.position = SCNVector3(0, 0, boardWorldOffsetZ)

        // Rebuild 3D diorama & rug
        dioramaBuilder.buildMap(
            mapId: board.mapId,
            unlockedDecorCount: unlockedDecorCount,
            reduceMotion: reduceMotion,
            into: scene,
            root: dioramaRoot
        )
        boardNode.configure(board: board, mapId: board.mapId)

        // Rebuild 3D cats
        catsRoot.childNodes.forEach { $0.removeFromParentNode() }
        catNodes.removeAll()
        lockedCatNodes.removeAll()

        // 1. Fixed sleeping cats pre-placed on the rug
        for fc in board.fixedCats {
            guard let def = catalog.catById[fc.catId] else { continue }
            let node = Cat3DNode(pieceIndex: -1, catDef: def, isLocked: true)
            node.setReduceMotion(reduceMotion)
            let local = boardNode.localCentroid(forCells: def.cells, anchor: fc.anchor, rotation: fc.rotation, board: board)
            let world = SCNVector3(local.x, 0, local.z + boardWorldOffsetZ)
            let yaw = -Float(fc.rotation) * (.pi / 2)
            node.snapImmediately(worldPos: world, liftY: 0.017, yaw: yaw, scale: 1.0)
            catsRoot.addChildNode(node)
            lockedCatNodes.append(node)
        }

        // 2. Compute responsive lower Portrait Cat Tray slots (2 neat rows below the rug!)
        computeTraySlots(board: board, ortho: ortho)

        // 3. Spawn playable 3D cats
        for (idx, catId) in board.playableCats.enumerated() {
            guard let def = catalog.catById[catId] else { continue }
            let node = Cat3DNode(pieceIndex: idx, catDef: def, isLocked: false)
            node.setReduceMotion(reduceMotion)
            if let placed = engine.placements[idx] {
                let local = boardNode.localCentroid(forCells: def.cells, anchor: placed.anchor, rotation: placed.rotation, board: board)
                let world = SCNVector3(local.x, 0, local.z + boardWorldOffsetZ)
                let yaw = -Float(placed.rotation) * (.pi / 2)
                node.snapImmediately(worldPos: world, liftY: 0.017, yaw: yaw, scale: 1.0)
            } else if let slot = traySlots[idx] {
                node.snapImmediately(worldPos: slot.pos, liftY: 0.014, yaw: 0, scale: slot.scale)
            }
            catsRoot.addChildNode(node)
            catNodes[idx] = node
        }

        AudioEngineManager.shared.setMapAudio(mapId: board.mapId)
        refreshBoardVisuals()
        notifyBoardChanged()
    }

    private func computeTraySlots(board: BoardDefinition, ortho: Float) {
        traySlots.removeAll()
        let count = board.playableCats.count
        guard count > 0 else { return }

        let rugBottomZ = boardWorldOffsetZ + (Float(board.rows) * BoardGridNode.cellSize * 0.5) + 0.16
        let trayWidth = ortho * 0.43 * 1.82
        let rowCount = count <= 4 ? 1 : 2
        let perRow = Int(ceil(Double(count) / Double(rowCount)))
        let trayScale: Float = count >= 7 ? 0.44 : (count >= 5 ? 0.50 : 0.56)

        for i in 0..<count {
            let row = i / perRow
            let col = i % perRow
            let itemsInThisRow = (row == rowCount - 1) ? (count - row * perRow) : perRow
            let spacing = trayWidth / Float(max(1, itemsInThisRow))
            let x = (Float(col) - Float(itemsInThisRow - 1) * 0.5) * spacing
            let z = rugBottomZ + 0.17 + Float(row) * (ortho * 0.25)
            traySlots[i] = (SCNVector3(x, 0, z), trayScale)
        }
    }

    func updateReduceMotion(_ enabled: Bool) {
        reduceMotion = enabled
        dioramaBuilder.updateReduceMotion(enabled)
        catNodes.values.forEach { $0.setReduceMotion(enabled) }
        lockedCatNodes.forEach { $0.setReduceMotion(enabled) }
    }

    func currentCommittedPlacements() -> [PiecePlacement] {
        guard engine != nil else { return [] }
        return Array(engine.placements.values)
    }

    func currentMoveCount() -> Int {
        engine?.moveCount ?? 0
    }

    // MARK: - HUD Actions (Rotate / Undo / Reset / 3-Tier Solver Hint)

    func rotateSelectedOrActivePiece() {
        if let draggingIdx = activePieceIndex, isDragging, let cat = catNodes[draggingIdx] {
            dragRotation = (dragRotation + 1) % 4
            cat.targetYaw = -Float(dragRotation) * (.pi / 2)
            cat.triggerSquash(impulse: -0.9)
            AudioEngineManager.shared.playRotate()
            HapticManager.shared.playRotate()
            updateDragPreview(forPiece: draggingIdx, catNode: cat)
            return
        }

        let targetIdx = selectedPieceIndex ?? engine?.unplacedPieces.first
        guard let idx = targetIdx, let cat = catNodes[idx] else { return }
        if engine.rotatePieceCW(pieceIndex: idx) {
            let newRot = engine.currentRotation(forPiece: idx)
            if let placed = engine.placements[idx] {
                let local = boardNode.localCentroid(forCells: cat.catDef.cells, anchor: placed.anchor, rotation: placed.rotation, board: currentBoard)
                cat.targetWorldPos = SCNVector3(local.x, 0, local.z + boardWorldOffsetZ)
            }
            cat.targetYaw = -Float(newRot) * (.pi / 2)
            cat.triggerSquash(impulse: -0.9)
            AudioEngineManager.shared.playRotate()
            HapticManager.shared.playRotate()
            refreshBoardVisuals()
            notifyBoardChanged()
            checkWinState()
        } else {
            // Cannot rotate in-place on board without collision -> gentle grumble feedback!
            cat.setInvalidWarning(true)
            cat.triggerSquash(impulse: 1.2)
            AudioEngineManager.shared.playCatGrumble(pitchMultiplier: cat.catDef.pitch)
            HapticManager.shared.playInvalid()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                cat.setInvalidWarning(false)
                cat.setExpression(.awake)
            }
        }
    }

    func performUndo() {
        guard let entry = engine?.undo() else { return }
        clearHint()
        AudioEngineManager.shared.playUITap()
        HapticManager.shared.playRotate()
        syncCatToCommittedState(pieceIndex: entry.pieceIndex)
        refreshBoardVisuals()
        notifyBoardChanged()
    }

    func performReset() {
        guard engine != nil else { return }
        clearHint()
        engine.resetBoard()
        AudioEngineManager.shared.playUITap()
        HapticManager.shared.playPickup()
        for idx in catNodes.keys {
            syncCatToCommittedState(pieceIndex: idx)
        }
        refreshBoardVisuals()
        notifyBoardChanged()
    }

    /// 3-Tier Solver-Aware Hint:
    /// Tier 1: Softly highlight target cells & matching cat
    /// Tier 2: Gently auto-place the hinted cat into position (or return blocking cat if dead-end!)
    func triggerSmartHint() {
        guard engine != nil else { return }
        let rec = ExactCoverSolver.computeHint(engine: engine)
        switch rec {
        case .alreadySolved:
            clearHint()
        case .removeBlockingPiece(let pieceIndex, _):
            clearHint()
            activeHintPiece = pieceIndex
            catNodes[pieceIndex]?.setHintHighlight(true)
            catNodes[pieceIndex]?.setInvalidWarning(true)
            AudioEngineManager.shared.playCatChirp(pitchMultiplier: 1.1)
            HapticManager.shared.playRotate()
            if hintTier >= 1 {
                // Tier 2 on dead-end: gently return blocking cat to tray!
                engine.returnToTray(pieceIndex: pieceIndex)
                syncCatToCommittedState(pieceIndex: pieceIndex)
                clearHint()
                refreshBoardVisuals()
                notifyBoardChanged()
            } else {
                hintTier = 1
                onHintMessage?(
                    "Bé mèo đang nhấp nháy chắn chỗ rồi — chạm Gợi ý lần nữa để nhấc ra nhé!",
                    "The highlighted cat is blocking a fit — tap Hint again to lift it!"
                )
            }
        case .placePiece(let placement, let cells):
            if activeHintPiece == placement.pieceIndex && hintTier >= 1 {
                // Tier 2: Place this cat gently for the player!
                clearHint()
                if engine.commitPlacement(pieceIndex: placement.pieceIndex, anchor: placement.anchor, rotation: placement.rotation) {
                    syncCatToCommittedState(pieceIndex: placement.pieceIndex)
                    catNodes[placement.pieceIndex]?.triggerPetReaction()
                    AudioEngineManager.shared.playSnap()
                    HapticManager.shared.playSnap()
                    refreshBoardVisuals()
                    notifyBoardChanged()
                    checkWinState()
                }
            } else {
                clearHint()
                hintTier = 1
                activeHintPiece = placement.pieceIndex
                activeHintCells = cells
                catNodes[placement.pieceIndex]?.setHintHighlight(true)
                AudioEngineManager.shared.playUITap()
                HapticManager.shared.playPickup()
                refreshBoardVisuals()
                onHintMessage?(
                    "Thử xếp bé mèo phát sáng vào ô vàng nhé — bấm Gợi ý lần nữa để đặt giúp!",
                    "Try fitting the glowing cat on the gold cells — tap Hint again to place!"
                )
            }
        }
    }

    private func clearHint() {
        if let p = activeHintPiece {
            catNodes[p]?.setHintHighlight(false)
            catNodes[p]?.setInvalidWarning(false)
        }
        activeHintPiece = nil
        activeHintCells = []
        hintTier = 0
    }

    // MARK: - Touch Handling (Called directly by SceneKitViewport)

    func handleTouchBegan(at screenPt: CGPoint, in view: SCNView) {
        guard engine != nil else { return }
        touchStartScreen = screenPt
        isDragging = false

        // 1. Raycast hit-test against exact cat meshes (plus fallback cell proximity so small/thin shapes feel generous!)
        let hitResults = view.hitTest(screenPt, options: [
            .searchMode: SCNHitTestSearchMode.all.rawValue,
            .ignoreHiddenNodes: true
        ])

        for hit in hitResults {
            if let catNode = findParentCatNode(hit.node) {
                if catNode.isLocked {
                    // Tapping a Fixed Sleeping Cat -> cute grumpy wiggle + sleepy chirp!
                    catNode.triggerLockedWiggle()
                    AudioEngineManager.shared.playCatGrumble(pitchMultiplier: catNode.catDef.pitch)
                    HapticManager.shared.playRotate()
                    return
                }
                selectPiece(catNode.pieceIndex)
                activePieceIndex = catNode.pieceIndex
                dragRotation = engine.currentRotation(forPiece: catNode.pieceIndex)
                return
            }
        }

        // Tapping empty floor deselects smoothly
        selectPiece(nil)
    }

    func handleTouchMoved(to screenPt: CGPoint, in view: SCNView) {
        guard let pieceIdx = activePieceIndex, let cat = catNodes[pieceIdx] else { return }

        let dx = screenPt.x - touchStartScreen.x
        let dy = screenPt.y - touchStartScreen.y
        let dist = hypot(dx, dy)

        if !isDragging && dist > 7.0 {
            isDragging = true
            clearHint()
            cat.targetLiftY = 0.145
            cat.targetScale = 1.0 // Smoothly expand from tray mini-scale to true 1:1 world scale!
            cat.setSelectedOutline(true)
            cat.setExpression(.surprised)
            cat.triggerSquash(impulse: -1.15)
            AudioEngineManager.shared.playPickup()
            HapticManager.shared.playPickup()
        }

        if isDragging {
            // Finger-clearance upward offset (+54 pt above finger so thumb NEVER hides the target cells!)
            let offsetPt = CGPoint(x: screenPt.x, y: screenPt.y - 54.0)
            if let worldXZ = projectToBoardPlane(screenPt: offsetPt, in: view) {
                cat.targetWorldPos = SCNVector3(worldXZ.x, 0, worldXZ.z)
                updateDragPreview(forPiece: pieceIdx, catNode: cat)
            }
        }
    }

    func handleTouchEnded(at screenPt: CGPoint, in view: SCNView) {
        guard let pieceIdx = activePieceIndex, let cat = catNodes[pieceIdx] else { return }
        activePieceIndex = nil

        if !isDragging {
            // Short tap (< 7pt movement):
            // - If board is already solved ("Ngắm mèo" mode) -> Pet the cat (purr + hearts!)
            // - If cat is in tray -> Rotate 90° CW!
            // - If cat is placed on board -> Pet & purr if tap is quick (or rotate via bottom button!)
            if engine.isSolved {
                cat.triggerPetReaction()
                AudioEngineManager.shared.playCatPurrPulse()
                HapticManager.shared.playPurrOrSolve()
                onCatPetted?()
            } else if engine.placements[pieceIdx] == nil {
                rotateSelectedOrActivePiece()
            } else {
                // Petting a placed cat makes it purr and blush!
                cat.triggerPetReaction()
                AudioEngineManager.shared.playCatPurrPulse()
                HapticManager.shared.playPurrOrSolve()
                onCatPetted?()
            }
            return
        }

        // End of drag: decide commit vs return-to-tray vs invalid bounce!
        isDragging = false
        cat.setSelectedOutline(false)
        cat.setInvalidWarning(false)

        let localPos = SCNVector3(cat.targetWorldPos.x, 0, cat.targetWorldPos.z - boardWorldOffsetZ)
        let anchor = boardNode.nearestAnchor(
            forLocalPos: localPos,
            baseCells: cat.catDef.cells,
            rotation: dragRotation,
            board: currentBoard
        )
        let check = engine.validatePlacement(pieceIndex: pieceIdx, anchor: anchor, rotation: dragRotation)

        switch check {
        case .valid:
            engine.commitPlacement(pieceIndex: pieceIdx, anchor: anchor, rotation: dragRotation)
            syncCatToCommittedState(pieceIndex: pieceIdx)
            cat.triggerSquash(impulse: 1.55)
            cat.setExpression(.happy)
            AudioEngineManager.shared.playSnap()
            AudioEngineManager.shared.playCatMeow(catId: cat.catDef.id, pitchMultiplier: cat.catDef.pitch)
            HapticManager.shared.playSnap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
                if self?.engine?.isSolved == false {
                    cat.setExpression(.awake)
                }
            }
            refreshBoardVisuals()
            notifyBoardChanged()
            checkWinState()

        case .overlapping, .outOfMask:
            // If player dragged down into the tray zone, return cleanly to tray!
            let rugBottomZ = boardWorldOffsetZ + Float(currentBoard.rows) * BoardGridNode.cellSize * 0.5 + 0.14
            if cat.targetWorldPos.z > rugBottomZ {
                engine.returnToTray(pieceIndex: pieceIdx)
                engine.setTrayRotation(pieceIndex: pieceIdx, rotation: dragRotation)
                syncCatToCommittedState(pieceIndex: pieceIdx)
                cat.setExpression(.awake)
                AudioEngineManager.shared.playSnap()
                HapticManager.shared.playPickup()
            } else {
                // Invalid drop on board: show brief angry/warning flash + grumble + smooth spring bounce back!
                cat.setInvalidWarning(true)
                cat.triggerSquash(impulse: 1.35)
                AudioEngineManager.shared.playInvalid()
                AudioEngineManager.shared.playCatGrumble(pitchMultiplier: cat.catDef.pitch)
                HapticManager.shared.playInvalid()
                syncCatToCommittedState(pieceIndex: pieceIdx)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
                    cat.setInvalidWarning(false)
                    cat.setExpression(.awake)
                }
            }
            refreshBoardVisuals()
            notifyBoardChanged()
        }
    }

    func handleTouchCancelled() {
        guard let pieceIdx = activePieceIndex, let cat = catNodes[pieceIdx] else { return }
        activePieceIndex = nil
        isDragging = false
        cat.setSelectedOutline(false)
        cat.setInvalidWarning(false)
        cat.setExpression(.awake)
        syncCatToCommittedState(pieceIndex: pieceIdx)
        refreshBoardVisuals()
    }

    // MARK: - Internal Helpers

    private func selectPiece(_ idx: Int?) {
        if let prev = selectedPieceIndex, prev != idx {
            catNodes[prev]?.setSelectedOutline(false)
        }
        selectedPieceIndex = idx
        if let cur = idx {
            catNodes[cur]?.setSelectedOutline(true)
        }
        notifyBoardChanged()
    }

    private func syncCatToCommittedState(pieceIndex: Int) {
        guard let cat = catNodes[pieceIndex] else { return }
        if let placed = engine.placements[pieceIndex] {
            let local = boardNode.localCentroid(
                forCells: cat.catDef.cells,
                anchor: placed.anchor,
                rotation: placed.rotation,
                board: currentBoard
            )
            cat.targetWorldPos = SCNVector3(local.x, 0, local.z + boardWorldOffsetZ)
            cat.targetLiftY = 0.017
            cat.targetYaw = -Float(placed.rotation) * (.pi / 2)
            cat.targetScale = 1.0
        } else if let slot = traySlots[pieceIndex] {
            let rot = engine.currentRotation(forPiece: pieceIndex)
            cat.targetWorldPos = slot.pos
            cat.targetLiftY = 0.014
            cat.targetYaw = -Float(rot) * (.pi / 2)
            cat.targetScale = slot.scale
        }
    }

    private func updateDragPreview(forPiece pieceIdx: Int, catNode: Cat3DNode) {
        let localPos = SCNVector3(catNode.targetWorldPos.x, 0, catNode.targetWorldPos.z - boardWorldOffsetZ)
        let anchor = boardNode.nearestAnchor(
            forLocalPos: localPos,
            baseCells: catNode.catDef.cells,
            rotation: dragRotation,
            board: currentBoard
        )
        let res = engine.validatePlacement(pieceIndex: pieceIdx, anchor: anchor, rotation: dragRotation)
        let previewCells = engine.worldCells(forCatId: catNode.catDef.id, anchor: anchor, rotation: dragRotation)

        let rugBottomZ = boardWorldOffsetZ + Float(currentBoard.rows) * BoardGridNode.cellSize * 0.5 + 0.16
        let overBoard = catNode.targetWorldPos.z <= rugBottomZ

        switch res {
        case .valid:
            catNode.setInvalidWarning(false)
            catNode.setExpression(.surprised)
            boardNode.updateHighlights(
                mapId: currentMapId,
                occupied: engine.occupiedCells(excludingPiece: pieceIdx),
                previewCells: previewCells,
                previewValid: true,
                hintCells: activeHintCells,
                isDragging: true
            )
        case .overlapping:
            catNode.setInvalidWarning(true) // Exact red-black diagonal stripes over overlapping cat (Game.mp4!)
            boardNode.updateHighlights(
                mapId: currentMapId,
                occupied: engine.occupiedCells(excludingPiece: pieceIdx),
                previewCells: previewCells.filter { currentBoard.playableMask.contains($0) },
                previewValid: false,
                hintCells: activeHintCells,
                isDragging: true
            )
        case .outOfMask:
            catNode.setInvalidWarning(overBoard && previewCells.contains { currentBoard.playableMask.contains($0) })
            if !overBoard { catNode.setExpression(.surprised) }
            boardNode.updateHighlights(
                mapId: currentMapId,
                occupied: engine.occupiedCells(excludingPiece: pieceIdx),
                previewCells: overBoard ? previewCells.filter { currentBoard.playableMask.contains($0) } : [],
                previewValid: false,
                hintCells: activeHintCells,
                isDragging: true
            )
        }
        lastPreviewAnchor = anchor
        lastPreviewValid = (res == .valid(occupiedCells: previewCells))
    }

    private func refreshBoardVisuals() {
        guard engine != nil else { return }
        boardNode.updateHighlights(
            mapId: currentMapId,
            occupied: engine.occupiedCells(excludingPiece: nil),
            previewCells: [],
            previewValid: true,
            hintCells: activeHintCells,
            isDragging: isDragging
        )
    }

    private func checkWinState() {
        guard engine.isSolved else { return }
        clearHint()
        selectPiece(nil)
        AudioEngineManager.shared.playSolve()
        AudioEngineManager.shared.playCatPurrPulse()
        HapticManager.shared.playPurrOrSolve()

        // Every cat does a joyful cozy wave + purr + hearts!
        for (i, cat) in catNodes.values.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                cat.triggerPetReaction()
            }
        }
        let solvedId = currentBoard.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { [weak self] in
            self?.onBoardSolved?(solvedId)
        }
    }

    private func notifyBoardChanged() {
        guard engine != nil else { return }
        onBoardChanged?(engine.placements.count, currentBoard.playableCats.count, !engine.undoStack.isEmpty, selectedPieceIndex)
    }

    private func findParentCatNode(_ node: SCNNode?) -> Cat3DNode? {
        var cur = node
        while let n = cur {
            if let cat = n as? Cat3DNode { return cat }
            cur = n.parent
        }
        return nil
    }

    /// Exact ray-plane intersection against horizontal board plane `y = 0.05`.
    private func projectToBoardPlane(screenPt: CGPoint, in view: SCNView) -> SCNVector3? {
        let p0 = view.unprojectPoint(SCNVector3(Float(screenPt.x), Float(screenPt.y), 0.0))
        let p1 = view.unprojectPoint(SCNVector3(Float(screenPt.x), Float(screenPt.y), 1.0))
        let dirY = p1.y - p0.y
        guard abs(dirY) > 1e-5 else { return nil }
        let t = (0.05 - p0.y) / dirY
        return SCNVector3(p0.x + (p1.x - p0.x) * t, 0.05, p0.z + (p1.z - p0.z) * t)
    }

    // MARK: - SCNSceneRendererDelegate (60–120 FPS ProMotion Update Loop)

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let dt: Float = lastFrameTime == 0 ? (1.0 / 60.0) : Float(max(0.001, min(time - lastFrameTime, 1.0 / 24.0)))
        lastFrameTime = time

        for cat in catNodes.values {
            cat.update(dt: dt, currentTime: time)
        }
        for locked in lockedCatNodes {
            locked.update(dt: dt, currentTime: time)
        }
    }
}
