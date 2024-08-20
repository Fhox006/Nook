import SwiftUI

struct FlashcardView: View {
    @EnvironmentObject private var deckStore: DeckStore
    @Binding var flashcard: Flashcard
    
    var body: some View {
        Form {
            flashcardSection(title: "Question", text: $flashcard.question)
            flashcardSection(title: "Answer", text: $flashcard.answer)
        }
        .navigationTitle("Edit Flashcard")
        .onDisappear(perform: saveFlashcard)
    }
    
    private func flashcardSection(title: String, text: Binding<String>) -> some View {
        Section(header: Text(title).textCase(.uppercase)) {
            TextEditor(text: text)
                .frame(height: 100)
                .padding(.vertical, 8)
        }
    }
    
    private func saveFlashcard() {
        deckStore.updateFlashcard(flashcard)
    }
}

class SharedSettings: ObservableObject {
    @Published var inputText = ""
    @Published var rememberOption = RememberOption.all
    @Published var questionType = QuestionType.shortShort
    @Published var aiModel = AIModel.gpt4
}
