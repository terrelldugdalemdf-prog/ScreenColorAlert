import SwiftUI

@main
struct ScreenColorAlertApp: App {
    @StateObject private var viewModel = ColorMonitorViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        .windowResizability(.contentSize)
        .windowStyle(.titleBar)
    }
}
