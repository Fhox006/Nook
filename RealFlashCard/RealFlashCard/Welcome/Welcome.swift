import SwiftUI

struct WelcomeView: View {
    @AppStorage("userName") var userName: String = ""
    @AppStorage("appLanguage") var appLanguage: String = ""
    @State private var inputName: String = ""
    @State private var isDone: Bool = false
    
    var body: some View {
        if isDone == false {
            VStack {
                Text(LocalizedStringKey("Welcome"))
                    .font(.largeTitle)
                TextField(LocalizedStringKey("Choose your Name"), text: $inputName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    userName = inputName
                    isDone = true
                }) {
                    Text(LocalizedStringKey("Send"))
                }
                .disabled(inputName.isEmpty)
            }
            .onAppear(perform: setAppLanguage) 
        } else {
            MainTabView()
        }
    }
    
//MARK: - To Do (Implementare tutte le lingue)
    func setAppLanguage() {
        let supportedLanguages = ["it", "fr", "es", "de"]
        var deviceLanguage = "en"
        if let deviceLanguageIdentifier = Locale.current.language.languageCode?.identifier ,
           supportedLanguages.contains(deviceLanguageIdentifier) {
                   deviceLanguage = deviceLanguageIdentifier
        }
        appLanguage = deviceLanguage
    }
}
