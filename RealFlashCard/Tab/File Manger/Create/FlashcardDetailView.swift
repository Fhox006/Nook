import SwiftUI

struct FlashcardDetailView: View {
    @EnvironmentObject var deckStore: DeckStore
    @State private var flashcard: Flashcard
    
    init(flashcard: Flashcard) {
        _flashcard = State(initialValue: flashcard)
    }
    
    var body: some View {
        Form {
            TextField("Question", text: $flashcard.question)
            TextField("Answer", text: $flashcard.answer)
        }
        .navigationTitle("Edit Flashcard")
        .navigationBarItems(trailing: Button("Save") {
            deckStore.updateFlashcard(flashcard)
        })
    }
}
