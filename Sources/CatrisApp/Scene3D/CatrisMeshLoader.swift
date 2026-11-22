import Foundation
import SceneKit
import UIKit

enum AssetBundle {
    static func url(name: String, ext: String, folder: String) -> URL? {
        if let u = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: folder) {
            return u
        }
        return Bundle.main.url(forResource: name, withExtension: ext)
    }

    static func image(named name: String, folder: String = "Textures") -> UIImage? {
        guard let url = url(name: name, ext: "png", folder: folder) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >> 8) & 0xFF) / 255.0
        let b = CGFloat(value & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

struct CatAnchorData: Codable {
    let id: String
    let headPos: [Float]
    let leftEyePos: [Float]
    let rightEyePos: [Float]
    let eyeNormal: [Float]
    let nosePos: [Float]
    let leftWhiskerPos: [Float]
    let rightWhiskerPos: [Float]
    let zzzPos: [Float]
    let faceYawDeg: Float
    let eyeSpacing: Float
    let eyeRadius: Float
    let eyeStyle: String
    let eyeColorHex: String
    let hasFangs: Bool
    let hasBlep: Bool
    let hasFishPlushie: Bool
    let fishPos: [Float]?
    let hasEarBow: Bool
    let bowPos: [Float]?
    let boundsMin: [Float]
    let boundsMax: [Float]

    enum CodingKeys: String, CodingKey {
        case id
        case headPos = "head_pos"
        case leftEyePos = "left_eye_pos"
        case rightEyePos = "right_eye_pos"
        case eyeNormal = "eye_normal"
        case nosePos = "nose_pos"
        case leftWhiskerPos = "left_whisker_pos"
        case rightWhiskerPos = "right_whisker_pos"
        case zzzPos = "zzz_pos"
        case faceYawDeg = "face_yaw_deg"
        case eyeSpacing = "eye_spacing"
        case eyeRadius = "eye_radius"
        case eyeStyle = "eye_style"
        case eyeColorHex = "eye_color_hex"
        case hasFangs = "has_fangs"
        case hasBlep = "has_blep"
        case hasFishPlushie = "has_fish_plushie"
        case fishPos = "fish_pos"
        case hasEarBow = "has_ear_bow"
        case bowPos = "bow_pos"
        case boundsMin = "bounds_min"
        case boundsMax = "bounds_max"
    }

    static func vec(_ arr: [Float]) -> SCNVector3 {
        guard arr.count >= 3 else { return SCNVector3Zero }
        return SCNVector3(arr[0], arr[1], arr[2])
    }
}

/// Fast binary CMESH01 loader with geometry caching.
/// Loads vertex positions, analytical smooth normals, UVs, and RGBA soft-rig weights directly into Metal buffers.
final class CatrisMeshCache {
    static let shared = CatrisMeshCache()
    private var geometryCache: [String: SCNGeometry] = [:]
    private var anchorsById: [String: CatAnchorData] = [:]

    private init() {
        loadAnchors()
    }

    private func loadAnchors() {
        guard let url = AssetBundle.url(name: "cat_anchors", ext: "json", folder: "Data"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([CatAnchorData].self, from: data) else {
            return
        }
        anchorsById = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
    }

    func anchor(forCatId id: String) -> CatAnchorData? {
        anchorsById[id]
    }

    func geometry(named name: String) -> SCNGeometry? {
        if let cached = geometryCache[name] {
            return cached.copy() as? SCNGeometry
        }
        guard let url = AssetBundle.url(name: name, ext: "cmesh", folder: "Meshes"),
              let data = try? Data(contentsOf: url),
              let geo = parseCMesh(data: data) else {
            return nil
        }
        geometryCache[name] = geo
        return geo.copy() as? SCNGeometry
    }

    private func parseCMesh(data: Data) -> SCNGeometry? {
        guard data.count >= 16 else { return nil }
        let magic = String(data: data.prefix(7), encoding: .ascii)
        guard magic == "CMESH01" else { return nil }

        let vertCount: UInt32 = data.withUnsafeBytes { ptr in
            ptr.loadUnaligned(fromByteOffset: 8, as: UInt32.self)
        }
        let indexCount: UInt32 = data.withUnsafeBytes { ptr in
            ptr.loadUnaligned(fromByteOffset: 12, as: UInt32.self)
        }

        let stride = 48 // 12 floats: pos(3) + norm(3) + uv(2) + color(4)
        let vertByteLen = Int(vertCount) * stride
        let idxByteLen = Int(indexCount) * 4
        guard data.count >= 16 + vertByteLen + idxByteLen, vertCount > 0, indexCount >= 3 else {
            return nil
        }

        let vertData = data.subdata(in: 16..<(16 + vertByteLen))
        let idxData = data.subdata(in: (16 + vertByteLen)..<(16 + vertByteLen + idxByteLen))

        let posSource = SCNGeometrySource(
            data: vertData,
            semantic: .vertex,
            vectorCount: Int(vertCount),
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: 4,
            dataOffset: 0,
            dataStride: stride
        )
        let normSource = SCNGeometrySource(
            data: vertData,
            semantic: .normal,
            vectorCount: Int(vertCount),
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: 4,
            dataOffset: 12,
            dataStride: stride
        )
        let uvSource = SCNGeometrySource(
            data: vertData,
            semantic: .texcoord,
            vectorCount: Int(vertCount),
            usesFloatComponents: true,
            componentsPerVector: 2,
            bytesPerComponent: 4,
            dataOffset: 24,
            dataStride: stride
        )
        let colSource = SCNGeometrySource(
            data: vertData,
            semantic: .color,
            vectorCount: Int(vertCount),
            usesFloatComponents: true,
            componentsPerVector: 4,
            bytesPerComponent: 4,
            dataOffset: 32,
            dataStride: stride
        )

        let element = SCNGeometryElement(
            data: idxData,
            primitiveType: .triangles,
            primitiveCount: Int(indexCount) / 3,
            bytesPerIndex: 4
        )

        return SCNGeometry(sources: [posSource, normSource, uvSource, colSource], elements: [element])
    }
}
