import Foundation

public final class LevelCatalog: @unchecked Sendable {
    public let maps: [MapTheme]
    public let cats: [CatDefinition]
    public let catById: [String: CatDefinition]
    public let levels: [BoardDefinition]
    public let levelById: [Int: BoardDefinition]

    public init(payload: LevelBundlePayload) {
        self.maps = payload.maps.sorted { $0.index < $1.index }
        self.cats = payload.cats
        self.catById = Dictionary(uniqueKeysWithValues: payload.cats.map { ($0.id, $0) })
        self.levels = payload.levels.sorted { $0.id < $1.id }
        self.levelById = Dictionary(uniqueKeysWithValues: payload.levels.map { ($0.id, $0) })
    }

    public static func load(from data: Data) throws -> LevelCatalog {
        let payload = try JSONDecoder().decode(LevelBundlePayload.self, from: data)
        return LevelCatalog(payload: payload)
    }

    public static func loadBundled(bundle: Bundle = .main) throws -> LevelCatalog {
        let candidates: [URL?] = [
            bundle.url(forResource: "levels", withExtension: "json", subdirectory: "Data"),
            bundle.url(forResource: "levels", withExtension: "json"),
            Bundle.module.url(forResource: "levels", withExtension: "json")
        ]
        for case let url? in candidates {
            if let data = try? Data(contentsOf: url) {
                return try load(from: data)
            }
        }
        throw NSError(domain: "CatrisCore", code: 404, userInfo: [
            NSLocalizedDescriptionKey: "Could not locate levels.json in app or module bundle."
        ])
    }

    public func levels(inMap mapId: String) -> [BoardDefinition] {
        levels.filter { $0.mapId == mapId }
    }

    public func map(forId id: String) -> MapTheme? {
        maps.first { $0.id == id }
    }

    public func nextLevel(after levelId: Int) -> BoardDefinition? {
        levelById[levelId + 1]
    }
}
