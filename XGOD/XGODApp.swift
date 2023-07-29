import SwiftUI

@main
struct XGODApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 250, minHeight: 250)
        }
        .windowResizability(.contentSize)
    }
}
