import Foundation
import SceneKit
import UIKit
import CatrisCore

/// Renders the plush 3D rug, crisp cell grid lines (white by default, bright cozy green under valid placements
/// matching Game.mp4!), live placement previews, 3-tier solver hint highlights, and sculpted 3D obstacles.
final class BoardGridNode: SCNNode {
    static let cellSize: Float = 0.25

    private let rugNode = SCNNode()
    private let cellsRoot = SCNNode()
    private let obstaclesRoot = SCNNode()
    private var cellFrameMaterials: [GridPoint: SCNMaterial] = [:]
    private var cellFillNodes: [GridPoint: SCNNode] = [:]
    private var currentBoard: BoardDefinition?

    override init() {
        super.init()
        addChildNode(rugNode)
        addChildNode(cellsRoot)
        addChildNode(obstaclesRoot)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    func configure(board: BoardDefinition, mapId: String) {
        currentBoard = board
        cellsRoot.childNodes.forEach { $0.removeFromParentNode() }
        obstaclesRoot.childNodes.forEach { $0.removeFromParentNode() }
        cellFrameMaterials.removeAll()
        cellFillNodes.removeAll()

        // 1. Scale plush beveled 3D rug neatly around the board with generous cozy margins!
        let boardW = Float(board.cols) * Self.cellSize
        let boardH = Float(board.rows) * Self.cellSize
        let rugGeo = CatrisMeshCache.shared.geometry(named: "prop_rug")
            ?? SCNBox(width: 1.0, height: 0.018, length: 1.0, chamferRadius: 0.04)
        let rugMat = SCNMaterial()
        rugMat.lightingModel = .physicallyBased
        let rugTexName = "rug_\(mapId.lowercased())"
        rugMat.diffuse.contents = AssetBundle.image(named: rugTexName) ?? UIColor(hex: "#EE87A9")
        if mapId == "M01", let norm = AssetBundle.image(named: "rug_m01_norm") {
            rugMat.normal.contents = norm
            rugMat.normal.intensity = 0.45
        }
        rugMat.roughness.contents = NSNumber(value: 0.88)
        rugMat.metalness.contents = NSNumber(value: 0.0)
        rugGeo.materials = [rugMat]
        rugNode.geometry = rugGeo
        rugNode.scale = SCNVector3(boardW + 0.22, 1.0, boardH + 0.20)
        rugNode.position = SCNVector3(0, 0.001, 0)
        rugNode.castsShadow = true

        // 2. Crisp cell borders & subtle hover/hint fill planes for every playable cell!
        let mask = board.playableMask
        let obsSet = board.obstacleCells
        let voids = board.voidCells
        let outlineColor = (mapId == "M05") ? UIColor(hex: "#9B8A82", alpha: 0.72) : UIColor(white: 1.0, alpha: 0.80)

        for c in 0..<board.cols {
            for r in 0..<board.rows {
                let pt = GridPoint(col: c, row: r)
                if voids.contains(pt) { continue }

                let world = localPoint(for: pt, board: board)
                if mask.contains(pt) {
                    let frameMat = SCNMaterial()
                    frameMat.lightingModel = .constant
                    frameMat.diffuse.contents = outlineColor
                    frameMat.writesToDepthBuffer = false

                    let border = buildCellBorderNode(size: Self.cellSize * 0.94, thickness: 0.0075, material: frameMat)
                    border.position = SCNVector3(world.x, 0.0185, world.z)
                    cellsRoot.addChildNode(border)
                    cellFrameMaterials[pt] = frameMat

                    let fillGeo = SCNPlane(width: CGFloat(Self.cellSize * 0.90), height: CGFloat(Self.cellSize * 0.90))
                    fillGeo.cornerRadius = 0.022
                    let fillMat = SCNMaterial()
                    fillMat.lightingModel = .constant
                    fillMat.diffuse.contents = UIColor.clear
                    fillMat.writesToDepthBuffer = false
                    fillGeo.materials = [fillMat]
                    let fillNode = SCNNode(geometry: fillGeo)
                    fillNode.eulerAngles.x = -.pi / 2
                    fillNode.position = SCNVector3(world.x, 0.0180, world.z)
                    cellsRoot.addChildNode(fillNode)
                    cellFillNodes[pt] = fillNode
                } else if obsSet.contains(pt), let obs = board.obstacles.first(where: { $0.point == pt }) {
                    let obsNode = buildObstacleNode(kind: obs.kind)
                    obsNode.position = SCNVector3(world.x, 0.017, world.z)
                    obstaclesRoot.addChildNode(obsNode)
                }
            }
        }
    }

    func localPoint(for cell: GridPoint, board: BoardDefinition) -> SCNVector3 {
        let halfW = Float(board.cols - 1) * 0.5 * Self.cellSize
        let halfH = Float(board.rows - 1) * 0.5 * Self.cellSize
        let x = Float(cell.col) * Self.cellSize - halfW
        let z = -(Float(cell.row) * Self.cellSize - halfH)
        return SCNVector3(x, 0.017, z)
    }

    /// World position of a cat piece's bounding-box centroid when anchored at `(anchor, rotation)`.
    func localCentroid(forCells baseCells: [GridPoint], anchor: GridPoint, rotation: Int, board: BoardDefinition) -> SCNVector3 {
        let rotated = PolyominoMath.rotatedCW(baseCells, steps: rotation)
        let (wCols, hRows) = PolyominoMath.bounds(of: rotated)
        let centerCol = Float(anchor.col) + Float(wCols - 1) * 0.5
        let centerRow = Float(anchor.row) + Float(hRows - 1) * 0.5
        let halfW = Float(board.cols - 1) * 0.5 * Self.cellSize
        let halfH = Float(board.rows - 1) * 0.5 * Self.cellSize
        let x = centerCol * Self.cellSize - halfW
        let z = -(centerRow * Self.cellSize - halfH)
        return SCNVector3(x, 0.017, z)
    }

    /// Convert local XZ centroid of a dragged cat back into the nearest integer grid anchor!
    func nearestAnchor(forLocalPos pos: SCNVector3, baseCells: [GridPoint], rotation: Int, board: BoardDefinition) -> GridPoint {
        let rotated = PolyominoMath.rotatedCW(baseCells, steps: rotation)
        let (wCols, hRows) = PolyominoMath.bounds(of: rotated)
        let halfW = Float(board.cols - 1) * 0.5 * Self.cellSize
        let halfH = Float(board.rows - 1) * 0.5 * Self.cellSize
        let centerCol = (pos.x + halfW) / Self.cellSize
        let centerRow = (-pos.z + halfH) / Self.cellSize
        let anchorCol = Int(round(centerCol - Float(wCols - 1) * 0.5))
        let anchorRow = Int(round(centerRow - Float(hRows - 1) * 0.5))
        return GridPoint(col: anchorCol, row: anchorRow)
    }

    /// Update cell highlight states (occupied green border, live drag valid/invalid preview, solver hint glow).
    func updateHighlights(
        mapId: String,
        occupied: Set<GridPoint>,
        previewCells: [GridPoint],
        previewValid: Bool,
        hintCells: [GridPoint],
        isDragging: Bool
    ) {
        let defaultLine = (mapId == "M05")
            ? UIColor(hex: "#9B8A82", alpha: isDragging ? 0.88 : 0.65)
            : UIColor(white: 1.0, alpha: isDragging ? 0.95 : 0.78)
        let placedGreen = UIColor(hex: "#78D658", alpha: 0.92)
        let previewSet = Set(previewCells)
        let hintSet = Set(hintCells)

        for (pt, frameMat) in cellFrameMaterials {
            let fillMat = cellFillNodes[pt]?.geometry?.firstMaterial
            if previewSet.contains(pt) {
                frameMat.diffuse.contents = previewValid ? UIColor(hex: "#7CE05A") : UIColor(hex: "#E84855")
                fillMat?.diffuse.contents = previewValid
                    ? UIColor(hex: "#96F075", alpha: 0.34)
                    : UIColor(hex: "#E84855", alpha: 0.32)
            } else if hintSet.contains(pt) {
                frameMat.diffuse.contents = UIColor(hex: "#FFD15C")
                fillMat?.diffuse.contents = UIColor(hex: "#FFE182", alpha: 0.42)
            } else if occupied.contains(pt) {
                frameMat.diffuse.contents = placedGreen
                fillMat?.diffuse.contents = UIColor.clear
            } else {
                frameMat.diffuse.contents = defaultLine
                fillMat?.diffuse.contents = UIColor.clear
            }
        }
    }

    private func buildCellBorderNode(size: Float, thickness: Float, material: SCNMaterial) -> SCNNode {
        let root = SCNNode()
        let half = size * 0.5
        let hBar = SCNPlane(width: CGFloat(size), height: CGFloat(thickness))
        hBar.materials = [material]
        let vBar = SCNPlane(width: CGFloat(thickness), height: CGFloat(size))
        vBar.materials = [material]

        let top = SCNNode(geometry: hBar); top.eulerAngles.x = -.pi / 2; top.position = SCNVector3(0, 0, -half)
        let bot = SCNNode(geometry: hBar); bot.eulerAngles.x = -.pi / 2; bot.position = SCNVector3(0, 0,  half)
        let lft = SCNNode(geometry: vBar); lft.eulerAngles.x = -.pi / 2; lft.position = SCNVector3(-half, 0, 0)
        let rgt = SCNNode(geometry: vBar); rgt.eulerAngles.x = -.pi / 2; rgt.position = SCNVector3( half, 0, 0)

        root.addChildNode(top); root.addChildNode(bot); root.addChildNode(lft); root.addChildNode(rgt)
        return root
    }

    private func buildObstacleNode(kind: String) -> SCNNode {
        let (meshName, hexColor, scaleVal): (String, String, Float) = switch kind {
        case "yarn_ball":  ("prop_yarn_ball", "#E87A90", 0.96)
        case "milk_bowl":  ("prop_milk_bowl", "#F7F3EA", 0.96)
        case "acorn":      ("prop_acorn",     "#9B643D", 1.05)
        case "flower_pot": ("prop_ceramic_pot", "#C97A58", 0.65)
        case "book":       ("prop_book",      "#6E8B9E", 0.92)
        case "teacup":     ("prop_teacup",    "#F4ECE0", 0.95)
        default:           ("prop_yarn_ball", "#E8A07A", 0.95)
        }

        let geo = CatrisMeshCache.shared.geometry(named: meshName) ?? SCNSphere(radius: 0.07)
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = UIColor(hex: hexColor)
        mat.roughness.contents = NSNumber(value: kind == "teacup" || kind == "milk_bowl" ? 0.32 : 0.76)
        geo.materials = [mat]

        let node = SCNNode(geometry: geo)
        node.scale = SCNVector3(scaleVal, scaleVal, scaleVal)
        node.castsShadow = true

        // Add tiny sprout leaves on flower_pot obstacle!
        if kind == "flower_pot", let leafGeo = CatrisMeshCache.shared.geometry(named: "prop_monstera") {
            let lMat = SCNMaterial()
            lMat.lightingModel = .physicallyBased
            lMat.diffuse.contents = AssetBundle.image(named: "prop_leaf_albedo") ?? UIColor(hex: "#66AA52")
            lMat.isDoubleSided = true
            leafGeo.materials = [lMat]
            let sprout = SCNNode(geometry: leafGeo)
            sprout.scale = SCNVector3(0.32, 0.32, 0.32)
            sprout.position = SCNVector3(0, 0.08, 0)
            node.addChildNode(sprout)
        }
        return node
    }
}
