import SwiftUI

class SharedSettings: ObservableObject {
    @Published var inputText = ""
    @Published var rememberOption = RememberOption.all
    @Published var questionType = QuestionType.shortShort
    @Published var aiModel = AIModel.gpt4
}

struct FlashcardView: View {
    @EnvironmentObject var deckStore: DeckStore
    @Binding var flashcard: Flashcard
    
    var body: some View {
        Form {
            Section(header: Text("Question").textCase(.uppercase)) {
                TextEditor(text: $flashcard.question)
                    .frame(height: 100)
            }
            
            Section(header: Text("Answer").textCase(.uppercase)) {
                TextEditor(text: $flashcard.answer)
                    .frame(height: 100)
            }
        }
        .navigationTitle("Edit Flashcard")
        .onDisappear {
            deckStore.updateFlashcard(flashcard)
        }
    }
}
