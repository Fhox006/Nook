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
            contentView
        }
    }
    
    private var contentView: some View {
        if isLoading {
            return AnyView(LoadingView(isLoading: $isLoading))
        } else if userName == nil {
            return AnyView(WelcomeView(refreshView: $refreshView))
        } else {
            return AnyView(MainTabView()
                            .environmentObject(folderStore)
                            .environmentObject(deckStore)
                            .environmentObject(statsManager)
                            .environmentObject(streakManager))
        }
    }
}







// aslto4 --> numero rinnovo patente e visita.
// sito motorizzazione torino.
// Cerco la sezione sportello appuntamenti per fare la patente e prenoto una data DOPO la visita medica.

