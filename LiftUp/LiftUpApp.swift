import SwiftUI
import SwiftData

@main
struct LiftUpApp: App {
    @StateObject private var dataService = DataService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataService)
                .modelContainer(dataService.modelContainer)
                .preferredColorScheme(.light)
                .task {
                    await dataService.initializeIfNeeded()
                }
        }
    }
}
