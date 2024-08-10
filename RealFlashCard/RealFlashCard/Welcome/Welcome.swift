import SwiftUI

struct WelcomeView: View {
    @AppStorage("userName") var userName: String = ""
    @AppStorage("appLanguage") var appLanguage: String = ""
    @State private var inputName: String = ""
    @State private var isDone: Bool = false
    
    var body: some View {
        Group {
            if isDone {
                MainTabView()
            } else {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Text(LocalizedStringKey("Welcome"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.top, 50)
                    
                    TextField(LocalizedStringKey("Choose your Name"), text: $inputName)
                        .padding()
                        .background(Color(.systemGray6)) // Sfondo chiaro per il TextField
                        .cornerRadius(10) // Angoli arrotondati per il TextField
                        .padding(.horizontal, 30)
                    
                    Button(action: {
                        userName = inputName
                        isDone = true
                    }) {
                        Text(LocalizedStringKey("Send"))
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(inputName.isEmpty ? Color.gray : Color.blue) // Colore di sfondo condizionale
                            .foregroundColor(.white) // Colore del testo
                            .clipShape(Capsule()) // Forma arrotondata moderna
                    }
                    .disabled(inputName.isEmpty) // Disabilita il pulsante se il campo è vuoto
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
                .navigationTitle("Welcome")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear(perform: setAppLanguage)
            }
        }
    }
    
    // MARK: - To Do (Implementare tutte le lingue)
    func setAppLanguage() {
        let supportedLanguages = ["it", "fr", "es", "de"]
        var deviceLanguage = "en"
        if let deviceLanguageIdentifier = Locale.current.language.languageCode?.identifier,
           supportedLanguages.contains(deviceLanguageIdentifier) {
            deviceLanguage = deviceLanguageIdentifier
        }
        appLanguage = deviceLanguage
    }
}
