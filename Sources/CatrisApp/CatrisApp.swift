import SwiftUI
import UIKit

final class CatrisAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        .portrait // Strict portrait-only iPhone lock!
    }
}

@main
struct CatrisApp: App {
    @UIApplicationDelegateAdaptor(CatrisAppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
                .onChange(of: scenePhase) { _, newPhase in
                    appState.handleScenePhase(newPhase)
                }
        }
    }
}
