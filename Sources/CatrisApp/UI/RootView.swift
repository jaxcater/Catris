import SwiftUI
import CatrisCore

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            switch appState.screen {
            case .home:
                HomeTitleView()
            case .mapSelect:
                MapSelectView()
            case .levelSelect(let mapId):
                LevelSelectView(mapId: mapId)
            case .playing(let levelId):
                GameplayContainerView(levelId: levelId)
            case .catAlbum:
                CatAlbumView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.screen)
        .sheet(isPresented: $appState.showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

// MARK: - Cozy Portrait Home Title Screen

private struct HomeTitleView: View {
    @EnvironmentObject var appState: AppState
    @State private var floatUp = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#F5C27A"), Color(hex: "#DF9C56"), Color(hex: "#CC8242")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Soft diagonal sunlight band decoration
            Rectangle()
                .fill(Color(hex: "#FFF4D2").opacity(0.24))
                .frame(width: 240, height: 950)
                .rotationEffect(.degrees(22))
                .offset(x: 90, y: -60)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button {
                        AudioEngineManager.shared.playUITap()
                        appState.showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color(hex: "#4A3A33"))
                            .frame(width: 48, height: 48)
                            .background(Color(hex: "#FFF8EE").opacity(0.90), in: Circle())
                            .shadow(color: Color(hex: "#5A3824").opacity(0.18), radius: 8, y: 4)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // Cozy Title Card & AppIcon Preview
                VStack(spacing: 14) {
                    if let iconImg = AssetBundle.image(named: "AppIcon") {
                        Image(uiImage: iconImg)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 132, height: 132)
                            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 32, style: .continuous)
                                    .stroke(Color(hex: "#FFFDF7"), lineWidth: 5)
                            )
                            .shadow(color: Color(hex: "#5A3622").opacity(0.28), radius: 16, y: 10)
                            .offset(y: floatUp ? -6 : 6)
                            .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: floatUp)
                    }

                    Text("CATRIS")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(Color(hex: "#FFFDF7"))
                        .shadow(color: Color(hex: "#6B3828").opacity(0.32), radius: 0, x: 0, y: 4)

                    Text(appState.vi ? "Xếp mèo 3D ấm áp · 5 không gian · 60 màn chơi" : "Cozy 3D Cat Packing · 5 Worlds · 60 Levels")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "#4A342B"))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#FFF6EA").opacity(0.84), in: Capsule())
                }

                Spacer()

                // Primary Portrait Action Buttons (All >= 52pt comfortable thumb targets!)
                VStack(spacing: 14) {
                    Button {
                        AudioEngineManager.shared.playUITap()
                        HapticManager.shared.playPickup()
                        appState.continueJourney()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                            Text(appState.save.completedLevelIds.isEmpty
                                 ? (appState.vi ? "Bắt Đầu Chơi" : "Start Playing")
                                 : (appState.vi ? "Chơi Tiếp · Màn \(appState.save.currentLevelId)" : "Continue · Level \(appState.save.currentLevelId)"))
                        }
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color(hex: "#E87A9E"), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color(hex: "#FFFDF7").opacity(0.85), lineWidth: 2.5)
                        )
                        .shadow(color: Color(hex: "#7A2D48").opacity(0.32), radius: 12, y: 6)
                    }

                    HStack(spacing: 12) {
                        Button {
                            AudioEngineManager.shared.playUITap()
                            appState.screen = .mapSelect
                        } label: {
                            Label(appState.vi ? "5 Bản Đồ" : "5 Maps", systemImage: "map.fill")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "#4A3A33"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color(hex: "#FFF8EE").opacity(0.94), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .shadow(color: Color(hex: "#5A3824").opacity(0.14), radius: 8, y: 4)
                        }

                        Button {
                            AudioEngineManager.shared.playUITap()
                            appState.screen = .catAlbum
                        } label: {
                            Label(appState.vi ? "Mèo (\(appState.save.unlockedCatIds.count)/12)" : "Cats (\(appState.save.unlockedCatIds.count)/12)", systemImage: "pawprint.fill")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "#4A3A33"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color(hex: "#FFF8EE").opacity(0.94), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .shadow(color: Color(hex: "#5A3824").opacity(0.14), radius: 8, y: 4)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 26)
            }
            .padding(.top, 12)
        }
        .onAppear {
            floatUp = true
            AudioEngineManager.shared.setMapAudio(mapId: "M01")
        }
    }
}

extension Color {
    init(hex: String) {
        self.init(UIColor(hex: hex))
    }
}
