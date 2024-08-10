import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var folderStore: FolderStore
    @EnvironmentObject var deckStore: DeckStore
    @EnvironmentObject var statsManager: StatsManager
    
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            
            NavigationStack {
                FileView()
            }
            .tabItem {
                Label("Files", systemImage: "folder")
            }
            
            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
        }
    }
}
