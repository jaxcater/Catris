import Foundation
import QuartzCore
import SceneKit
import UIKit

/// Builds each of Catris's 5 bespoke portrait 3D diorama worlds (M01–M05):
/// - Distinct floor material, window/canopy gobo sunlight, warm fill & CC0 HDRI IBL
/// - Sculpted 3D peripheral props with anchored GPU wind sway (plants, curtains, oak roots, lamp, guitar, books)
/// - Rainy window glass shader (M04), floating dust motes / petals / fireflies
/// - Progressive unlockable room decorations (up to 3 per map as player completes boards!)
final class DioramaBuilder {
    private var windMaterials: [SCNMaterial] = []

    func buildMap(
        mapId: String,
        unlockedDecorCount: Int,
        reduceMotion: Bool,
        into scene: SCNScene,
        root: SCNNode
    ) {
        root.childNodes.forEach { $0.removeFromParentNode() }
        windMaterials.removeAll()

        // 1. CC0 Poly Haven Sky IBL for warm coherent indirect ambient light
        if let hdrURL = AssetBundle.url(name: "sky_ibl", ext: "hdr", folder: "Textures") {
            scene.lightingEnvironment.contents = hdrURL
            scene.lightingEnvironment.intensity = (mapId == "M05") ? 0.38 : (mapId == "M04" ? 0.55 : 0.85)
        }

        // 2. Map-specific floor plane
        let floorPlane = SCNPlane(width: 4.5, height: 6.5)
        let floorMat = SCNMaterial()
        floorMat.lightingModel = .physicallyBased
        let texName = "floor_\(mapId.lowercased())"
        floorMat.diffuse.contents = AssetBundle.image(named: texName) ?? UIColor(hex: "#DF9C56")
        floorMat.diffuse.wrapS = .repeat
        floorMat.diffuse.wrapT = .repeat
        floorMat.diffuse.contentsTransform = SCNMatrix4MakeScale(2.5, 4.0, 1.0)
        if mapId == "M01", let norm = AssetBundle.image(named: "floor_m01_norm") {
            floorMat.normal.contents = norm
            floorMat.normal.wrapS = .repeat
            floorMat.normal.wrapT = .repeat
            floorMat.normal.contentsTransform = SCNMatrix4MakeScale(2.5, 4.0, 1.0)
            floorMat.normal.intensity = 0.45
        }
        floorMat.roughness.contents = NSNumber(value: mapId == "M02" ? 0.88 : 0.62)
        floorMat.metalness.contents = NSNumber(value: 0.0)
        floorPlane.materials = [floorMat]

        let floorNode = SCNNode(geometry: floorPlane)
        floorNode.eulerAngles.x = -.pi / 2
        floorNode.position = SCNVector3(0, 0, 0)
        root.addChildNode(floorNode)

        // 3. Map-specific lighting rig, signature props, atmosphere & unlockable decor!
        switch mapId {
        case "M01": buildM01SunlitCorner(root: root, scene: scene, decorCount: unlockedDecorCount, reduceMotion: reduceMotion)
        case "M02": buildM02UnderTheOak(root: root, scene: scene, decorCount: unlockedDecorCount, reduceMotion: reduceMotion)
        case "M03": buildM03GreenhousePorch(root: root, scene: scene, decorCount: unlockedDecorCount, reduceMotion: reduceMotion)
        case "M04": buildM04RainyReadingNook(root: root, scene: scene, decorCount: unlockedDecorCount, reduceMotion: reduceMotion)
        case "M05": buildM05MoonlitAttic(root: root, scene: scene, decorCount: unlockedDecorCount, reduceMotion: reduceMotion)
        default:    buildM01SunlitCorner(root: root, scene: scene, decorCount: unlockedDecorCount, reduceMotion: reduceMotion)
        }
    }

    func updateReduceMotion(_ enabled: Bool) {
        let v = NSNumber(value: Float(enabled ? 1.0 : 0.0))
        for m in windMaterials { m.setValue(v, forKey: "u_reduceMotion") }
    }

    // MARK: - M01: Góc Nắng (Reference Anchor to Game.mp4!)

    private func buildM01SunlitCorner(root: SCNNode, scene: SCNScene, decorCount: Int, reduceMotion: Bool) {
        scene.background.contents = UIColor(hex: "#DF9C56")

        // Warm Ambient Fill (keeps charcoal Nori & dark Sumi readable even in shadow!)
        addAmbient(root: root, color: "#FFE8CC", intensity: 520)

        // Signature Golden Afternoon Window-Mullion Sunbeam Gobo Key Light!
        addGoboKeyLight(
            root: root,
            pos: SCNVector3(1.15, 3.8, -1.05),
            lookAt: SCNVector3(-0.05, 0, 0.05),
            color: "#FFE7B8",
            intensity: 1750,
            goboName: "gobo_window_m01",
            outerAngle: 58
        )

        // Bottom-left Acoustic Guitar + Cozy Green Cushion (recomposed cleanly for Portrait!)
        if let guitar = makeProp("prop_guitar", textureName: "prop_guitar_albedo", roughness: 0.48) {
            guitar.position = SCNVector3(-0.62, 0.0, 0.98)
            guitar.eulerAngles.y = 0.42
            guitar.scale = SCNVector3(0.95, 0.95, 0.95)
            root.addChildNode(guitar)
        }
        if let cushion = makeProp("prop_cushion", hex: "#5C8E58", roughness: 0.86) {
            cushion.position = SCNVector3(-0.66, 0.0, 0.62)
            cushion.eulerAngles.y = 0.25
            root.addChildNode(cushion)
        }

        // Right-edge Potted Broadleaf Monstera Plants w/ anchored GPU wind sway!
        addPottedPlant(root: root, at: SCNVector3(0.72, 0, 0.72), potHex: "#C97E5D", scale: 1.05, windStrength: 0.020, reduceMotion: reduceMotion)
        addPottedPlant(root: root, at: SCNVector3(0.76, 0, -0.82), potHex: "#E8DDD0", scale: 0.85, windStrength: 0.024, reduceMotion: reduceMotion)

        // Top-left Cozy Sofa/Bed edge + Pleated Linen Curtains billowing gently at top window edge!
        if let sofa = makeProp("prop_cushion", hex: "#DDD8DE", roughness: 0.88) {
            sofa.position = SCNVector3(-0.68, 0.0, -0.96)
            sofa.scale = SCNVector3(1.6, 1.3, 1.4)
            root.addChildNode(sofa)
        }
        addCurtain(root: root, at: SCNVector3(-0.42, 0.14, -1.52), hex: "#FAF1E2", windStrength: 0.022, reduceMotion: reduceMotion)
        addCurtain(root: root, at: SCNVector3( 0.48, 0.14, -1.52), hex: "#FAF1E2", windStrength: 0.026, reduceMotion: reduceMotion)

        // Slow drifting golden afternoon dust motes (10–16 visible particles, subtle!)
        addAtmosphereParticles(root: root, color: "#FFF2C2", birthRate: 5.5, size: 0.014, velocity: 0.04, reduceMotion: reduceMotion)

        // Unlockable permanent decor rewards (1 per 4 boards solved!)
        if decorCount >= 1, let yarn = makeProp("prop_yarn_ball", hex: "#F299B6", roughness: 0.85) {
            yarn.position = SCNVector3(-0.58, 0.0, -0.58); root.addChildNode(yarn)
        }
        if decorCount >= 2, let cup = makeProp("prop_teacup", hex: "#F7EFE6", roughness: 0.32) {
            cup.position = SCNVector3(0.58, 0.0, -0.58); root.addChildNode(cup)
        }
        if decorCount >= 3, let book = makeProp("prop_book", hex: "#D68265", roughness: 0.65) {
            book.position = SCNVector3(0.56, 0.0, 0.48); book.eulerAngles.y = -0.35; root.addChildNode(book)
        }
    }

    // MARK: - M02: Dưới Tán Sồi (Under the Old Oak Tree)

    private func buildM02UnderTheOak(root: SCNNode, scene: SCNScene, decorCount: Int, reduceMotion: Bool) {
        scene.background.contents = UIColor(hex: "#82B36B")
        addAmbient(root: root, color: "#EFF7DF", intensity: 540)
        addGoboKeyLight(
            root: root,
            pos: SCNVector3(-1.0, 4.0, -1.1),
            lookAt: SCNVector3(0.05, 0, 0.05),
            color: "#FFF0C4",
            intensity: 1650,
            goboName: "gobo_oak_m02",
            outerAngle: 64
        )

        if let oak = makeProp("prop_oak_roots", hex: "#6F503B", roughness: 0.88) {
            oak.position = SCNVector3(-0.62, 0.0, -0.92)
            oak.scale = SCNVector3(1.25, 1.1, 1.25)
            root.addChildNode(oak)
        }
        addPottedPlant(root: root, at: SCNVector3(0.75, 0, -0.80), potHex: "#7A5B42", scale: 1.15, windStrength: 0.032, reduceMotion: reduceMotion)
        addPottedPlant(root: root, at: SCNVector3(-0.75, 0, 0.78), potHex: "#8B694D", scale: 0.92, windStrength: 0.028, reduceMotion: reduceMotion)

        for (x, z, r) in [(Float(0.60), Float(0.78), Float(0.4)), (-0.54, -0.64, 1.1), (0.64, -0.42, 2.2)] {
            if let acorn = makeProp("prop_acorn", hex: "#8F5A36", roughness: 0.58) {
                acorn.position = SCNVector3(x, 0, z); acorn.eulerAngles = SCNVector3(0.6, r, 0.3)
                acorn.scale = SCNVector3(0.75, 0.75, 0.75); root.addChildNode(acorn)
            }
        }
        addAtmosphereParticles(root: root, color: "#FFE89E", birthRate: 4.0, size: 0.022, velocity: 0.075, reduceMotion: reduceMotion)

        if decorCount >= 1, let bowl = makeProp("prop_milk_bowl", hex: "#EBD8B5", roughness: 0.55) {
            bowl.position = SCNVector3(0.56, 0, 0.54); root.addChildNode(bowl)
        }
        if decorCount >= 2, let cushion = makeProp("prop_cushion", hex: "#E88D72", roughness: 0.85) {
            cushion.position = SCNVector3(-0.56, 0, 0.54); cushion.scale = SCNVector3(0.85, 0.85, 0.85); root.addChildNode(cushion)
        }
        if decorCount >= 3, let cup = makeProp("prop_teacup", hex: "#FFF4E0", roughness: 0.34) {
            cup.position = SCNVector3(0.52, 0, -0.60); root.addChildNode(cup)
        }
    }

    // MARK: - M03: Hiên Nhà Kính (Sunlit Greenhouse Porch)

    private func buildM03GreenhousePorch(root: SCNNode, scene: SCNScene, decorCount: Int, reduceMotion: Bool) {
        scene.background.contents = UIColor(hex: "#D48E72")
        addAmbient(root: root, color: "#FFF6EA", intensity: 560)
        addGoboKeyLight(
            root: root,
            pos: SCNVector3(0.95, 3.9, -1.2),
            lookAt: SCNVector3(0, 0, 0),
            color: "#FFF3DC",
            intensity: 1620,
            goboName: "gobo_greenhouse_m03",
            outerAngle: 62
        )

        addPottedPlant(root: root, at: SCNVector3(-0.70, 0, -0.84), potHex: "#C97555", scale: 1.10, windStrength: 0.024, reduceMotion: reduceMotion)
        addPottedPlant(root: root, at: SCNVector3( 0.72, 0, -0.78), potHex: "#EDE3D5", scale: 0.96, windStrength: 0.026, reduceMotion: reduceMotion)
        addPottedPlant(root: root, at: SCNVector3( 0.70, 0,  0.80), potHex: "#87A688", scale: 0.90, windStrength: 0.022, reduceMotion: reduceMotion)
        addCurtain(root: root, at: SCNVector3(0.0, 0.16, -1.36), hex: "#F7F4EC", windStrength: 0.024, reduceMotion: reduceMotion)
        addAtmosphereParticles(root: root, color: "#FFFDF5", birthRate: 4.5, size: 0.016, velocity: 0.05, reduceMotion: reduceMotion)

        if decorCount >= 1, let pot = makeProp("prop_ceramic_pot", hex: "#D9A07E", roughness: 0.35) {
            pot.position = SCNVector3(-0.62, 0, 0.74); pot.scale = SCNVector3(0.75, 0.75, 0.75); root.addChildNode(pot)
        }
        if decorCount >= 2, let book = makeProp("prop_book", hex: "#7FA380", roughness: 0.70) {
            book.position = SCNVector3(-0.58, 0, 0.45); root.addChildNode(book)
        }
        if decorCount >= 3, let cup = makeProp("prop_teacup", hex: "#D6E5D4", roughness: 0.30) {
            cup.position = SCNVector3(0.56, 0, 0.48); root.addChildNode(cup)
        }
    }

    // MARK: - M04: Ô Cửa Ngày Mưa (Rainy Reading Nook)

    private func buildM04RainyReadingNook(root: SCNNode, scene: SCNScene, decorCount: Int, reduceMotion: Bool) {
        scene.background.contents = UIColor(hex: "#6B5040")
        // Cool rainy sky ambient + cozy warm amber reading lamp light!
        addAmbient(root: root, color: "#BDD0E5", intensity: 440)

        let lampLight = SCNLight()
        lampLight.type = .spot
        lampLight.color = UIColor(hex: "#FFC77D")
        lampLight.intensity = 1780
        lampLight.spotInnerAngle = 25
        lampLight.spotOuterAngle = 72
        lampLight.castsShadow = true
        lampLight.shadowMode = .forward
        lampLight.shadowMapSize = CGSize(width: 1024, height: 1024)
        lampLight.shadowSampleCount = 4
        lampLight.shadowRadius = 4.0
        let lightNode = SCNNode()
        lightNode.light = lampLight
        lightNode.position = SCNVector3(-0.85, 2.8, -0.65)
        lightNode.look(at: SCNVector3(0.05, 0, 0.05))
        root.addChildNode(lightNode)

        // Rainy glass window panel strictly at the top edge (outside play board!)
        let glassGeo = SCNPlane(width: 1.9, height: 0.48)
        let glassMat = SCNMaterial()
        glassMat.lightingModel = .constant
        glassMat.diffuse.contents = UIColor(hex: "#506985", alpha: 0.65)
        glassMat.shaderModifiers = [.fragment: MetalShaderModifiers.rainGlassFragment]
        glassMat.writesToDepthBuffer = false
        glassGeo.materials = [glassMat]
        let glassNode = SCNNode(geometry: glassGeo)
        glassNode.eulerAngles.x = -.pi / 2
        glassNode.position = SCNVector3(0, 0.08, -1.18)
        root.addChildNode(glassNode)

        if let lamp = makeProp("prop_lamp", hex: "#E5B263", roughness: 0.35) {
            lamp.position = SCNVector3(-0.68, 0, -0.78); root.addChildNode(lamp)
        }
        if let b1 = makeProp("prop_book", hex: "#5C768F", roughness: 0.72) {
            b1.position = SCNVector3(0.64, 0, -0.72); b1.eulerAngles.y = 0.28; root.addChildNode(b1)
        }
        if let b2 = makeProp("prop_book", hex: "#B87A62", roughness: 0.72) {
            b2.position = SCNVector3(0.66, 0.055, -0.71); b2.eulerAngles.y = -0.15; root.addChildNode(b2)
        }
        if let cup = makeProp("prop_teacup", hex: "#F0E6D8", roughness: 0.30) {
            cup.position = SCNVector3(0.62, 0, 0.74); root.addChildNode(cup)
        }
        if let cushion = makeProp("prop_cushion", hex: "#6B86A0", roughness: 0.88) {
            cushion.position = SCNVector3(-0.64, 0, 0.82); root.addChildNode(cushion)
        }

        if decorCount >= 1, let yarn = makeProp("prop_yarn_ball", hex: "#94B3CF", roughness: 0.84) {
            yarn.position = SCNVector3(-0.58, 0, 0.48); root.addChildNode(yarn)
        }
        if decorCount >= 2, let b3 = makeProp("prop_book", hex: "#8A9C78", roughness: 0.70) {
            b3.position = SCNVector3(0.58, 0, 0.45); b3.eulerAngles.y = 0.45; root.addChildNode(b3)
        }
        if decorCount >= 3, let bowl = makeProp("prop_milk_bowl", hex: "#E6DDD2", roughness: 0.36) {
            bowl.position = SCNVector3(-0.56, 0, -0.45); root.addChildNode(bowl)
        }
    }

    // MARK: - M05: Gác Mái Trăng (Moonlit Starry Attic)

    private func buildM05MoonlitAttic(root: SCNNode, scene: SCNScene, decorCount: Int, reduceMotion: Bool) {
        scene.background.contents = UIColor(hex: "#382C38")
        addAmbient(root: root, color: "#C5CEF0", intensity: 460)
        addGoboKeyLight(
            root: root,
            pos: SCNVector3(0.95, 3.8, -1.1),
            lookAt: SCNVector3(0, 0, 0),
            color: "#D8E5FF",
            intensity: 1450,
            goboName: "gobo_moon_m05",
            outerAngle: 62
        )

        // Warm cozy amber lantern fill on left side so dark cats & board remain crisp & inviting!
        let amber = SCNLight()
        amber.type = .omni
        amber.color = UIColor(hex: "#FFBE6E")
        amber.intensity = 650
        amber.attenuationEndDistance = 3.2
        let amberNode = SCNNode()
        amberNode.light = amber
        amberNode.position = SCNVector3(-0.72, 0.48, -0.68)
        root.addChildNode(amberNode)

        if let lamp = makeProp("prop_lamp", hex: "#F2B65C", roughness: 0.32) {
            lamp.position = SCNVector3(-0.68, 0, -0.78); root.addChildNode(lamp)
        }
        if let book = makeProp("prop_book", hex: "#766A8E", roughness: 0.70) {
            book.position = SCNVector3(0.65, 0, -0.74); book.eulerAngles.y = -0.3; root.addChildNode(book)
        }
        if let cushion = makeProp("prop_cushion", hex: "#E8DAC8", roughness: 0.88) {
            cushion.position = SCNVector3(-0.65, 0, 0.84); root.addChildNode(cushion)
        }
        addPottedPlant(root: root, at: SCNVector3(0.72, 0, 0.78), potHex: "#7A6A7C", scale: 0.85, windStrength: 0.014, reduceMotion: reduceMotion)

        // Warm golden fireflies / starlight motes floating gently outside the board!
        addAtmosphereParticles(root: root, color: "#FFE28A", birthRate: 5.0, size: 0.018, velocity: 0.045, reduceMotion: reduceMotion)

        if decorCount >= 1, let yarn = makeProp("prop_yarn_ball", hex: "#E8C47C", roughness: 0.82) {
            yarn.position = SCNVector3(0.56, 0, 0.48); root.addChildNode(yarn)
        }
        if decorCount >= 2, let cup = makeProp("prop_teacup", hex: "#DDD5E6", roughness: 0.32) {
            cup.position = SCNVector3(-0.56, 0, 0.48); root.addChildNode(cup)
        }
        if decorCount >= 3, let b2 = makeProp("prop_book", hex: "#C89D6C", roughness: 0.68) {
            b2.position = SCNVector3(0.58, 0, -0.46); root.addChildNode(b2)
        }
    }

    // MARK: - Helpers

    private func addAmbient(root: SCNNode, color: String, intensity: CGFloat) {
        let light = SCNLight()
        light.type = .ambient
        light.color = UIColor(hex: color)
        light.intensity = intensity
        let node = SCNNode()
        node.light = light
        root.addChildNode(node)
    }

    private func addGoboKeyLight(
        root: SCNNode, pos: SCNVector3, lookAt: SCNVector3,
        color: String, intensity: CGFloat, goboName: String, outerAngle: CGFloat
    ) {
        let light = SCNLight()
        light.type = .spot
        light.color = UIColor(hex: color)
        light.intensity = intensity
        light.spotInnerAngle = outerAngle * 0.65
        light.spotOuterAngle = outerAngle
        light.castsShadow = true
        light.shadowMode = .forward
        light.shadowMapSize = CGSize(width: 1024, height: 1024)
        light.shadowSampleCount = 4
        light.shadowRadius = 3.2
        light.shadowBias = 0.0025
        light.shadowColor = UIColor(hex: "#58424D", alpha: 0.48)
        if let goboImg = AssetBundle.image(named: goboName) {
            light.gobo?.contents = goboImg
            light.gobo?.intensity = 0.85
        }
        let node = SCNNode()
        node.light = light
        node.position = pos
        node.look(at: lookAt)
        root.addChildNode(node)
    }

    private func makeProp(_ meshName: String, textureName: String? = nil, hex: String = "#FFFFFF", roughness: Float = 0.72) -> SCNNode? {
        guard let geo = CatrisMeshCache.shared.geometry(named: meshName) else { return nil }
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        if let tName = textureName, let img = AssetBundle.image(named: tName) {
            mat.diffuse.contents = img
        } else {
            mat.diffuse.contents = UIColor(hex: hex)
        }
        mat.roughness.contents = NSNumber(value: roughness)
        mat.metalness.contents = NSNumber(value: 0.0)
        geo.materials = [mat]
        let node = SCNNode(geometry: geo)
        node.castsShadow = true
        return node
    }

    private func addPottedPlant(root: SCNNode, at pos: SCNVector3, potHex: String, scale: Float, windStrength: Float, reduceMotion: Bool) {
        let holder = SCNNode()
        holder.position = pos
        holder.scale = SCNVector3(scale, scale, scale)

        if let pot = makeProp("prop_ceramic_pot", hex: potHex, roughness: 0.36) {
            holder.addChildNode(pot)
        }
        if let leafGeo = CatrisMeshCache.shared.geometry(named: "prop_monstera") {
            let lMat = SCNMaterial()
            lMat.lightingModel = .physicallyBased
            lMat.diffuse.contents = AssetBundle.image(named: "prop_leaf_albedo") ?? UIColor(hex: "#5FA44A")
            lMat.roughness.contents = NSNumber(value: 0.65)
            lMat.isDoubleSided = true
            lMat.shaderModifiers = [.geometry: MetalShaderModifiers.windSwayGeometry]
            lMat.setValue(NSNumber(value: windStrength), forKey: "u_windStrength")
            lMat.setValue(NSNumber(value: Float(1.35)), forKey: "u_windSpeed")
            lMat.setValue(NSNumber(value: Float(reduceMotion ? 1.0 : 0.0)), forKey: "u_reduceMotion")
            windMaterials.append(lMat)
            leafGeo.materials = [lMat]
            let leaves = SCNNode(geometry: leafGeo)
            leaves.position = SCNVector3(0, 0.04, 0)
            leaves.castsShadow = true
            holder.addChildNode(leaves)
        }
        root.addChildNode(holder)
    }

    private func addCurtain(root: SCNNode, at pos: SCNVector3, hex: String, windStrength: Float, reduceMotion: Bool) {
        guard let geo = CatrisMeshCache.shared.geometry(named: "prop_curtain") else { return }
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = UIColor(hex: hex, alpha: 0.88)
        mat.roughness.contents = NSNumber(value: 0.90)
        mat.isDoubleSided = true
        mat.shaderModifiers = [.geometry: MetalShaderModifiers.windSwayGeometry]
        mat.setValue(NSNumber(value: windStrength), forKey: "u_windStrength")
        mat.setValue(NSNumber(value: Float(0.95)), forKey: "u_windSpeed")
        mat.setValue(NSNumber(value: Float(reduceMotion ? 1.0 : 0.0)), forKey: "u_reduceMotion")
        windMaterials.append(mat)
        geo.materials = [mat]
        let node = SCNNode(geometry: geo)
        node.position = pos
        node.castsShadow = true
        root.addChildNode(node)
    }

    private func addAtmosphereParticles(root: SCNNode, color: String, birthRate: CGFloat, size: CGFloat, velocity: CGFloat, reduceMotion: Bool) {
        let holder = SCNNode()
        holder.position = SCNVector3(0, 0.36, -0.2)
        let sys = SCNParticleSystem()
        sys.birthRate = reduceMotion ? birthRate * 0.2 : birthRate
        sys.particleLifeSpan = 6.0
        sys.emitterShape = SCNBox(width: 1.8, height: 0.1, length: 2.6, chamferRadius: 0)
        sys.particleSize = size
        sys.particleSizeVariation = size * 0.45
        sys.particleVelocity = velocity
        sys.spreadingAngle = 25
        sys.emittingDirection = SCNVector3(-0.35, -0.05, 0.65)
        sys.particleColor = UIColor(hex: color)
        sys.blendMode = .additive
        sys.isLightingEnabled = false
        let alphaAnim = CAKeyframeAnimation(keyPath: "opacity")
        alphaAnim.values = [0.0, 0.55, 0.45, 0.0]
        alphaAnim.keyTimes = [0.0, 0.25, 0.75, 1.0]
        sys.propertyControllers = [.opacity: SCNParticlePropertyController(animation: alphaAnim)]
        holder.addParticleSystem(sys)
        root.addChildNode(holder)
    }
}
