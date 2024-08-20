import SwiftUI

struct TestView: View {
    @State private var title: String = "Titolo iniziale"

    var body: some View {
        NavigationView {
            VStack {
                TextField("Modifica il titolo", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Spacer()
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Modifica") {
                        // Azione per modificare il titolo
                    }
                }
            }
        }
    }
}
