import SwiftUI

struct HomeView: View {
    @AppStorage("userName") var userName: String = ""
    @EnvironmentObject var folderStore: FolderStore
    @EnvironmentObject var deckStore: DeckStore
    @EnvironmentObject var streakManager: StreakManager
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Benvenuto")) {
                    Text("Welcome, \(userName)!")
                        .font(.headline)
                    StreakView(streak: streakManager.currentStreak)
                }
                
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
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                }
            }
        }
        .onAppear {
            deckStore.updatePlayedFlashcards()
            streakManager.updateStreak(playedCards: deckStore.playedFlashcardsToday, availableCards: deckStore.availableFlashcardsToday)
        }
    }
}

struct StreakView: View {
    let streak: Int
    
    var body: some View {
        HStack {
            Text("Current Streak: \(streak)")
                .font(.subheadline)
            
            Spacer()
            
            HStack {
                ForEach(0..<7) { index in
                    Circle()
                        .frame(width: 20, height: 20)
                        .foregroundColor(index < streak % 7 ? .blue : .gray)
                }
            }
        }
    }
}
