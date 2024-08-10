import SwiftUI

struct HomeView: View {
    @AppStorage("userName") var userName: String = ""
    @StateObject private var folderStore = FolderStore()
    @StateObject private var deckStore = DeckStore()
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.title)
                            .padding(.leading)
                    }
                    Spacer()
                }
                
                Spacer()
                
                Text("Welcome, \(userName)!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                NavigationLink(destination: SettingsPlayView()
                    .environmentObject(folderStore)
                    .environmentObject(deckStore)) {
                        Text("Play")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                }

                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}
