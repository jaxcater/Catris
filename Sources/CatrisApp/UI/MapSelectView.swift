import SwiftUI
import CatrisCore

struct MapSelectView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color(hex: "#F9F1E7").ignoresSafeArea()

            VStack(spacing: 0) {
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

                    Text(appState.vi ? "5 Không Gian Catris" : "5 Catris Worlds")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: "#3E3028"))

                    Spacer()

                    Color.clear.frame(width: 46, height: 46)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(appState.catalog.maps) { map in
                            mapCard(map)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
    }

    private func mapCard(_ map: MapTheme) -> some View {
        let levels = appState.catalog.levels(inMap: map.id)
        let solved = levels.filter { appState.save.completedLevelIds.contains($0.id) }.count
        let decor = appState.save.unlockedDecorCount(forMap: map.id, catalog: appState.catalog)

        return Button {
            AudioEngineManager.shared.playUITap()
            appState.screen = .levelSelect(mapId: map.id)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(map.id)
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.18), in: Capsule())

                        Text(map.localizedName(vietnamese: appState.vi))
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(solved)/\(levels.count)")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text(appState.vi ? "Trang trí \(decor)/3" : "Decor \(decor)/3")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }

                Text(map.localizedTagline(vietnamese: appState.vi))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.leading)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.28))
                        Capsule()
                            .fill(.white)
                            .frame(width: geo.size.width * CGFloat(solved) / CGFloat(max(1, levels.count)))
                    }
                }
                .frame(height: 8)
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color(hex: map.bgHex), Color(hex: map.accentHex)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .shadow(color: Color(hex: map.bgHex).opacity(0.32), radius: 10, y: 6)
        }
    }
}

struct LevelSelectView: View {
    @EnvironmentObject var appState: AppState
    let mapId: String

    private var map: MapTheme? { appState.catalog.map(forId: mapId) }
    private var levels: [BoardDefinition] { appState.catalog.levels(inMap: mapId) }

    var body: some View {
        ZStack {
            Color(hex: "#F9F1E7").ignoresSafeArea()

            VStack(spacing: 14) {
                HStack {
                    Button {
                        AudioEngineManager.shared.playUITap()
                        appState.screen = .mapSelect
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color(hex: "#463830"))
                            .frame(width: 46, height: 46)
                            .background(Color.white, in: Circle())
                            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text(map?.localizedName(vietnamese: appState.vi) ?? mapId)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(hex: "#3E3028"))
                        Text(appState.vi ? "Chọn bàn xếp mèo" : "Choose a Puzzle Board")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: "#8A7164"))
                    }

                    Spacer()
                    Color.clear.frame(width: 46, height: 46)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(levels) { board in
                            let done = appState.save.completedLevelIds.contains(board.id)
                            Button {
                                AudioEngineManager.shared.playUITap()
                                appState.startLevel(board.id, resumeSaved: true)
                            } label: {
                                VStack(spacing: 6) {
                                    HStack {
                                        Spacer()
                                        if done {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Color(hex: "#6DB86B"))
                                        }
                                    }
                                    .frame(height: 16)

                                    Text("\(board.id)")
                                        .font(.system(size: 26, weight: .black, design: .rounded))
                                        .foregroundStyle(done ? Color(hex: "#3E3028") : Color(hex: map?.accentHex ?? "#E87A9E"))

                                    Text("\(board.cols)×\(board.rows)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color(hex: "#8A7164"))

                                    Text(board.localizedTitle(vietnamese: appState.vi))
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Color(hex: "#5A483E"))
                                        .lineLimit(1)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(done ? Color(hex: "#EEF8EC") : Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(done ? Color(hex: "#8FD18B") : Color(hex: "#EFE2D5"), lineWidth: 2)
                                )
                                .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}
