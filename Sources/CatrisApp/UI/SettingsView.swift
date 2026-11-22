import SwiftUI
import CatrisCore

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(appState.vi ? "Âm Thanh" : "Audio") {
                    Toggle(appState.vi ? "Tắt Toàn Bộ Âm" : "Mute All Audio", isOn: binding(\.isMuted))
                    sliderRow(title: appState.vi ? "Nhạc Nền" : "Music", value: binding(\.musicVolume))
                    sliderRow(title: appState.vi ? "Không Gian" : "Ambience", value: binding(\.ambienceVolume))
                    sliderRow(title: appState.vi ? "Tiếng Chạm / Vải" : "Foley", value: binding(\.foleyVolume))
                    sliderRow(title: appState.vi ? "Tiếng Mèo" : "Cats", value: binding(\.catsVolume))
                }

                Section(appState.vi ? "Cảm Giác & Điều Khiển" : "Feel & Controls") {
                    Toggle(appState.vi ? "Rung Xúc Giác (Haptics)" : "Tactile Haptics", isOn: binding(\.hapticsEnabled))
                    Toggle(appState.vi ? "Bố Cục Tay Trái" : "Left-Handed Controls", isOn: binding(\.leftHandedControls))
                    Toggle(appState.vi ? "Tiết Kiệm Pin (30 FPS)" : "Battery Saver (30 FPS)", isOn: binding(\.eco30Fps))
                    Toggle(appState.vi ? "Giảm Chuyển Động" : "Reduce Motion", isOn: binding(\.reduceMotion))
                }

                Section(appState.vi ? "Ngôn Ngữ" : "Language") {
                    Toggle(appState.vi ? "Tiếng Việt" : "Vietnamese (Tiếng Việt)", isOn: binding(\.useVietnamese))
                }

                Section(appState.vi ? "Thông Tin" : "About Catris") {
                    HStack {
                        Text(appState.vi ? "Tiến độ" : "Progress")
                        Spacer()
                        Text("\(appState.save.completedLevelIds.count) / 60")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(appState.vi ? "Lượt vuốt ve mèo" : "Total Cat Pets")
                        Spacer()
                        Text("\(appState.save.totalPetsGiven) 🐾")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(appState.vi ? "Cài Đặt" : "Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(appState.vi ? "Xong" : "Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }

    private func binding<T>(_ keyPath: WritableKeyPath<GameSettings, T>) -> Binding<T> {
        Binding(
            get: { appState.save.settings[keyPath: keyPath] },
            set: { newVal in
                appState.updateSettings { $0[keyPath: keyPath] = newVal }
            }
        )
    }

    private func sliderRow(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: 0...1)
                .tint(Color(hex: "#E87A9E"))
        }
    }
}
