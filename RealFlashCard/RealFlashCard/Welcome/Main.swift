import SwiftUI

@main
struct Nook: App {
    @StateObject private var folderStore = FolderStore()
    @StateObject private var deckStore = DeckStore()
    @StateObject private var statsManager = StatsManager()
    @StateObject private var streakManager = StreakManager()
    @State private var isLoading = true
    @State private var userName: String? = UserDefaults.standard.string(forKey: "userName")
    @State private var refreshView = false
    
    var body: some Scene {
        WindowGroup {
            if isLoading {
                LoadingView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isLoading = false
                        }
                    }
            } else {
                if userName == nil {
                    WelcomeView()
                        .id(refreshView)
                        .onAppear {
                            refreshView.toggle()
                        }
                } else {
                    MainTabView()
                        .environmentObject(folderStore)
                        .environmentObject(deckStore)
                        .environmentObject(statsManager)
                        .environmentObject(streakManager)
                }
            }
        }
    }
}
