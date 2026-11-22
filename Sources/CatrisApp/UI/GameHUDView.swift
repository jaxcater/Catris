import SwiftUI
import CatrisCore

struct GameplayContainerView: View {
    @EnvironmentObject var appState: AppState
    let levelId: Int

    private var board: BoardDefinition? {
        appState.catalog.levelById[levelId]
    }

    private var mapTheme: MapTheme? {
        guard let b = board else { return nil }
        return appState.catalog.map(forId: b.mapId)
    }

    var body: some View {
        ZStack {
            // Full-bleed native Metal 3D SceneKit viewport
            SceneKitViewport(
                controller: appState.sceneController,
                eco30Fps: appState.save.settings.eco30Fps
            )
            .ignoresSafeArea()

            // Safe-Area Portrait HUD Overlay (unobtrusive, reachable controls >= 48pt!)
            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // Subtle Tutorial Hint Pill (Levels 1-3) or Solver Hint Toast
                if let toast = appState.hintToast {
                    cozyBanner(text: toast, accent: Color(hex: "#F5B841"))
                        .padding(.top, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else if let tut = board?.localizedTutorialHint(vietnamese: appState.vi),
                          !appState.showSolvedBanner && !appState.isAdmiringSolvedBoard {
                    cozyBanner(text: tut, accent: Color(hex: "#E87A9E"))
                        .padding(.top, 8)
                }

                Spacer()

                if appState.isAdmiringSolvedBoard {
                    admiringBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                } else {
                    bottomControls
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                }
            }

            // Cozy Level Solved Overlay (allows "Ngắm mèo / Pet Cats" or "Next Level"!)
            if appState.showSolvedBanner {
                solvedOverlay
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: appState.showSolvedBanner)
        .animation(.easeInOut(duration: 0.25), value: appState.hintToast)
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                AudioEngineManager.shared.playUITap()
                appState.persistInProgressBoard()
                if let mapId = board?.mapId {
                    appState.screen = .levelSelect(mapId: mapId)
                } else {
                    appState.screen = .mapSelect
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "#463830"))
                    .frame(width: 46, height: 46)
                    .background(Color(hex: "#FFF8EE").opacity(0.92), in: Circle())
                    .shadow(color: .black.opacity(0.14), radius: 6, y: 3)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(mapTheme?.localizedName(vietnamese: appState.vi) ?? "Catris")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#8A6D5E"))
                Text(appState.vi ? "Màn \(levelId) · \(board?.titleVi ?? "")" : "Lv \(levelId) · \(board?.titleEn ?? "")")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: "#3E3028"))
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color(hex: "#FFF8EE").opacity(0.92), in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)

            Spacer()

            // Cat progress pill
            HStack(spacing: 4) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#E87A9E"))
                Text("\(appState.placedCount)/\(appState.totalCatsCount)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#3E3028"))
            }
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(Color(hex: "#FFF8EE").opacity(0.92), in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)

            Button {
                AudioEngineManager.shared.playUITap()
                appState.showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: "#463830"))
                    .frame(width: 46, height: 46)
                    .background(Color(hex: "#FFF8EE").opacity(0.92), in: Circle())
                    .shadow(color: .black.opacity(0.14), radius: 6, y: 3)
            }
        }
    }

    private var bottomControls: some View {
        let leftHanded = appState.save.settings.leftHandedControls
        return HStack(spacing: 10) {
            if leftHanded {
                rotateButton
                Spacer()
                actionButtonsGroup
            } else {
                actionButtonsGroup
                Spacer()
                rotateButton
            }
        }
    }

    private var actionButtonsGroup: some View {
        HStack(spacing: 10) {
            hudRoundButton(icon: "arrow.uturn.backward", label: appState.vi ? "Lùi" : "Undo", enabled: appState.canUndo) {
                appState.sceneController.performUndo()
            }
            hudRoundButton(icon: "lightbulb.fill", label: appState.vi ? "Gợi ý" : "Hint", enabled: true, tint: Color(hex: "#E5A032")) {
                appState.sceneController.triggerSmartHint()
            }
            hudRoundButton(icon: "arrow.counterclockwise", label: appState.vi ? "Lại" : "Reset", enabled: appState.placedCount > 0) {
                appState.sceneController.performReset()
            }
        }
    }

    private var rotateButton: some View {
        Button {
            appState.sceneController.rotateSelectedOrActivePiece()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "rotate.right.fill")
                    .font(.system(size: 18, weight: .bold))
                Text(appState.vi ? "Xoay 90°" : "Rotate")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 18)
            .frame(height: 52)
            .background(Color(hex: "#E87A9E"), in: Capsule())
            .overlay(Capsule().stroke(Color(hex: "#FFFDF7"), lineWidth: 2))
            .shadow(color: Color(hex: "#6B2A42").opacity(0.30), radius: 8, y: 4)
        }
    }

    private func hudRoundButton(icon: String, label: String, enabled: Bool, tint: Color = Color(hex: "#463830"), action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold))
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .foregroundStyle(enabled ? tint : tint.opacity(0.35))
            .frame(width: 56, height: 52)
            .background(Color(hex: "#FFF8EE").opacity(enabled ? 0.94 : 0.65), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 5, y: 3)
        }
        .disabled(!enabled)
    }

    private func cozyBanner(text: String, accent: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(accent).frame(width: 8, height: 8)
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "#44342C"))
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Color(hex: "#FFF9F0").opacity(0.94), in: Capsule())
        .shadow(color: .black.opacity(0.14), radius: 8, y: 3)
        .padding(.horizontal, 18)
    }

    private var admiringBar: some View {
        HStack(spacing: 12) {
            Text(appState.vi ? "Chạm vào mèo để vuốt ve nhé!" : "Tap any cat to pet & purr!")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#44342C"))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(hex: "#FFF8EE").opacity(0.92), in: Capsule())

            Spacer()

            Button {
                AudioEngineManager.shared.playUITap()
                appState.advanceToNextLevel()
            } label: {
                HStack(spacing: 6) {
                    Text(appState.vi ? "Màn Tiếp" : "Next")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(height: 50)
                .background(Color(hex: "#6DB86B"), in: Capsule())
                .shadow(color: .black.opacity(0.20), radius: 8, y: 4)
            }
        }
    }

    private var solvedOverlay: some View {
        ZStack {
            Color.black.opacity(0.26).ignoresSafeArea()

            VStack(spacing: 18) {
                Text("✨ 🐾 ✨")
                    .font(.system(size: 30))

                Text(appState.vi ? "Hoàn Thành Ấm Áp!" : "Purrfect Fit!")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "#40322B"))

                Text(appState.vi ? "Tất cả các bé mèo đã nằm gọn thật êm ái." : "Every kitty is tucked in snugly.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#6E5A4F"))
                    .multilineTextAlignment(.center)

                VStack(spacing: 10) {
                    Button {
                        AudioEngineManager.shared.playUITap()
                        appState.advanceToNextLevel()
                    } label: {
                        Text(levelId < 60
                             ? (appState.vi ? "Màn Tiếp Theo (\(levelId + 1))" : "Next Level (\(levelId + 1))")
                             : (appState.vi ? "Về Bản Đồ" : "All Maps"))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color(hex: "#E87A9E"), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    Button {
                        AudioEngineManager.shared.playUITap()
                        appState.showSolvedBanner = false
                        appState.isAdmiringSolvedBoard = true
                    } label: {
                        Text(appState.vi ? "Ngồi Ngắm & Vuốt Mèo" : "Stay & Pet Cats")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#5A473E"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Color(hex: "#F5EAE0"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
            .padding(26)
            .background(Color(hex: "#FFF9F2"), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Color(hex: "#F2D7C4"), lineWidth: 2))
            .shadow(color: .black.opacity(0.24), radius: 24, y: 12)
            .padding(.horizontal, 30)
        }
    }
}
