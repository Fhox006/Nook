import SwiftUI

struct CongratulationsView: View {
    var body: some View {
        VStack {
            Text("Congratulations!")
                .font(.largeTitle)
                .padding()
            
            Text("You've completed all flashcards.")
                .font(.headline)
                .padding()
        }
    }
}
