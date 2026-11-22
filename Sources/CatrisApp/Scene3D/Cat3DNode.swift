import Foundation
import QuartzCore
import SceneKit
import UIKit
import CatrisCore

enum CatExpression {
    case sleepy
    case awake
    case surprised
    case angry
    case happy
}

/// Complete sculpted 3D organic cat entity with:
/// - Smooth SDF-sculpted `.cmesh` geometry + painterly coat texture
/// - GPU Metal soft-body bend, squash-and-stretch, chest breathing & tail wag
/// - Cloned inverted-hull warm-white sticker silhouette outline (fades smoothly on hover/drag!)
/// - Animated red-black diagonal warning stripes shader on invalid drop
/// - Hierarchical 3D expressive face (eyes, animated blink eyelids, tracking pupils, cute fangs, blep tongue, whiskers, rosy blush, Pudding's 3D fish plushie, Azuki's bow)
/// - Detached height-responsive soft contact shadow + floating Zzz & petting hearts!
final class Cat3DNode: SCNNode {
    let pieceIndex: Int // -1 for fixed sleeping cat
    let catDef: CatDefinition
    let isLocked: Bool

    let visualRoot = SCNNode()
    private let bodyNode = SCNNode()
    private let outlineNode = SCNNode()
    private let faceRoot = SCNNode()
    private let shadowNode = SCNNode()

    private var bodyMaterial: SCNMaterial!
    private var outlineMaterial: SCNMaterial!

    // Animated facial sub-nodes
    private var leftEyeNode = SCNNode()
    private var rightEyeNode = SCNNode()
    private var leftPupilNode = SCNNode()
    private var rightPupilNode = SCNNode()
    private var leftEyelidNode = SCNNode()
    private var rightEyelidNode = SCNNode()
    private var leftAngryBrow = SCNNode()
    private var rightAngryBrow = SCNNode()
    private var leftHappyArc = SCNNode()
    private var rightHappyArc = SCNNode()
    private var leftBlush = SCNNode()
    private var rightBlush = SCNNode()
    private var zzzNode: SCNNode?
    private var heartEmitterNode = SCNNode()

    // Spring animation state (decoupled from logical board placement!)
    var targetWorldPos: SCNVector3 = SCNVector3Zero
    var targetLiftY: Float = 0.017
    var targetYaw: Float = 0
    var targetScale: Float = 1.0

    private var curWorldPos: SCNVector3 = SCNVector3Zero
    private var curLiftY: Float = 0.017
    private var curYaw: Float = 0
    private var curScale: Float = 1.0

    private var squashVal: Float = 0
    private var squashVel: Float = 0
    private var bendX: Float = 0
    private var bendZ: Float = 0
    private var invalidMix: Float = 0
    private var targetInvalidMix: Float = 0
    private var outlineOpacity: Float = 0
    private var targetOutlineOpacity: Float = 0
    private var hintPulse: Float = 0

    // Independent idle timers (seeded uniquely per cat so cats NEVER blink in unison!)
    private let breathPhase: Float
    private var nextBlinkTime: Double
    private var blinkProgress: Float = 0
    private var isBlinking = false
    private var nextGazeTime: Double
    private var gazeTarget = CGPoint.zero
    private var gazeCurrent = CGPoint.zero
    private var expression: CatExpression = .awake
    private var petHappyTimer: Double = 0
    private var reduceMotion: Bool = false

    private var anchorData: CatAnchorData?

    init(pieceIndex: Int, catDef: CatDefinition, isLocked: Bool) {
        self.pieceIndex = pieceIndex
        self.catDef = catDef
        self.isLocked = isLocked
        self.breathPhase = Float((pieceIndex + 3) * 17 % 31) * 0.21
        self.nextBlinkTime = Double.random(in: 2.5...6.5)
        self.nextGazeTime = Double.random(in: 1.8...4.5)
        super.init()

        self.name = isLocked ? "locked_cat_\(catDef.id)" : "cat_piece_\(pieceIndex)"
        self.anchorData = CatrisMeshCache.shared.anchor(forCatId: catDef.id)

        addChildNode(shadowNode)
        addChildNode(visualRoot)
        visualRoot.addChildNode(bodyNode)
        visualRoot.addChildNode(outlineNode)
        visualRoot.addChildNode(faceRoot)
        visualRoot.addChildNode(heartEmitterNode)

        buildBodyAndOutline()
        buildContactShadow()
        buildExpressiveFace()
        setExpression(isLocked ? .sleepy : .awake)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    private func buildBodyAndOutline() {
        let meshName = "cat_\(catDef.id)"
        let geo = CatrisMeshCache.shared.geometry(named: meshName)
            ?? SCNSphere(radius: 0.10)

        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        if let tex = AssetBundle.image(named: "cat_\(catDef.id)_albedo") {
            mat.diffuse.contents = tex
        } else {
            mat.diffuse.contents = UIColor(hex: catDef.baseHex)
        }
        mat.roughness.contents = NSNumber(value: 0.74)
        mat.metalness.contents = NSNumber(value: 0.0)
        mat.shaderModifiers = [
            .geometry: MetalShaderModifiers.catSoftBodyGeometry,
            .surface: MetalShaderModifiers.catSurfaceAndWarning
        ]
        mat.setValue(NSNumber(value: breathPhase), forKey: "u_breathPhase")
        mat.setValue(NSNumber(value: Float(1.0)), forKey: "u_breathAmp")
        mat.setValue(NSNumber(value: Float(0.0)), forKey: "u_squash")
        mat.setValue(NSNumber(value: Float(0.0)), forKey: "u_bendX")
        mat.setValue(NSNumber(value: Float(0.0)), forKey: "u_bendZ")
        mat.setValue(NSNumber(value: Float(1.0)), forKey: "u_tailAmp")
        mat.setValue(NSNumber(value: Float(0.0)), forKey: "u_reduceMotion")
        mat.setValue(NSNumber(value: Float(0.0)), forKey: "u_invalidMix")
        mat.setValue(NSNumber(value: Float(0.0)), forKey: "u_hintPulse")
        mat.setValue(NSNumber(value: Float(0.24)), forKey: "u_rimDarken")

        geo.materials = [mat]
        bodyNode.geometry = geo
        bodyNode.castsShadow = true
        self.bodyMaterial = mat

        // Cloned inverted-hull warm-white sticker silhouette outline (matches Game.mp4 pickup outline!)
        if let outlineGeo = geo.copy() as? SCNGeometry {
            let oMat = SCNMaterial()
            oMat.lightingModel = .constant
            oMat.diffuse.contents = UIColor(hex: "#FFFDF7")
            oMat.cullMode = .front
            oMat.writesToDepthBuffer = true
            oMat.transparency = 0.0
            oMat.shaderModifiers = [.geometry: MetalShaderModifiers.whiteOutlineGeometry]
            oMat.setValue(NSNumber(value: breathPhase), forKey: "u_breathPhase")
            oMat.setValue(NSNumber(value: Float(1.0)), forKey: "u_breathAmp")
            oMat.setValue(NSNumber(value: Float(0.0)), forKey: "u_squash")
            oMat.setValue(NSNumber(value: Float(0.0)), forKey: "u_bendX")
            oMat.setValue(NSNumber(value: Float(0.0)), forKey: "u_bendZ")
            oMat.setValue(NSNumber(value: Float(1.0)), forKey: "u_tailAmp")
            oMat.setValue(NSNumber(value: Float(0.0)), forKey: "u_reduceMotion")
            oMat.setValue(NSNumber(value: Float(0.011)), forKey: "u_outlineWidth")
            outlineGeo.materials = [oMat]
            outlineNode.geometry = outlineGeo
            outlineNode.castsShadow = false
            outlineNode.isHidden = true
            self.outlineMaterial = oMat
        }
    }

    private func buildContactShadow() {
        let (wCols, hRows) = PolyominoMath.bounds(of: catDef.cells)
        let shadowW = CGFloat(wCols) * 0.25 + 0.05
        let shadowH = CGFloat(hRows) * 0.25 + 0.05
        let plane = SCNPlane(width: shadowW, height: shadowH)
        let mat = SCNMaterial()
        mat.lightingModel = .constant
        mat.diffuse.contents = Self.makeSoftShadowImage()
        mat.writesToDepthBuffer = false
        mat.readsFromDepthBuffer = true
        plane.materials = [mat]
        shadowNode.geometry = plane
        shadowNode.eulerAngles.x = -.pi / 2
        shadowNode.position = SCNVector3(0.008, 0.002, 0.014)
        shadowNode.opacity = 0.36
        shadowNode.castsShadow = false
    }

    private func buildExpressiveFace() {
        guard let a = anchorData else { return }
        let lPos = CatAnchorData.vec(a.leftEyePos)
        let rPos = CatAnchorData.vec(a.rightEyePos)
        let nPos = CatAnchorData.vec(a.nosePos)
        let eyeR = CGFloat(a.eyeRadius)
        let yawRad = a.faceYawDeg * .pi / 180.0

        // Sclera / Iris spheres flattened cleanly onto head crown
        let irisMat = SCNMaterial()
        irisMat.lightingModel = .physicallyBased
        irisMat.diffuse.contents = UIColor(hex: a.eyeColorHex)
        irisMat.roughness.contents = NSNumber(value: 0.22)

        let pupilMat = SCNMaterial()
        pupilMat.lightingModel = .constant
        pupilMat.diffuse.contents = UIColor(hex: "#18161C")

        let whiteMat = SCNMaterial()
        whiteMat.lightingModel = .constant
        whiteMat.diffuse.contents = UIColor.white

        let lidMat = SCNMaterial()
        lidMat.lightingModel = .physicallyBased
        lidMat.diffuse.contents = UIColor(hex: catDef.baseHex)
        lidMat.roughness.contents = NSNumber(value: 0.74)

        let darkLineMat = SCNMaterial()
        darkLineMat.lightingModel = .constant
        darkLineMat.diffuse.contents = UIColor(hex: "#261E1C")

        func makeEye(at pos: SCNVector3, isLeft: Bool) -> (SCNNode, SCNNode, SCNNode, SCNNode, SCNNode) {
            let root = SCNNode()
            root.position = SCNVector3(pos.x, pos.y + 0.003, pos.z)
            root.eulerAngles.y = yawRad

            // Main colored eye
            let scleraGeo = SCNSphere(radius: eyeR)
            scleraGeo.materials = [a.eyeStyle == "big_blue" ? whiteMat : irisMat]
            let sclera = SCNNode(geometry: scleraGeo)
            sclera.scale = SCNVector3(1.0, 0.45, 1.0)
            root.addChildNode(sclera)

            // Tracking pupil + sparkle catchlight
            let pupilRoot = SCNNode()
            let pGeo = SCNSphere(radius: eyeR * (a.eyeStyle == "big_blue" ? 0.68 : 0.56))
            pGeo.materials = [a.eyeStyle == "big_blue" ? irisMat : pupilMat]
            let pNode = SCNNode(geometry: pGeo)
            pNode.scale = SCNVector3(1.0, 0.55, 1.0)
            pNode.position = SCNVector3(0, Float(eyeR) * 0.34, 0.001)
            pupilRoot.addChildNode(pNode)

            let glint = SCNNode(geometry: SCNSphere(radius: eyeR * 0.22))
            glint.geometry?.materials = [whiteMat]
            glint.position = SCNVector3(-Float(eyeR) * 0.22, Float(eyeR) * 0.56, -Float(eyeR) * 0.16)
            pupilRoot.addChildNode(glint)
            root.addChildNode(pupilRoot)

            // Blinking / sleepy closed eyelid bar
            let lid = SCNNode(geometry: SCNCapsule(capRadius: 0.0038, height: eyeR * 2.1))
            lid.geometry?.materials = [darkLineMat]
            lid.eulerAngles.z = .pi / 2
            lid.position = SCNVector3(0, Float(eyeR) * 0.48, 0.001)
            lid.isHidden = true
            root.addChildNode(lid)

            // Angry brow slant (> <)
            let brow = SCNNode(geometry: SCNCapsule(capRadius: 0.0036, height: eyeR * 2.1))
            brow.geometry?.materials = [darkLineMat]
            brow.eulerAngles = SCNVector3(0, isLeft ? -0.35 : 0.35, .pi / 2)
            brow.position = SCNVector3(0, Float(eyeR) * 0.62, -Float(eyeR) * 0.55)
            brow.isHidden = true
            root.addChildNode(brow)

            // Happy smiling arc (^ ^)
            let arc = SCNNode(geometry: SCNTorus(ringRadius: eyeR * 0.72, pipeRadius: 0.0032))
            arc.geometry?.materials = [darkLineMat]
            arc.position = SCNVector3(0, Float(eyeR) * 0.42, 0.004)
            arc.scale = SCNVector3(1.0, 1.0, 0.55)
            arc.isHidden = true
            root.addChildNode(arc)

            faceRoot.addChildNode(root)
            return (root, pupilRoot, lid, brow, arc)
        }

        (leftEyeNode, leftPupilNode, leftEyelidNode, leftAngryBrow, leftHappyArc) = makeEye(at: lPos, isLeft: true)
        (rightEyeNode, rightPupilNode, rightEyelidNode, rightAngryBrow, rightHappyArc) = makeEye(at: rPos, isLeft: false)

        // Rosy blush cheeks (appear when petted or happy!)
        let blushMat = SCNMaterial()
        blushMat.lightingModel = .constant
        blushMat.diffuse.contents = UIColor(hex: "#F48498", alpha: 0.72)
        let blushGeo = SCNSphere(radius: 0.013)
        blushGeo.materials = [blushMat]
        leftBlush = SCNNode(geometry: blushGeo)
        leftBlush.scale = SCNVector3(1.2, 0.3, 0.8)
        leftBlush.position = SCNVector3(lPos.x - 0.014, lPos.y - 0.002, lPos.z + 0.016)
        leftBlush.isHidden = true
        rightBlush = SCNNode(geometry: blushGeo)
        rightBlush.scale = SCNVector3(1.2, 0.3, 0.8)
        rightBlush.position = SCNVector3(rPos.x + 0.014, rPos.y - 0.002, rPos.z + 0.016)
        rightBlush.isHidden = true
        faceRoot.addChildNode(leftBlush)
        faceRoot.addChildNode(rightBlush)

        // Cute pink/coral cat nose
        let noseMat = SCNMaterial()
        noseMat.lightingModel = .physicallyBased
        noseMat.diffuse.contents = UIColor(hex: a.hasBlep ? "#8A3A3A" : "#E07F89")
        noseMat.roughness.contents = NSNumber(value: 0.35)
        let nose = SCNNode(geometry: SCNSphere(radius: 0.009))
        nose.geometry?.materials = [noseMat]
        nose.scale = SCNVector3(1.25, 0.65, 0.95)
        nose.position = SCNVector3(nPos.x, nPos.y + 0.003, nPos.z)
        faceRoot.addChildNode(nose)

        // Nori's iconic two tiny cute white vampire fangs!
        if a.hasFangs {
            for dx in [-0.009 as Float, 0.009 as Float] {
                let fang = SCNNode(geometry: SCNCone(topRadius: 0.0, bottomRadius: 0.0042, height: 0.013))
                fang.geometry?.materials = [whiteMat]
                fang.eulerAngles.x = .pi * 0.68
                fang.position = SCNVector3(nPos.x + dx, nPos.y - 0.001, nPos.z + 0.013)
                faceRoot.addChildNode(fang)
            }
        }

        // Pudding's cute tiny pink blep tongue!
        if a.hasBlep {
            let blepMat = SCNMaterial()
            blepMat.lightingModel = .physicallyBased
            blepMat.diffuse.contents = UIColor(hex: "#F27D8C")
            let blep = SCNNode(geometry: SCNSphere(radius: 0.0085))
            blep.geometry?.materials = [blepMat]
            blep.scale = SCNVector3(1.1, 0.45, 1.3)
            blep.position = SCNVector3(nPos.x, nPos.y + 0.001, nPos.z + 0.014)
            faceRoot.addChildNode(blep)
        }

        // Delicate 3D whiskers on left & right cheeks!
        let whiskMat = SCNMaterial()
        whiskMat.lightingModel = .constant
        whiskMat.diffuse.contents = catDef.id == "nori" || catDef.id == "sumi" || catDef.id == "sesame"
            ? UIColor(hex: "#DDD8D0")
            : UIColor(hex: "#3E3430")
        let lwPos = CatAnchorData.vec(a.leftWhiskerPos)
        let rwPos = CatAnchorData.vec(a.rightWhiskerPos)
        for (wPos, sign) in [(lwPos, Float(-1)), (rwPos, Float(1))] {
            let wGroup = SCNNode()
            wGroup.position = SCNVector3(wPos.x, wPos.y + 0.003, wPos.z)
            wGroup.eulerAngles.y = yawRad
            for k in -1...1 {
                let w = SCNNode(geometry: SCNCapsule(capRadius: 0.0016, height: 0.036))
                w.geometry?.materials = [whiskMat]
                w.eulerAngles = SCNVector3(0, Float(k) * 0.24, .pi / 2)
                w.position = SCNVector3(sign * 0.014, 0, Float(k) * 0.006)
                wGroup.addChildNode(w)
            }
            faceRoot.addChildNode(wGroup)
        }

        // Pudding's sculpted 3D Sky-Blue Fish Plushie!
        if a.hasFishPlushie, let fp = a.fishPos,
           let fishGeo = CatrisMeshCache.shared.geometry(named: "prop_fish_plushie") {
            let fMat = SCNMaterial()
            fMat.lightingModel = .physicallyBased
            fMat.diffuse.contents = AssetBundle.image(named: "prop_fish_albedo") ?? UIColor(hex: "#4AA3E8")
            fMat.roughness.contents = NSNumber(value: 0.78)
            fishGeo.materials = [fMat]
            let fishNode = SCNNode(geometry: fishGeo)
            fishNode.position = CatAnchorData.vec(fp)
            fishNode.eulerAngles.y = 0.22
            fishNode.castsShadow = true
            visualRoot.addChildNode(fishNode)
        }

        // Azuki's cute Sky-Blue Ear Bow!
        if a.hasEarBow, let bp = a.bowPos,
           let bowGeo = CatrisMeshCache.shared.geometry(named: "prop_ear_bow") {
            let bMat = SCNMaterial()
            bMat.lightingModel = .physicallyBased
            bMat.diffuse.contents = UIColor(hex: "#6BB6F0")
            bMat.roughness.contents = NSNumber(value: 0.55)
            bowGeo.materials = [bMat]
            let bowNode = SCNNode(geometry: bowGeo)
            bowNode.position = CatAnchorData.vec(bp)
            bowNode.eulerAngles.y = -0.3
            visualRoot.addChildNode(bowNode)
        }

        // Sleepy floating blue "Z z z" particle emitter (exact homage to Game.mp4!)
        let zNode = SCNNode()
        zNode.position = CatAnchorData.vec(a.zzzPos)
        let zSys = SCNParticleSystem()
        zSys.birthRate = 0.85
        zSys.particleLifeSpan = 2.4
        zSys.particleSize = 0.036
        zSys.particleSizeVariation = 0.014
        zSys.particleVelocity = 0.055
        zSys.spreadingAngle = 14
        zSys.emittingDirection = SCNVector3(0.25, 0.7, -0.45)
        zSys.particleImage = Self.makeZzzSpriteImage()
        zSys.particleColor = UIColor(hex: "#78B2F5")
        zSys.blendMode = .alpha
        zSys.isLightingEnabled = false
        let opacityAnim = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnim.values = [0.0, 0.95, 0.85, 0.0]
        opacityAnim.keyTimes = [0.0, 0.18, 0.72, 1.0]
        zSys.propertyControllers = [.opacity: SCNParticlePropertyController(animation: opacityAnim)]
        zNode.addParticleSystem(zSys)
        zNode.isHidden = true
        visualRoot.addChildNode(zNode)
        self.zzzNode = zNode

        heartEmitterNode.position = SCNVector3(a.headPos[0], a.headPos[1] + 0.05, a.headPos[2])
    }

    // MARK: - State & Interaction Controls

    func snapImmediately(worldPos: SCNVector3, liftY: Float, yaw: Float, scale: Float) {
        targetWorldPos = worldPos
        curWorldPos = worldPos
        targetLiftY = liftY
        curLiftY = liftY
        targetYaw = yaw
        curYaw = yaw
        targetScale = scale
        curScale = scale
        position = SCNVector3(worldPos.x, 0, worldPos.z)
        visualRoot.position = SCNVector3(0, liftY, 0)
        eulerAngles.y = yaw
        self.scale = SCNVector3(scale, scale, scale)
    }

    func setReduceMotion(_ enabled: Bool) {
        reduceMotion = enabled
        let val = NSNumber(value: Float(enabled ? 1.0 : 0.0))
        bodyMaterial?.setValue(val, forKey: "u_reduceMotion")
        outlineMaterial?.setValue(val, forKey: "u_reduceMotion")
    }

    func setSelectedOutline(_ visible: Bool) {
        targetOutlineOpacity = visible ? 1.0 : 0.0
    }

    func setInvalidWarning(_ active: Bool) {
        targetInvalidMix = active ? 1.0 : 0.0
        if active {
            setExpression(.angry)
        }
    }

    func setHintHighlight(_ active: Bool) {
        hintPulse = active ? 1.0 : 0.0
        bodyMaterial?.setValue(NSNumber(value: hintPulse), forKey: "u_hintPulse")
    }

    func triggerSquash(impulse: Float) {
        squashVel += impulse
    }

    func triggerPetReaction() {
        petHappyTimer = 1.6
        setExpression(.happy)
        triggerSquash(impulse: 1.55)
        emitHearts()
    }

    func triggerLockedWiggle() {
        triggerSquash(impulse: 1.15)
        let shake = SCNAction.sequence([
            SCNAction.rotateBy(x: 0, y: 0.09, z: 0, duration: 0.06),
            SCNAction.rotateBy(x: 0, y: -0.18, z: 0, duration: 0.08),
            SCNAction.rotateBy(x: 0, y: 0.09, z: 0, duration: 0.06),
        ])
        visualRoot.runAction(shake)
        zzzNode?.isHidden = false
    }

    func setExpression(_ exp: CatExpression) {
        expression = exp
        let showEyes = (exp == .awake || exp == .surprised || exp == .angry)
        let showLid = (exp == .sleepy)
        let showAngry = (exp == .angry)
        let showHappy = (exp == .happy)

        for eye in [leftEyeNode, rightEyeNode] {
            for child in eye.childNodes {
                if child === leftEyelidNode || child === rightEyelidNode {
                    child.isHidden = !showLid
                } else if child === leftAngryBrow || child === rightAngryBrow {
                    child.isHidden = !showAngry
                } else if child === leftHappyArc || child === rightHappyArc {
                    child.isHidden = !showHappy
                } else {
                    child.isHidden = !showEyes
                }
            }
        }
        let eyeScale: Float = (exp == .surprised) ? 1.18 : 1.0
        leftEyeNode.scale = SCNVector3(eyeScale, eyeScale, eyeScale)
        rightEyeNode.scale = SCNVector3(eyeScale, eyeScale, eyeScale)

        leftBlush.isHidden = !showHappy
        rightBlush.isHidden = !showHappy
        zzzNode?.isHidden = (exp != .sleepy)
    }

    private func emitHearts() {
        let sys = SCNParticleSystem()
        sys.birthRate = 5
        sys.emissionDuration = 0.55
        sys.loops = false
        sys.particleLifeSpan = 1.1
        sys.particleSize = 0.032
        sys.particleVelocity = 0.09
        sys.spreadingAngle = 35
        sys.emittingDirection = SCNVector3(0, 1, -0.3)
        sys.particleImage = Self.makeHeartSpriteImage()
        sys.particleColor = UIColor(hex: "#F27B96")
        sys.isLightingEnabled = false
        heartEmitterNode.addParticleSystem(sys)
    }

    // MARK: - Per-Frame Damped Spring & Procedural Animation Update

    func update(dt rawDt: Float, currentTime: Double) {
        let dt = min(rawDt, 1.0 / 24.0) // Clamp dt safely after background resume!

        // 1. Smooth damped follow toward target world position
        let prevX = curWorldPos.x
        let prevZ = curWorldPos.z
        let posFollow = 1.0 - exp(-22.0 * dt)
        curWorldPos.x += (targetWorldPos.x - curWorldPos.x) * posFollow
        curWorldPos.z += (targetWorldPos.z - curWorldPos.z) * posFollow
        position = SCNVector3(curWorldPos.x, 0, curWorldPos.z)

        // Compute world drag velocity -> rotate into cat local space for GPU liquid-cat bend!
        let vx = (curWorldPos.x - prevX) / max(dt, 0.004)
        let vz = (curWorldPos.z - prevZ) / max(dt, 0.004)
        let cosY = cos(-curYaw)
        let sinY = sin(-curYaw)
        let localVx = vx * cosY - vz * sinY
        let localVz = vx * sinY + vz * cosY
        let targetBendX = max(-0.075, min(0.075, -localVx * 0.022))
        let targetBendZ = max(-0.075, min(0.075, -localVz * 0.022))
        let bendLerp = 1.0 - exp(-14.0 * dt)
        bendX += (targetBendX - bendX) * bendLerp
        bendZ += (targetBendZ - bendZ) * bendLerp

        // 2. Lift height & detached height-responsive contact shadow
        let liftLerp = 1.0 - exp(-18.0 * dt)
        curLiftY += (targetLiftY - curLiftY) * liftLerp
        visualRoot.position = SCNVector3(0, curLiftY, 0)

        let liftFrac = max(0, min(1, (curLiftY - 0.017) / 0.14))
        shadowNode.position = SCNVector3(0.008 + liftFrac * 0.032, 0.002, 0.014 + liftFrac * 0.052)
        shadowNode.scale = SCNVector3(1.0 + liftFrac * 0.14, 1.0 + liftFrac * 0.14, 1.0)
        shadowNode.opacity = CGFloat(0.36 - liftFrac * 0.16)

        // 3. Shortest-arc smooth 90° rotation + scale blend (tray <-> world scale)
        var angleDiff = targetYaw - curYaw
        while angleDiff > .pi { angleDiff -= .pi * 2 }
        while angleDiff < -.pi { angleDiff += .pi * 2 }
        curYaw += angleDiff * (1.0 - exp(-19.0 * dt))
        eulerAngles.y = curYaw

        curScale += (targetScale - curScale) * (1.0 - exp(-18.0 * dt))
        scale = SCNVector3(curScale, curScale, curScale)

        // 4. Damped harmonic squash spring (2 soft bounces, never rubbery!)
        let kSpring: Float = 210.0
        let damping: Float = 18.0
        let acc = -kSpring * squashVal - damping * squashVel
        squashVel += acc * dt
        squashVal += squashVel * dt
        if abs(squashVal) < 0.0005 && abs(squashVel) < 0.001 {
            squashVal = 0; squashVel = 0
        }

        // 5. Smooth invalid stripe & white sticker outline transitions (80-120ms)
        let uiFade = 1.0 - exp(-20.0 * dt)
        invalidMix += (targetInvalidMix - invalidMix) * uiFade
        outlineOpacity += (targetOutlineOpacity - outlineOpacity) * uiFade
        outlineNode.isHidden = outlineOpacity < 0.02
        outlineMaterial?.transparency = CGFloat(outlineOpacity)

        // Push uniforms cleanly to body + outline Metal shaders
        let sqNum = NSNumber(value: squashVal)
        let bxNum = NSNumber(value: bendX)
        let bzNum = NSNumber(value: bendZ)
        bodyMaterial?.setValue(sqNum, forKey: "u_squash")
        bodyMaterial?.setValue(bxNum, forKey: "u_bendX")
        bodyMaterial?.setValue(bzNum, forKey: "u_bendZ")
        bodyMaterial?.setValue(NSNumber(value: invalidMix), forKey: "u_invalidMix")
        outlineMaterial?.setValue(sqNum, forKey: "u_squash")
        outlineMaterial?.setValue(bxNum, forKey: "u_bendX")
        outlineMaterial?.setValue(bzNum, forKey: "u_bendZ")

        // 6. Idle pet happy timer decay
        if petHappyTimer > 0 {
            petHappyTimer -= Double(dt)
            if petHappyTimer <= 0 && targetInvalidMix < 0.1 {
                setExpression(isLocked ? .sleepy : .awake)
            }
        }

        // 7. Procedural blinking & subtle pupil gaze when awake!
        if expression == .awake {
            if isBlinking {
                blinkProgress += dt * 11.0
                if blinkProgress >= 1.0 {
                    isBlinking = false
                    blinkProgress = 0
                    leftEyelidNode.isHidden = true
                    rightEyelidNode.isHidden = true
                    nextBlinkTime = currentTime + Double.random(in: 3.0...7.2)
                }
            } else if currentTime >= nextBlinkTime {
                isBlinking = true
                leftEyelidNode.isHidden = false
                rightEyelidNode.isHidden = false
            }

            if currentTime >= nextGazeTime {
                nextGazeTime = currentTime + Double.random(in: 2.2...5.0)
                gazeTarget = CGPoint(x: CGFloat.random(in: -0.0045...0.0045), y: CGFloat.random(in: -0.0035...0.0035))
            }
            let gl = CGFloat(1.0 - exp(-8.0 * dt))
            gazeCurrent.x += (gazeTarget.x - gazeCurrent.x) * gl
            gazeCurrent.y += (gazeTarget.y - gazeCurrent.y) * gl
            leftPupilNode.position = SCNVector3(Float(gazeCurrent.x), 0, Float(gazeCurrent.y))
            rightPupilNode.position = SCNVector3(Float(gazeCurrent.x), 0, Float(gazeCurrent.y))
        }
    }

    // MARK: - Tiny Procedural Particle Sprites (Cached once!)

    private static var cachedShadow: UIImage?
    private static func makeSoftShadowImage() -> UIImage {
        if let img = cachedShadow { return img }
        let size = CGSize(width: 128, height: 128)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 16, dy: 16)
            ctx.cgContext.setShadow(offset: .zero, blur: 16, color: UIColor(hex: "#38221A", alpha: 0.92).cgColor)
            ctx.cgContext.setFillColor(UIColor(hex: "#38221A", alpha: 0.72).cgColor)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 34)
            ctx.cgContext.addPath(path.cgPath)
            ctx.cgContext.fillPath()
        }
        cachedShadow = img
        return img
    }

    private static var cachedZzz: UIImage?
    private static func makeZzzSpriteImage() -> UIImage {
        if let img = cachedZzz { return img }
        let size = CGSize(width: 64, height: 64)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { _ in
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 44, weight: .black),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor(hex: "#3A6EA8"),
                .strokeWidth: -4.0
            ]
            NSString(string: "Z").draw(at: CGPoint(x: 16, y: 6), withAttributes: attrs)
        }
        cachedZzz = img
        return img
    }

    private static var cachedHeart: UIImage?
    private static func makeHeartSpriteImage() -> UIImage {
        if let img = cachedHeart { return img }
        let size = CGSize(width: 64, height: 64)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 32, y: 54))
            path.addCurve(to: CGPoint(x: 8, y: 24), controlPoint1: CGPoint(x: 14, y: 42), controlPoint2: CGPoint(x: 8, y: 34))
            path.addArc(withCenter: CGPoint(x: 20, y: 22), radius: 12, startAngle: .pi, endAngle: 0, clockwise: true)
            path.addArc(withCenter: CGPoint(x: 44, y: 22), radius: 12, startAngle: .pi, endAngle: 0, clockwise: true)
            path.addCurve(to: CGPoint(x: 32, y: 54), controlPoint1: CGPoint(x: 56, y: 34), controlPoint2: CGPoint(x: 50, y: 42))
            UIColor.white.setFill()
            path.fill()
        }
        cachedHeart = img
        return img
    }
}
