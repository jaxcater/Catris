import Foundation

/// Integer grid coordinate on the puzzle mat.
/// Origin (0, 0) is bottom-left; +col is right, +row is up.
public struct GridPoint: Hashable, Codable, Sendable, Comparable {
    public let col: Int
    public let row: Int

    public init(col: Int, row: Int) {
        self.col = col
        self.row = row
    }

    public static func < (lhs: GridPoint, rhs: GridPoint) -> Bool {
        if lhs.col != rhs.col { return lhs.col < rhs.col }
        return lhs.row < rhs.row
    }

    public static func + (lhs: GridPoint, rhs: GridPoint) -> GridPoint {
        GridPoint(col: lhs.col + rhs.col, row: lhs.row + rhs.row)
    }
}

public enum PolyominoMath {
    /// Normalize cells so minimum col and minimum row are both 0, sorted deterministically.
    public static func normalize(_ cells: [GridPoint]) -> [GridPoint] {
        guard let minC = cells.map(\.col).min(),
              let minR = cells.map(\.row).min() else { return [] }
        return cells
            .map { GridPoint(col: $0.col - minC, row: $0.row - minR) }
            .sorted()
    }

    /// Rotate 90° clockwise `steps` times in +col right, +row up space: (c, r) -> (r, -c).
    public static func rotatedCW(_ cells: [GridPoint], steps: Int) -> [GridPoint] {
        let k = ((steps % 4) + 4) % 4
        var cur = cells
        for _ in 0..<k {
            cur = cur.map { GridPoint(col: $0.row, row: -$0.col) }
        }
        return normalize(cur)
    }

    /// Distinct rotation step indices and their normalized footprints.
    public static func uniqueRotations(_ cells: [GridPoint]) -> [(step: Int, cells: [GridPoint])] {
        var seen: Set<[GridPoint]> = []
        var out: [(Int, [GridPoint])] = []
        for step in 0..<4 {
            let rot = rotatedCW(cells, steps: step)
            if seen.insert(rot).inserted {
                out.append((step, rot))
            }
        }
        return out
    }

    /// Bounding size (widthCols, heightRows) of normalized cells.
    public static func bounds(of cells: [GridPoint]) -> (cols: Int, rows: Int) {
        let maxC = cells.map(\.col).max() ?? 0
        let maxR = cells.map(\.row).max() ?? 0
        return (maxC + 1, maxR + 1)
    }
}

public struct MapTheme: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let index: Int
    public let nameVi: String
    public let nameEn: String
    public let taglineVi: String
    public let taglineEn: String
    public let accentHex: String
    public let bgHex: String
    public let decorTiers: [String]

    enum CodingKeys: String, CodingKey {
        case id, index
        case nameVi = "name_vi"
        case nameEn = "name_en"
        case taglineVi = "tagline_vi"
        case taglineEn = "tagline_en"
        case accentHex = "accent_hex"
        case bgHex = "bg_hex"
        case decorTiers = "decor_tiers"
    }

    public func localizedName(vietnamese: Bool) -> String { vietnamese ? nameVi : nameEn }
    public func localizedTagline(vietnamese: Bool) -> String { vietnamese ? taglineVi : taglineEn }
}

public struct CatDefinition: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let code: String
    public let nameVi: String
    public let nameEn: String
    public let subtitleVi: String
    public let subtitleEn: String
    private let rawCells: [[Int]]
    public let baseHex: String
    public let accentHex: String
    public let eyeHex: String
    public let pitch: Double
    public let unlockMap: String
    public let unlockLevel: Int

    public var cells: [GridPoint] {
        PolyominoMath.normalize(rawCells.compactMap { arr in
            guard arr.count == 2 else { return nil }
            return GridPoint(col: arr[0], row: arr[1])
        })
    }

    enum CodingKeys: String, CodingKey {
        case id, code, pitch
        case nameVi = "name_vi"
        case nameEn = "name_en"
        case subtitleVi = "subtitle_vi"
        case subtitleEn = "subtitle_en"
        case rawCells = "cells"
        case baseHex = "base_hex"
        case accentHex = "accent_hex"
        case eyeHex = "eye_hex"
        case unlockMap = "unlock_map"
        case unlockLevel = "unlock_level"
    }

    public func localizedName(vietnamese: Bool) -> String { vietnamese ? nameVi : nameEn }
    public func localizedSubtitle(vietnamese: Bool) -> String { vietnamese ? subtitleVi : subtitleEn }
}

public struct ObstacleDefinition: Codable, Equatable, Hashable, Sendable {
    public let col: Int
    public let row: Int
    public let kind: String

    public var point: GridPoint { GridPoint(col: col, row: row) }
}

public struct FixedCatPlacement: Codable, Equatable, Hashable, Sendable {
    public let catId: String
    public let anchorCol: Int
    public let anchorRow: Int
    public let rotation: Int

    public var anchor: GridPoint { GridPoint(col: anchorCol, row: anchorRow) }

    enum CodingKeys: String, CodingKey {
        case catId = "cat_id"
        case anchorCol = "anchor_col"
        case anchorRow = "anchor_row"
        case rotation
    }
}

public struct PiecePlacement: Codable, Equatable, Hashable, Sendable {
    public let pieceIndex: Int
    public let catId: String
    public let anchorCol: Int
    public let anchorRow: Int
    public let rotation: Int

    public var anchor: GridPoint { GridPoint(col: anchorCol, row: anchorRow) }

    public init(pieceIndex: Int, catId: String, anchorCol: Int, anchorRow: Int, rotation: Int) {
        self.pieceIndex = pieceIndex
        self.catId = catId
        self.anchorCol = anchorCol
        self.anchorRow = anchorRow
        self.rotation = ((rotation % 4) + 4) % 4
    }

    enum CodingKeys: String, CodingKey {
        case pieceIndex = "piece_index"
        case catId = "cat_id"
        case anchorCol = "anchor_col"
        case anchorRow = "anchor_row"
        case rotation
    }
}

public struct BoardDefinition: Codable, Identifiable, Equatable, Sendable {
    public let id: Int
    public let mapId: String
    public let indexInMap: Int
    public let difficulty: Int
    public let titleVi: String
    public let titleEn: String
    public let tutorialHintVi: String?
    public let tutorialHintEn: String?
    public let cols: Int
    public let rows: Int
    private let rawVoidCells: [[Int]]
    public let obstacles: [ObstacleDefinition]
    public let fixedCats: [FixedCatPlacement]
    public let playableCats: [String]
    public let verifiedSolution: [PiecePlacement]

    public var voidCells: Set<GridPoint> {
        Set(rawVoidCells.compactMap { arr in
            guard arr.count == 2 else { return nil }
            return GridPoint(col: arr[0], row: arr[1])
        })
    }

    public var obstacleCells: Set<GridPoint> {
        Set(obstacles.map(\.point))
    }

    /// All cells on the rug that must be covered by either fixed or playable cats.
    public var playableMask: Set<GridPoint> {
        let voids = voidCells
        let obs = obstacleCells
        var mask: Set<GridPoint> = []
        for c in 0..<cols {
            for r in 0..<rows {
                let pt = GridPoint(col: c, row: r)
                if !voids.contains(pt) && !obs.contains(pt) {
                    mask.insert(pt)
                }
            }
        }
        return mask
    }

    public func localizedTitle(vietnamese: Bool) -> String { vietnamese ? titleVi : titleEn }
    public func localizedTutorialHint(vietnamese: Bool) -> String? { vietnamese ? tutorialHintVi : tutorialHintEn }

    enum CodingKeys: String, CodingKey {
        case id, difficulty, cols, rows, obstacles
        case mapId = "map_id"
        case indexInMap = "index_in_map"
        case titleVi = "title_vi"
        case titleEn = "title_en"
        case tutorialHintVi = "tutorial_hint_vi"
        case tutorialHintEn = "tutorial_hint_en"
        case rawVoidCells = "void_cells"
        case fixedCats = "fixed_cats"
        case playableCats = "playable_cats"
        case verifiedSolution = "verified_solution"
    }
}

public struct LevelBundlePayload: Codable, Sendable {
    public let schemaVersion: Int
    public let maps: [MapTheme]
    public let cats: [CatDefinition]
    public let levels: [BoardDefinition]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case maps, cats, levels
    }
}
