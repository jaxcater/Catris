import Foundation

public struct GameSettings: Codable, Equatable, Sendable {
    public var musicVolume: Double = 0.65
    public var ambienceVolume: Double = 0.70
    public var foleyVolume: Double = 0.85
    public var catsVolume: Double = 0.85
    public var uiVolume: Double = 0.75
    public var isMuted: Bool = false
    public var hapticsEnabled: Bool = true
    public var leftHandedControls: Bool = false
    public var eco30Fps: Bool = false
    public var reduceMotion: Bool = false
    public var useVietnamese: Bool = true

    public init() {}
}

public struct InProgressBoardSave: Codable, Equatable, Sendable {
    public var levelId: Int
    public var placements: [PiecePlacement]
    public var moveCount: Int

    public init(levelId: Int, placements: [PiecePlacement], moveCount: Int) {
        self.levelId = levelId
        self.placements = placements
        self.moveCount = moveCount
    }
}

public struct PlayerSaveData: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int = PlayerSaveData.currentSchemaVersion
    public var completedLevelIds: Set<Int> = []
    public var unlockedCatIds: Set<String> = ["nori", "mochi", "miso", "matcha"]
    public var currentLevelId: Int = 1
    public var activeBoard: InProgressBoardSave? = nil
    public var settings: GameSettings = GameSettings()
    public var totalPetsGiven: Int = 0

    public init() {}

    /// Number of permanent cozy decorations unlocked for a given map (1 per 4 boards completed, max 3).
    public func unlockedDecorCount(forMap mapId: String, catalog: LevelCatalog) -> Int {
        let mapLevels = catalog.levels(inMap: mapId)
        let solved = mapLevels.filter { completedLevelIds.contains($0.id) }.count
        return min(3, solved / 4)
    }
}

/// Atomic local save store with backup file recovery (never silently wipes progress on corruption!).
public final class SaveStore {
    public let primaryURL: URL
    public let backupURL: URL

    public init(directory: URL) {
        self.primaryURL = directory.appendingPathComponent("catris_save.json")
        self.backupURL = directory.appendingPathComponent("catris_save.backup.json")
    }

    public static func defaultDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = appSupport.appendingPathComponent("Catris", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public func load() -> (data: PlayerSaveData, recoveredFromBackup: Bool) {
        if let primary = decodeFile(at: primaryURL) {
            return (migrate(primary), false)
        }
        if let backup = decodeFile(at: backupURL) {
            let migrated = migrate(backup)
            try? save(migrated)
            return (migrated, true)
        }
        return (PlayerSaveData(), false)
    }

    public func save(_ state: PlayerSaveData) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: primaryURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let bytes = try encoder.encode(state)

        // Preserve previous valid primary as backup before atomic replace
        if fm.fileExists(atPath: primaryURL.path), decodeFile(at: primaryURL) != nil {
            let tmpBak = backupURL.appendingPathExtension("tmp")
            try? fm.removeItem(at: tmpBak)
            try fm.copyItem(at: primaryURL, to: tmpBak)
            if fm.fileExists(atPath: backupURL.path) {
                try? fm.removeItem(at: backupURL)
            }
            try fm.moveItem(at: tmpBak, to: backupURL)
        }

        let tmpPrimary = primaryURL.appendingPathExtension("tmp")
        try bytes.write(to: tmpPrimary, options: .atomic)
        if fm.fileExists(atPath: primaryURL.path) {
            _ = try fm.replaceItemAt(primaryURL, withItemAt: tmpPrimary)
        } else {
            try fm.moveItem(at: tmpPrimary, to: primaryURL)
        }
    }

    private func decodeFile(at url: URL) -> PlayerSaveData? {
        guard let raw = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PlayerSaveData.self, from: raw)
    }

    private func migrate(_ input: PlayerSaveData) -> PlayerSaveData {
        var copy = input
        copy.schemaVersion = PlayerSaveData.currentSchemaVersion
        if copy.unlockedCatIds.isEmpty {
            copy.unlockedCatIds = ["nori", "mochi", "miso", "matcha"]
        }
        return copy
    }
}
