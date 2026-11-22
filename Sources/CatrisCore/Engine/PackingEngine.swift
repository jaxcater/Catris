import Foundation

public struct UndoEntry: Codable, Equatable, Sendable {
    public let pieceIndex: Int
    public let previousPlacement: PiecePlacement?
    public let newPlacement: PiecePlacement?
    public let previousTrayRotation: Int
    public let newTrayRotation: Int
}

public enum PlacementCheckResult: Equatable, Sendable {
    case valid(occupiedCells: [GridPoint])
    case outOfMask(invalidCells: [GridPoint])
    case overlapping(overlappingCells: [GridPoint])
}

/// Pure deterministic polyomino packing engine.
/// Completely decoupled from 3D meshes, shaders, spring physics, or UIKit.
public final class PackingEngine {
    public let board: BoardDefinition
    public let catLookup: [String: CatDefinition]
    public let playableMask: Set<GridPoint>
    public let fixedOccupiedCells: Set<GridPoint>

    /// Current committed placements indexed by `pieceIndex`.
    public private(set) var placements: [Int: PiecePlacement] = [:]
    /// Current rotation of each piece while sitting in the tray (0..3).
    public private(set) var trayRotations: [Int: Int] = [:]
    public private(set) var undoStack: [UndoEntry] = []
    public private(set) var moveCount: Int = 0

    public init(board: BoardDefinition, cats: [String: CatDefinition]) {
        self.board = board
        self.catLookup = cats
        self.playableMask = board.playableMask

        var fixed: Set<GridPoint> = []
        for fc in board.fixedCats {
            if let def = cats[fc.catId] {
                let shape = PolyominoMath.rotatedCW(def.cells, steps: fc.rotation)
                for dc in shape {
                    fixed.insert(GridPoint(col: fc.anchorCol + dc.col, row: fc.anchorRow + dc.row))
                }
            }
        }
        self.fixedOccupiedCells = fixed

        for idx in 0..<board.playableCats.count {
            trayRotations[idx] = 0
        }
    }

    public func catDefinition(forPiece pieceIndex: Int) -> CatDefinition? {
        guard pieceIndex >= 0 && pieceIndex < board.playableCats.count else { return nil }
        return catLookup[board.playableCats[pieceIndex]]
    }

    public func currentRotation(forPiece pieceIndex: Int) -> Int {
        if let placed = placements[pieceIndex] { return placed.rotation }
        return trayRotations[pieceIndex] ?? 0
    }

    public func worldCells(forCatId catId: String, anchor: GridPoint, rotation: Int) -> [GridPoint] {
        guard let def = catLookup[catId] else { return [] }
        let shape = PolyominoMath.rotatedCW(def.cells, steps: rotation)
        return shape.map { GridPoint(col: anchor.col + $0.col, row: anchor.row + $0.row) }
    }

    /// Occupied cells on the board, optionally excluding a currently dragged piece (prevents self-collision).
    public func occupiedCells(excludingPiece excludedPiece: Int? = nil) -> Set<GridPoint> {
        var used = fixedOccupiedCells
        for (idx, p) in placements {
            if idx == excludedPiece { continue }
            for pt in worldCells(forCatId: p.catId, anchor: p.anchor, rotation: p.rotation) {
                used.insert(pt)
            }
        }
        return used
    }

    public func validatePlacement(
        pieceIndex: Int,
        anchor: GridPoint,
        rotation: Int
    ) -> PlacementCheckResult {
        guard let def = catDefinition(forPiece: pieceIndex) else {
            return .outOfMask(invalidCells: [])
        }
        let targetCells = worldCells(forCatId: def.id, anchor: anchor, rotation: rotation)
        let outside = targetCells.filter { !playableMask.contains($0) }
        if !outside.isEmpty {
            return .outOfMask(invalidCells: outside)
        }
        let used = occupiedCells(excludingPiece: pieceIndex)
        let overlap = targetCells.filter { used.contains($0) }
        if !overlap.isEmpty {
            return .overlapping(overlappingCells: overlap)
        }
        return .valid(occupiedCells: targetCells)
    }

    /// Atomically commit a valid placement onto the board and record a single undo entry.
    @discardableResult
    public func commitPlacement(
        pieceIndex: Int,
        anchor: GridPoint,
        rotation: Int
    ) -> Bool {
        guard case .valid = validatePlacement(pieceIndex: pieceIndex, anchor: anchor, rotation: rotation),
              let def = catDefinition(forPiece: pieceIndex) else {
            return false
        }
        let normRot = ((rotation % 4) + 4) % 4
        let prev = placements[pieceIndex]
        let prevTrayRot = trayRotations[pieceIndex] ?? 0
        let next = PiecePlacement(
            pieceIndex: pieceIndex,
            catId: def.id,
            anchorCol: anchor.col,
            anchorRow: anchor.row,
            rotation: normRot
        )
        if prev == next { return true } // No-op drop back to exact same spot

        placements[pieceIndex] = next
        trayRotations[pieceIndex] = normRot
        undoStack.append(UndoEntry(
            pieceIndex: pieceIndex,
            previousPlacement: prev,
            newPlacement: next,
            previousTrayRotation: prevTrayRot,
            newTrayRotation: normRot
        ))
        moveCount += 1
        return true
    }

    /// Return a placed piece back to the tray cleanly with undo support.
    @discardableResult
    public func returnToTray(pieceIndex: Int) -> Bool {
        guard let prev = placements[pieceIndex] else { return false }
        let prevTrayRot = trayRotations[pieceIndex] ?? prev.rotation
        placements.removeValue(forKey: pieceIndex)
        undoStack.append(UndoEntry(
            pieceIndex: pieceIndex,
            previousPlacement: prev,
            newPlacement: nil,
            previousTrayRotation: prevTrayRot,
            newTrayRotation: prevTrayRot
        ))
        moveCount += 1
        return true
    }

    /// Rotate a piece in place if in tray, or attempt 90° CW rotation on board (if valid).
    /// Returns true if rotation succeeded.
    @discardableResult
    public func rotatePieceCW(pieceIndex: Int) -> Bool {
        if let placed = placements[pieceIndex] {
            let nextRot = (placed.rotation + 1) % 4
            // Try keeping same anchor first, or nearest 1-cell nudge so rotation feels generous!
            let offsets = [
                GridPoint(col: 0, row: 0),
                GridPoint(col: -1, row: 0), GridPoint(col: 1, row: 0),
                GridPoint(col: 0, row: -1), GridPoint(col: 0, row: 1)
            ]
            for off in offsets {
                let cand = placed.anchor + off
                if case .valid = validatePlacement(pieceIndex: pieceIndex, anchor: cand, rotation: nextRot) {
                    return commitPlacement(pieceIndex: pieceIndex, anchor: cand, rotation: nextRot)
                }
            }
            return false
        } else {
            let cur = trayRotations[pieceIndex] ?? 0
            trayRotations[pieceIndex] = (cur + 1) % 4
            return true
        }
    }

    public func setTrayRotation(pieceIndex: Int, rotation: Int) {
        trayRotations[pieceIndex] = ((rotation % 4) + 4) % 4
    }

    @discardableResult
    public func undo() -> UndoEntry? {
        guard let last = undoStack.popLast() else { return nil }
        if let prev = last.previousPlacement {
            placements[last.pieceIndex] = prev
        } else {
            placements.removeValue(forKey: last.pieceIndex)
        }
        trayRotations[last.pieceIndex] = last.previousTrayRotation
        return last
    }

    public func resetBoard() {
        placements.removeAll()
        undoStack.removeAll()
        moveCount = 0
        for idx in 0..<board.playableCats.count {
            trayRotations[idx] = 0
        }
    }

    /// Restore validated committed placements from persistence (rejects any illegal entries safely).
    public func restorePlacements(_ saved: [PiecePlacement]) {
        resetBoard()
        for p in saved {
            if case .valid = validatePlacement(pieceIndex: p.pieceIndex, anchor: p.anchor, rotation: p.rotation) {
                placements[p.pieceIndex] = p
                trayRotations[p.pieceIndex] = p.rotation
            }
        }
    }

    /// Exact logical win check: every required piece placed and playable mask covered exactly once.
    public var isSolved: Bool {
        guard placements.count == board.playableCats.count else { return false }
        return occupiedCells(excludingPiece: nil) == playableMask
    }

    /// Remaining unplaced piece indices in deterministic order.
    public var unplacedPieces: [Int] {
        (0..<board.playableCats.count).filter { placements[$0] == nil }
    }
}
