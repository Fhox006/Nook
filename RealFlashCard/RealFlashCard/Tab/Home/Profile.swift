import SwiftUI //codice non fatto da me in giù
import AuthenticationServices

struct ProfileView: View {
  
    @AppStorage("userName") var userName: String = ""
    @AppStorage("loginCount") var loginCount: Int = 0

    var body: some View {
        VStack {
            SignInWithAppleButton(.signIn, onRequest: { request in
      
            }, onCompletion: { result in
       
                switch result {
                case .success(let authResults):
               
                    loginCount += 1
               
                    if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential,
                       let fullName = appleIDCredential.fullName,
                       let name = fullName.givenName {
                        userName = name
                    }
                case .failure(let error):
                 
                    print("Autenticazione fallita: \(error)")
                }
            })
            .frame(width: 280, height: 60)
            .padding()
         
            Text("Ciao, \(userName)! Hai effettuato l'accesso \(loginCount) volte.")
        }
    }
}
