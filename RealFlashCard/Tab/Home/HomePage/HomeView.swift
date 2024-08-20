import SwiftUI

struct HomeView: View {
    @AppStorage("userName") var userName: String = ""
    @EnvironmentObject var folderStore: FolderStore
    @EnvironmentObject var deckStore: DeckStore
    @EnvironmentObject var streakManager: StreakManager
    
    var body: some View {
        VStack {
            List {
                welcomeSection
                playSection
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
        .toolbar {
            settingsToolbarItem
        }
        .onAppear {
            deckStore.updatePlayedFlashcards()
            streakManager.updateStreak(
                playedCards: deckStore.playedFlashcardsToday,
                availableCards: deckStore.availableFlashcardsToday
            )
        }
    }
    
    private var welcomeSection: some View {
        Section(header: Text("Benvenuto")) {
            Text("Welcome, \(userName)!")
                .font(.headline)
            StreakStatusView(streak: streakManager.currentStreak)
        }
    }
    
    private var playSection: some View {
        Section {
            NavigationLink(destination: SettingsPlayView()
                .environmentObject(folderStore)
                .environmentObject(deckStore)) {
                HStack {
                    Image(systemName: "gamecontroller")
                    Text("Play")
                        .font(.headline)
                }
            }
        }
    }
    
    private var settingsToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape")
            }
        }
    }
}
