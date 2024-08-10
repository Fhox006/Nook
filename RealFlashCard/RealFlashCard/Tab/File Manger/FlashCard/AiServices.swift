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


struct LoadingAIView: View {
    @ObservedObject var deckStore: DeckStore
    let deck: Deck
    let inputText: String
    let rememberOption: RememberOption
    let questionType: QuestionType
    let aiModel: AIModel
    let onCompletion: () -> Void
    
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    private let openAIAPIKey = "mykey"
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(2)
                Text("Generating flashcards...")
                    .padding()
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                Button("Try Again") {
                    generateFlashcards()
                }
            } else {
                Text("Flashcards generated successfully!")
                Button("Done") {
                    onCompletion()
                }
            }
        }
        .onAppear {
            generateFlashcards()
        }
    }
    
    private func generateFlashcards() {
        isLoading = true
        errorMessage = nil
        
        let prompt = createPrompt()
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 1000
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Error during request: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let message = choices.first?["message"] as? [String: Any],
                      let content = message["content"] as? String else {
                    self.errorMessage = "Error parsing response"
                    self.isLoading = false
                    return
                }
                
                let newFlashcards = parseFlashcards(content)
                for flashcard in newFlashcards {
                    deckStore.addFlashcard(Flashcard(question: flashcard.question, answer: flashcard.answer, deckId: deck.id))
                }
                self.isLoading = false
            }
        }
        
        task.resume()
    }
    
    private func createPrompt() -> String {
        let rememberString: String
        switch rememberOption {
        case .all: rememberString = "all"
        case .mostImportant: rememberString = "the most important"
        case .few: rememberString = "a few"
        }
        
        let questionTypeString: String
        switch questionType {
        case .elaboratedShort: questionTypeString = "elaborated questions with short answers"
        case .shortShort: questionTypeString = "short questions with short answers"
        case .elaboratedElaborated: questionTypeString = "elaborated questions with elaborated answers"
        }
        
        return """
        Hello, your task is to create real flashcards based on the information sent. Use "+" to introduce the beginning of the flashcard and use "::" to separate the question from the answer. Here's an example:
        
        "
        + 🏛️ When was Napoleon born? :: 1769
        + ⚔️ When did Napoleon die? :: 1821
        "
        
        Output only the questions in this structure, no other messages are allowed (not even a hello or anything else.. otherwise the code doesn't work correctly).
        Note: Markdown usage is limited to *italic* and **bold**
        
        The user has specified these things:
        They want plain text (no markdown on latex) formatting, and you need to remember \(rememberString) information present in the sent text.
        Here's the sent text: \(inputText)
        """
    }
    
    private func parseFlashcards(_ content: String) -> [Flashcard] {
        let components = content.components(separatedBy: "+")
        return components.compactMap { component in
            let parts = component.components(separatedBy: "::")
            guard parts.count == 2 else { return nil }
            return Flashcard(question: parts[0].trimmingCharacters(in: .whitespacesAndNewlines),
                             answer: parts[1].trimmingCharacters(in: .whitespacesAndNewlines),
                             deckId: deck.id)
        }
    }
}

enum RememberOption: String, CaseIterable {
    case all = "All"
    case mostImportant = "Most Important"
    case few = "Few"
}

enum QuestionType: String, CaseIterable {
    case elaboratedShort = "Elaborated Question, Short Answer"
    case shortShort = "Short Question, Short Answer"
    case elaboratedElaborated = "Elaborated Question, Elaborated Answer"
}

enum AIModel: String, CaseIterable {
    case gpt4 = "GPT-4o-mini"
}

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
