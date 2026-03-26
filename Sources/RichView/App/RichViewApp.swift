import SwiftUI

@main
struct RichViewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("RichView", systemImage: "function") {
            MenuBarView(appState: appDelegate.appState)
        }
    }
}
