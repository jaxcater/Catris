import Foundation

public enum HintRecommendation: Equatable, Sendable {
    /// Current placements can still be completed! Suggest placing this exact piece.
    case placePiece(placement: PiecePlacement, targetCells: [GridPoint])
    /// Current placements form a dead-end. Suggest moving/removing this specific misplaced piece!
    case removeBlockingPiece(pieceIndex: Int, catId: String)
    /// Board is already solved.
    case alreadySolved
}

/// Fast exact-cover backtracking solver powering both automated level verification
/// AND solver-aware 3-tier hints (respects the player's current placements!).
public enum ExactCoverSolver {
    /// Attempt to complete `board` given already-committed `existingPlacements`.
    /// Returns a complete list of placements for ALL unplaced playable pieces, or nil if unsolvable.
    public static func solveRemaining(
        board: BoardDefinition,
        cats: [String: CatDefinition],
        existingPlacements: [Int: PiecePlacement],
        nodeLimit: Int = 60_000
    ) -> [PiecePlacement]? {
        let mask = board.playableMask
        var occupied: Set<GridPoint> = []

        // Fixed sleeping cats
        for fc in board.fixedCats {
            guard let def = cats[fc.catId] else { return nil }
            for dc in PolyominoMath.rotatedCW(def.cells, steps: fc.rotation) {
                let pt = GridPoint(col: fc.anchorCol + dc.col, row: fc.anchorRow + dc.row)
                guard mask.contains(pt), occupied.insert(pt).inserted else { return nil }
            }
        }

        // Player's current committed placements
        for (_, p) in existingPlacements {
            guard let def = cats[p.catId] else { return nil }
            for dc in PolyominoMath.rotatedCW(def.cells, steps: p.rotation) {
                let pt = GridPoint(col: p.anchorCol + dc.col, row: p.anchorRow + dc.row)
                guard mask.contains(pt), occupied.insert(pt).inserted else { return nil }
            }
        }

        let remainingIndices = (0..<board.playableCats.count)
            .filter { existingPlacements[$0] == nil }
            .sorted { a, b in
                let ca = cats[board.playableCats[a]]?.cells.count ?? 0
                let cb = cats[board.playableCats[b]]?.cells.count ?? 0
                return ca > cb
            }

        let freeCells = mask.subtracting(occupied)
        let neededArea = remainingIndices.reduce(0) { $0 + (cats[board.playableCats[$1]]?.cells.count ?? 0) }
        guard neededArea == freeCells.count else { return nil }
        if remainingIndices.isEmpty { return [] }

        // Precompute valid candidate placements per remaining piece
        struct Candidate {
            let rot: Int
            let col: Int
            let row: Int
            let cells: [GridPoint]
        }

        var candidatesBySlot: [[Candidate]] = []
        candidatesBySlot.reserveCapacity(remainingIndices.count)

        for pieceIdx in remainingIndices {
            let catId = board.playableCats[pieceIdx]
            guard let def = cats[catId] else { return nil }
            var list: [Candidate] = []
            for (rotStep, shape) in PolyominoMath.uniqueRotations(def.cells) {
                let (w, h) = PolyominoMath.bounds(of: shape)
                for ac in 0...(board.cols - w) {
                    for ar in 0...(board.rows - h) {
                        let pts = shape.map { GridPoint(col: ac + $0.col, row: ar + $0.row) }
                        if pts.allSatisfy({ freeCells.contains($0) }) {
                            list.append(Candidate(rot: rotStep, col: ac, row: ar, cells: pts))
                        }
                    }
                }
            }
            if list.isEmpty { return nil }
            candidatesBySlot.append(list)
        }

        var used = occupied
        var solution: [PiecePlacement] = []
        solution.reserveCapacity(remainingIndices.count)
        var visitedNodes = 0

        func dfs(_ slot: Int) -> Bool {
            if slot == remainingIndices.count { return true }
            visitedNodes += 1
            if visitedNodes > nodeLimit { return false }

            let pieceIdx = remainingIndices[slot]
            let catId = board.playableCats[pieceIdx]
            for cand in candidatesBySlot[slot] {
                var clash = false
                for pt in cand.cells where used.contains(pt) {
                    clash = true
                    break
                }
                if clash { continue }
                for pt in cand.cells { used.insert(pt) }
                solution.append(PiecePlacement(
                    pieceIndex: pieceIdx,
                    catId: catId,
                    anchorCol: cand.col,
                    anchorRow: cand.row,
                    rotation: cand.rot
                ))
                if dfs(slot + 1) { return true }
                solution.removeLast()
                for pt in cand.cells { used.remove(pt) }
            }
            return false
        }

        return dfs(0) ? solution : nil
    }

    /// Solver-aware Hint Engine:
    /// 1. Tries to complete from the player's current placements first!
    /// 2. If the player created a dead-end, finds a specific blocking placement to remove/move
    ///    rather than overlaying an impossible contradictory witness.
    public static func computeHint(engine: PackingEngine) -> HintRecommendation {
        if engine.isSolved { return .alreadySolved }

        // 1. Can current state be completed directly?
        if let completion = solveRemaining(
            board: engine.board,
            cats: engine.catLookup,
            existingPlacements: engine.placements
        ), let first = completion.first {
            let cells = engine.worldCells(forCatId: first.catId, anchor: first.anchor, rotation: first.rotation)
            return .placePiece(placement: first, targetCells: cells)
        }

        // 2. Dead-end detected! Check if removing a single placed piece restores solvability.
        for (pieceIdx, placement) in engine.placements.sorted(by: { $0.key > $1.key }) {
            var reduced = engine.placements
            reduced.removeValue(forKey: pieceIdx)
            if solveRemaining(board: engine.board, cats: engine.catLookup, existingPlacements: reduced) != nil {
                return .removeBlockingPiece(pieceIndex: pieceIdx, catId: placement.catId)
            }
        }

        // 3. Multiple pieces conflict: pinpoint the most recently placed piece that differs from verified witness!
        let witnessByPiece = Dictionary(uniqueKeysWithValues: engine.board.verifiedSolution.map { ($0.pieceIndex, $0) })
        if let lastUndo = engine.undoStack.reversed().first(where: { entry in
            guard let cur = engine.placements[entry.pieceIndex] else { return false }
            return cur != witnessByPiece[entry.pieceIndex]
        }), let cur = engine.placements[lastUndo.pieceIndex] {
            return .removeBlockingPiece(pieceIndex: cur.pieceIndex, catId: cur.catId)
        }

        if let mismatch = engine.placements.values.first(where: { $0 != witnessByPiece[$0.pieceIndex] }) {
            return .removeBlockingPiece(pieceIndex: mismatch.pieceIndex, catId: mismatch.catId)
        }

        // Fallback to verified witness if board empty
        if let firstWitness = engine.board.verifiedSolution.first(where: { engine.placements[$0.pieceIndex] == nil }) {
            let cells = engine.worldCells(forCatId: firstWitness.catId, anchor: firstWitness.anchor, rotation: firstWitness.rotation)
            return .placePiece(placement: firstWitness, targetCells: cells)
        }
        return .alreadySolved
    }
}
