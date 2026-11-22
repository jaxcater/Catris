import SwiftUI
import SceneKit
import CatrisCore

/// Interactive 3D Cat Album showcasing all 12 sculpted organic Catris cats!
/// Players can inspect, rotate, and pet any unlocked 3D cat.
struct CatAlbumView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCat: CatDefinition?

    var body: some View {
        ZStack {
            Color(hex: "#F9F1E7").ignoresSafeArea()

            VStack(spacing: 14) {
                HStack {
                    Button {
                        AudioEngineManager.shared.playUITap()
                        appState.screen = .home
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color(hex: "#463830"))
                            .frame(width: 46, height: 46)
                            .background(Color.white, in: Circle())
                            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                    }
                    Spacer()
                    Text(appState.vi ? "Bộ Sưu Tập Mèo (12)" : "Cat Album (12)")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: "#3E3028"))
                    Spacer()
                    Color.clear.frame(width: 46, height: 46)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Interactive 3D Turntable Showcase for the selected cat!
                let activeCat = selectedCat ?? appState.catalog.cats.first
                if let cat = activeCat {
                    VStack(spacing: 8) {
                        CatTurntable3DView(cat: cat)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white, lineWidth: 3))
                            .shadow(color: .black.opacity(0.10), radius: 10, y: 5)
                            .onTapGesture {
                                AudioEngineManager.shared.playCatMeow(catId: cat.id, pitchMultiplier: cat.pitch, force: true)
                                HapticManager.shared.playPurrOrSolve()
                            }

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(cat.localizedName(vietnamese: appState.vi)) · \(cat.code)")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundStyle(Color(hex: "#3E3028"))
                                Text(cat.localizedSubtitle(vietnamese: appState.vi))
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color(hex: "#7D685C"))
                            }
                            Spacer()
                            Text(appState.vi ? "\(cat.cells.count) ô" : "\(cat.cells.count) cells")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(hex: "#E87A9E"), in: Capsule())
                        }
                    }
                    .padding(.horizontal, 20)
                }

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(appState.catalog.cats) { cat in
                            let unlocked = appState.save.unlockedCatIds.contains(cat.id)
                            let isSelected = (selectedCat?.id ?? appState.catalog.cats.first?.id) == cat.id
                            Button {
                                AudioEngineManager.shared.playUITap()
                                selectedCat = cat
                                if unlocked {
                                    AudioEngineManager.shared.playCatMeow(catId: cat.id, pitchMultiplier: cat.pitch, force: true)
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(Color(hex: cat.baseHex))
                                        .frame(width: 44, height: 44)
                                        .overlay(Circle().stroke(Color(hex: cat.accentHex), lineWidth: 4))
                                        .opacity(unlocked ? 1.0 : 0.35)

                                    Text(cat.localizedName(vietnamese: appState.vi))
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color(hex: "#3E3028"))

                                    Text(unlocked ? "\(cat.cells.count) 🐾" : "🔒 \(cat.unlockMap)")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Color(hex: "#8A7164"))
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(isSelected ? Color(hex: "#FCE7EE") : Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(isSelected ? Color(hex: "#E87A9E") : Color(hex: "#EFE2D5"), lineWidth: 2))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
        }
    }
}

private struct CatTurntable3DView: UIViewRepresentable {
    let cat: CatDefinition

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = UIColor(hex: "#F4D5DF")
        view.antialiasingMode = .multisampling2X
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.scene = buildScene(for: cat)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.scene = buildScene(for: cat)
    }

    private func buildScene(for cat: CatDefinition) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor(hex: "#F6DCE5")
        let camNode = SCNNode()
        camNode.camera = SCNCamera()
        camNode.position = SCNVector3(0, 0.72, 0.78)
        camNode.look(at: SCNVector3(0, 0.05, 0))
        scene.rootNode.addChildNode(camNode)

        let catNode = Cat3DNode(pieceIndex: 0, catDef: cat, isLocked: false)
        catNode.snapImmediately(worldPos: SCNVector3Zero, liftY: 0, yaw: 0, scale: 1.0)
        catNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 9.0)))
        scene.rootNode.addChildNode(catNode)
        return scene
    }
}
