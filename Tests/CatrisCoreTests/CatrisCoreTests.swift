import XCTest
@testable import CatrisCore

final class CatrisCoreTests: XCTestCase {
    private var catalog: LevelCatalog!

    override func setUpWithError() throws {
        catalog = try LevelCatalog.loadBundled(bundle: .module)
    }

    func testCatalogScopeFiveMapsSixtyLevelsTwelveCats() {
        XCTAssertEqual(catalog.maps.count, 5, "Catris must have strictly 5 maps")
        XCTAssertEqual(catalog.levels.count, 60, "Catris must ship all 60 verified levels")
        XCTAssertEqual(catalog.cats.count, 12, "Catris must ship all 12 sculpted cat species")
        for map in catalog.maps {
            XCTAssertEqual(catalog.levels(inMap: map.id).count, 12, "Map \(map.id) should have 12 boards")
        }
    }

    func testFourRotationsReturnExactOriginalFootprint() {
        for cat in catalog.cats {
            let norm = cat.cells
            let rot4 = PolyominoMath.rotatedCW(norm, steps: 4)
            XCTAssertEqual(norm, rot4, "4x CW rotation failed for cat \(cat.id)")
        }
    }

    func testAllSixtyBoardsHaveValidVerifiedWitnessAndExactCoverage() {
        for board in catalog.levels {
            let engine = PackingEngine(board: board, cats: catalog.catById)
            XCTAssertFalse(engine.isSolved, "Fresh board \(board.id) should not be solved")
            XCTAssertEqual(board.verifiedSolution.count, board.playableCats.count, "Board \(board.id) witness length mismatch")

            for placement in board.verifiedSolution {
                let ok = engine.commitPlacement(
                    pieceIndex: placement.pieceIndex,
                    anchor: placement.anchor,
                    rotation: placement.rotation
                )
                XCTAssertTrue(ok, "Witness placement failed on board \(board.id) for cat \(placement.catId)")
            }
            XCTAssertTrue(engine.isSolved, "Board \(board.id) did not solve after applying verified witness")
        }
    }

    func testRejectsOutOfMaskAndOverlapAndAllowsSelfOccupancyMove() {
        let board = catalog.levelById[3]! // Classic 4x4 video board!
        let engine = PackingEngine(board: board, cats: catalog.catById)

        // Place Nori (1x4 vertical) at col 0
        XCTAssertTrue(engine.commitPlacement(pieceIndex: 0, anchor: GridPoint(col: 0, row: 0), rotation: 0))

        // Out of bounds rejection
        if case .outOfMask = engine.validatePlacement(pieceIndex: 0, anchor: GridPoint(col: 0, row: 1), rotation: 0) {
            // Expected!
        } else {
            XCTFail("Expected outOfMask when 1x4 cat extends past row 3")
        }

        // Overlap rejection with Nori
        if case .overlapping = engine.validatePlacement(pieceIndex: 1, anchor: GridPoint(col: 0, row: 0), rotation: 0) {
            // Expected!
        } else {
            XCTFail("Expected overlapping when Sumi collides with Nori")
        }

        // Self-occupancy exclusion: moving Nori onto a valid spot overlapping its own old cells (rotated horizontal at row 0) succeeds!
        XCTAssertEqual(engine.validatePlacement(pieceIndex: 0, anchor: GridPoint(col: 0, row: 0), rotation: 1),
                       .valid(occupiedCells: [
                           GridPoint(col: 0, row: 0), GridPoint(col: 1, row: 0),
                           GridPoint(col: 2, row: 0), GridPoint(col: 3, row: 0)
                       ]))
    }

    func testUndoAndReturnToTrayInvariants() {
        let board = catalog.levelById[3]!
        let engine = PackingEngine(board: board, cats: catalog.catById)

        XCTAssertTrue(engine.commitPlacement(pieceIndex: 0, anchor: GridPoint(col: 0, row: 0), rotation: 0))
        XCTAssertTrue(engine.commitPlacement(pieceIndex: 4, anchor: GridPoint(col: 1, row: 3), rotation: 0))
        XCTAssertEqual(engine.placements.count, 2)

        XCTAssertNotNil(engine.undo())
        XCTAssertNil(engine.placements[4])
        XCTAssertEqual(engine.placements.count, 1)

        XCTAssertTrue(engine.returnToTray(pieceIndex: 0))
        XCTAssertEqual(engine.placements.count, 0)

        XCTAssertNotNil(engine.undo())
        XCTAssertNotNil(engine.placements[0])
    }

    func testSolverAwareHintHandlesSolvableAndDeadEndStates() {
        let board = catalog.levelById[3]! // 4x4 video board
        let engine = PackingEngine(board: board, cats: catalog.catById)

        // Solvable partial state -> recommends placing a valid piece!
        XCTAssertTrue(engine.commitPlacement(pieceIndex: 0, anchor: GridPoint(col: 0, row: 0), rotation: 0))
        let goodHint = ExactCoverSolver.computeHint(engine: engine)
        if case .placePiece(let placement, let cells) = goodHint {
            XCTAssertFalse(cells.isEmpty)
            XCTAssertTrue(engine.commitPlacement(pieceIndex: placement.pieceIndex, anchor: placement.anchor, rotation: placement.rotation))
        } else {
            XCTFail("Expected .placePiece hint for solvable partial board, got \(goodHint)")
        }

        // Dead-end state: place 1x4 Nori vertically in col 1, isolating col 0 (1x4) while placing Miso in (0,1)!
        engine.resetBoard()
        XCTAssertTrue(engine.commitPlacement(pieceIndex: 0, anchor: GridPoint(col: 1, row: 0), rotation: 0))
        XCTAssertTrue(engine.commitPlacement(pieceIndex: 4, anchor: GridPoint(col: 0, row: 1), rotation: 0))
        // Now (0,0) is a 1x1 isolated pocket and no remaining 1x1 piece exists -> unsolvable dead-end!
        let deadHint = ExactCoverSolver.computeHint(engine: engine)
        if case .removeBlockingPiece(let idx, _) = deadHint {
            XCTAssertTrue(idx == 0 || idx == 4)
        } else {
            XCTFail("Expected .removeBlockingPiece on dead-end state, got \(deadHint)")
        }
    }

    func testSaveStoreAtomicWriteAndBackupCorruptionRecovery() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = SaveStore(directory: tempDir)
        var state = PlayerSaveData()
        state.completedLevelIds.insert(1)
        state.completedLevelIds.insert(2)
        state.settings.leftHandedControls = true
        try store.save(state)

        // Save a second time so backup exists!
        state.completedLevelIds.insert(3)
        try store.save(state)

        // Corrupt primary save file intentionally
        try Data("{corrupted json!!".utf8).write(to: store.primaryURL)

        let (loaded, recovered) = store.load()
        XCTAssertTrue(recovered, "Should recover automatically from backup when primary save is corrupted")
        XCTAssertTrue(loaded.completedLevelIds.contains(1))
        XCTAssertTrue(loaded.completedLevelIds.contains(2))
        XCTAssertTrue(loaded.settings.leftHandedControls)
    }
}
