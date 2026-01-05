import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var dataService: DataService
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Accueil", systemImage: "house.fill", value: .home) {
                HomeView(dataService: dataService)
            }

            Tab("Programme", systemImage: "calendar", value: .program) {
                ProgramView(dataService: dataService, onStartSession: nil)
            }

            Tab("Historique", systemImage: "clock.arrow.circlepath", value: .history) {
                HistoryView(dataService: dataService)
            }

            Tab("Stats", systemImage: "chart.line.uptrend.xyaxis", value: .stats) {
                StatsView(dataService: dataService)
            }
        }
        .tint(Color.appPrimary)
    }
}

enum AppTab: Hashable {
    case home
    case program
    case history
    case stats
}

#Preview {
    ContentView()
        .environmentObject(DataService())
}
