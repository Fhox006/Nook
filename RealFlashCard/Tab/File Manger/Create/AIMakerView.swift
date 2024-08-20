import SwiftUI

struct AIMakerView: View {
    @EnvironmentObject var deckStore: DeckStore
    let deck: Deck
    @State private var inputText = ""
    @State private var rememberOption = RememberOption.all
    @State private var questionType = QuestionType.shortShort
    @State private var aiModel = AIModel.gpt4
    @State private var showingLoadingView = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("Input").textCase(.uppercase)) {
                TextEditor(text: $inputText)
                    .frame(height: 150)
                
                Text("\(inputText.count)/1000")
                    .font(.caption)
                    .foregroundColor(inputText.count == 1000 ? .red : .secondary)
            }
            
            Section(header: Text("Preferences").textCase(.uppercase)) {
                Picker("Remember", selection: $rememberOption) {
                    ForEach(RememberOption.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                
                Picker("Question Type", selection: $questionType) {
                    ForEach(QuestionType.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
            }
            
            Section(header: Text("Advanced").textCase(.uppercase)) {
                Picker("AI Model", selection: $aiModel) {
                    ForEach(AIModel.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
            }
            
            Section {
                Button(action: generateFlashcards) {
                    Text("Generate Flashcards")
                }
                .disabled(inputText.isEmpty)
            }
        }
        .navigationTitle("AI Flashcard Maker")
        .sheet(isPresented: $showingLoadingView) {
            LoadingAIView(deckStore: deckStore, deck: deck, inputText: inputText, rememberOption: rememberOption, questionType: questionType, aiModel: aiModel) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func generateFlashcards() {
        showingLoadingView = true
    }
}
