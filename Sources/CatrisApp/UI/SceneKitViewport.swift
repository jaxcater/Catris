import SwiftUI
import SceneKit

/// Custom SCNView subclass capturing exact single-finger portrait touches with zero gesture-recognizer delay!
final class InteractiveCatrisSCNView: SCNView {
    weak var controller: CatrisSceneController?
    private var trackedTouch: UITouch?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard trackedTouch == nil, let t = touches.first else { return }
        trackedTouch = t
        controller?.handleTouchBegan(at: t.location(in: self), in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = trackedTouch, touches.contains(t) else { return }
        controller?.handleTouchMoved(to: t.location(in: self), in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = trackedTouch, touches.contains(t) else { return }
        trackedTouch = nil
        controller?.handleTouchEnded(at: t.location(in: self), in: self)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = trackedTouch, touches.contains(t) else { return }
        trackedTouch = nil
        controller?.handleTouchCancelled()
    }
}

struct SceneKitViewport: UIViewRepresentable {
    let controller: CatrisSceneController
    let eco30Fps: Bool

    func makeUIView(context: Context) -> InteractiveCatrisSCNView {
        let view = InteractiveCatrisSCNView(frame: .zero)
        view.scene = controller.scene
        view.delegate = controller
        view.controller = controller
        view.isPlaying = true
        view.loops = true
        view.antialiasingMode = .multisampling2X
        view.preferredFramesPerSecond = eco30Fps ? 30 : 60
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        view.backgroundColor = UIColor(hex: "#DF9C56")
        view.isMultipleTouchEnabled = false
        return view
    }

    func updateUIView(_ uiView: InteractiveCatrisSCNView, context: Context) {
        uiView.preferredFramesPerSecond = eco30Fps ? 30 : 60
    }
}
