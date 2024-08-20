import SwiftUI

struct WelcomeView: View {
    @AppStorage("userName") var userName: String = ""
    @AppStorage("appLanguage") var appLanguage: String = ""
    @State private var inputName: String = ""
    @State private var isDone: Bool = false
    @Binding var refreshView: Bool
    
    var body: some View {
        Group {
            if isDone {
                MainTabView()
            } else {
                WelcomeFormView(inputName: $inputName, isDone: $isDone)
            }
        }
        .onAppear {
            setAppLanguage()
            refreshView.toggle()
        }
    }
    
    private func setAppLanguage() {
        appLanguage = determineDeviceLanguage()
    }
}

struct WelcomeFormView: View {
    @Binding var inputName: String
    @Binding var isDone: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text(LocalizedStringKey("Welcome"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top, 50)
            
            TextField(LocalizedStringKey("Choose your Name"), text: $inputName)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 30)
            
            Button(action: {
                isDone = true
            }) {
                Text(LocalizedStringKey("Send"))
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(inputName.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .disabled(inputName.isEmpty)
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .navigationTitle("Welcome")
        .navigationBarTitleDisplayMode(.inline)
    }
}
