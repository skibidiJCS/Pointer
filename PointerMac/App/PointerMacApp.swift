import SwiftUI

@main
struct PointerMacApp: App {
    @StateObject private var model = MacAppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            DashboardView(model: model)
                .frame(minWidth: 760, minHeight: 600)
                .onAppear {
                    model.start()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        model.refreshPermission()
                    }
                }
        }
        .defaultSize(width: 820, height: 680)
        .windowResizability(.contentMinSize)
    }
}
