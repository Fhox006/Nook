import SwiftUI

// Struttura per rappresentare un mazzo
struct Deck: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var color: DeckColor
    
    init(id: UUID = UUID(), name: String, color: DeckColor) {
        self.id = id
        self.name = name
        self.color = color
    }
}

// Enumerazione per i colori dei mazzi
enum DeckColor: String, CaseIterable, Codable {
    case red, green, blue, purple

    var color: Color {
        switch self {
        case .red: return .red
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        }
    }
}

struct Flashcard: Identifiable, Codable, Hashable {
    let id: UUID
    var question: String
    var answer: String
    var deckId: UUID
    var interval: Double = 1
    var nextReviewDate: Date = Date()
    var correctReviews: Int = 0
    var incorrectReviews: Int = 0
    var reviewTimes: [TimeInterval] = []
    var lastReviewDate: Date = Date()
    
    init(id: UUID = UUID(), question: String, answer: String, deckId: UUID) {
        self.id = id
        self.question = question
        self.answer = answer
        self.deckId = deckId
    }
    
    var averageReviewTime: TimeInterval {
        reviewTimes.isEmpty ? 0 : reviewTimes.reduce(0, +) / Double(reviewTimes.count)
    }
}

class DeckStore: ObservableObject {
    @Published var flashcards: [Flashcard] = []
    @Published var decks: [Deck] = []
    @Published var playedFlashcardsToday: Int = 0
    @Published var availableFlashcardsToday: Int = 0

    init() {
        loadFlashcards()
        loadDecks()
    }

    func addFlashcard(_ flashcard: Flashcard) {
        flashcards.append(flashcard)
        saveFlashcards()
    }

    func deleteFlashcard(_ flashcard: Flashcard) {
        flashcards.removeAll { $0.id == flashcard.id }
        saveFlashcards()
    }

    func updateFlashcard(_ updatedFlashcard: Flashcard) {
        if let index = flashcards.firstIndex(where: { $0.id == updatedFlashcard.id }) {
            flashcards[index] = updatedFlashcard
            saveFlashcards()
        }
    }

    func addDeck(_ deck: Deck) {
        decks.append(deck)
        saveDecks()
    }

    func deleteDeck(_ deck: Deck) {
        decks.removeAll { $0.id == deck.id }
        flashcards.removeAll { $0.deckId == deck.id }
        saveDecks()
        saveFlashcards()
    }

    private func saveFlashcards() {
        if let encodedData = try? JSONEncoder().encode(flashcards) {
            UserDefaults.standard.set(encodedData, forKey: "SavedFlashcards")
        }
    }

    public func loadFlashcards() {
        if let data = UserDefaults.standard.data(forKey: "SavedFlashcards"),
           let savedFlashcards = try? JSONDecoder().decode([Flashcard].self, from: data) {
            flashcards = savedFlashcards
        }
    }

    private func saveDecks() {
        if let encodedData = try? JSONEncoder().encode(decks) {
            UserDefaults.standard.set(encodedData, forKey: "SavedDecks")
        }
    }

    public func loadDecks() {
        if let data = UserDefaults.standard.data(forKey: "SavedDecks"),
           let savedDecks = try? JSONDecoder().decode([Deck].self, from: data) {
            decks = savedDecks
        }
    }

    func flashcardsForReview(for deckId: UUID) -> [Flashcard] {
        flashcards.filter { $0.deckId == deckId && $0.nextReviewDate <= Date() }
    }
    
    func updatePlayedFlashcards() {
        let today = Calendar.current.startOfDay(for: Date())
        playedFlashcardsToday = flashcards.filter { Calendar.current.isDate($0.lastReviewDate, inSameDayAs: today) }.count
        availableFlashcardsToday = flashcards.filter { $0.nextReviewDate <= today }.count
    }

    func markFlashcardAsPlayed(_ flashcard: Flashcard) {
        if var updatedFlashcard = flashcards.first(where: { $0.id == flashcard.id }) {
            updatedFlashcard.lastReviewDate = Date()
            updateFlashcard(updatedFlashcard)
        }
        updatePlayedFlashcards()
    }
    
    func updateFlashcardInterval(_ flashcard: Flashcard, correct: Bool) {
        if var updatedFlashcard = flashcards.first(where: { $0.id == flashcard.id }) {
            if correct {
                updatedFlashcard.interval *= 2
            } else {
                updatedFlashcard.interval = 1
            }
            updatedFlashcard.nextReviewDate = Calendar.current.date(byAdding: .day, value: Int(updatedFlashcard.interval), to: Date())!
            updateFlashcard(updatedFlashcard)
        }
    }
}

// Vista per aggiungere un nuovo mazzo
struct AddDeckView: View {
    @EnvironmentObject var folderStore: FolderStore
    @Environment(\.presentationMode) var presentationMode
    let parentFolder: Folder
    
    @State private var deckName = ""
    @State private var selectedColor = DeckColor.blue
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Nome Mazzo", text: $deckName)
                
                Picker("Colore", selection: $selectedColor) {
                    ForEach(DeckColor.allCases, id: \.self) { deckColor in
                        HStack {
                            Circle()
                                .fill(deckColor.color)
                                .frame(width: 30, height: 30)
                            Text(deckColor.rawValue.capitalized)
                        }
                        .tag(deckColor)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .navigationTitle("Aggiungi Mazzo")
            .navigationBarItems(
                leading: Button("Annulla") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Salva") {
                    let newDeck = Deck(name: deckName, color: selectedColor)
                    folderStore.addDeck(to: parentFolder, newDeck: newDeck)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(deckName.isEmpty)
            )
        }
    }
}

// Vista principale per un mazzo
struct DeckView: View {
    @EnvironmentObject var deckStore: DeckStore
    @EnvironmentObject var folderStore: FolderStore
    let deck: Deck
    let parentFolder: Folder
    @State private var showingEditDeck = false
    @State private var inputText = ""
    @FocusState private var isTextEditorFocused: Bool

    private var deckFlashcards: [Flashcard] {
        deckStore.flashcards.filter { $0.deckId == deck.id }
    }

    var body: some View {
        List {
            Section(header: Text("Creazione").textCase(.uppercase)) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Creazione Manuale")
                        .font(.headline)

                    TextEditor(text: $inputText)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                        .focused($isTextEditorFocused)

                    HStack {
                        Button(action: {
                            addFlashcardsFromInput()
                        }) {
                            Text("Crea Flashcard")
                        }
                        .disabled(inputText.isEmpty)

                        Spacer()

                        Button(action: {
                            isTextEditorFocused = false
                        }) {
                            Image(systemName: "keyboard.chevron.compact.down")
                        }
                    }
                }
            }

            if !deckFlashcards.isEmpty {
                Section(header: Text("Le tue Flashcard").textCase(.uppercase)) {
                    ForEach(deckFlashcards) { flashcard in
                        VStack(alignment: .leading) {
                            Text(flashcard.question)
                                .font(.headline)
                            Text(flashcard.answer)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete(perform: deleteFlashcards)
                }
            }
        }
        .navigationTitle(deck.name)
        .navigationBarItems(trailing: HStack {
            Button(action: {
                showingEditDeck = true
            }) {
                Image(systemName: "pencil")
            }
            Button(action: {
            }) {
                Image(systemName: "square.and.arrow.up")
            }
            Button(action: {
            }) {
                Image(systemName: "square.and.arrow.down")
            }
        })
        .sheet(isPresented: $showingEditDeck) {
            EditDeckView(parentFolder: parentFolder, deck: deck)
        }

    }

    private func addFlashcardsFromInput() {
        let flashcards = createFlashcards(inputText)
        flashcards.forEach { deckStore.addFlashcard($0) }
        inputText = "" // Clear input text after creating flashcards
    }

    private func deleteFlashcards(at offsets: IndexSet) {
        offsets.map { deckFlashcards[$0] }.forEach { deckStore.deleteFlashcard($0) }
    }

    private func createFlashcards(_ content: String) -> [Flashcard] {
        let components = content.components(separatedBy: "+")
        return components.compactMap { component in
            let parts = component.components(separatedBy: "::")
            guard parts.count == 2 else { return nil }
            return Flashcard(question: parts[0].trimmedSpacesAndNewlines(),
                             answer: parts[1].trimmedSpacesAndNewlines(),
                             deckId: deck.id)
        }
    }
}

// Vista per modificare un mazzo esistente
struct EditDeckView: View {
    @EnvironmentObject var folderStore: FolderStore
    @Environment(\.presentationMode) var presentationMode
    
    var parentFolder: Folder
    var deck: Deck
    
    @State private var deckName: String
    @State private var selectedColor: DeckColor
    
    init(parentFolder: Folder, deck: Deck) {
        self.parentFolder = parentFolder
        self.deck = deck
        _deckName = State(initialValue: deck.name)
        _selectedColor = State(initialValue: deck.color)
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Nome Mazzo", text: $deckName)
                
                Picker("Colore", selection: $selectedColor) {
                    ForEach(DeckColor.allCases, id: \.self) { deckColor in
                        HStack {
                            Circle()
                                .fill(deckColor.color)
                                .frame(width: 30, height: 30)
                            Text(deckColor.rawValue.capitalized)
                        }
                        .tag(deckColor)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .navigationTitle("Modifica Mazzo")
            .navigationBarItems(
                leading: Button("Annulla") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Salva") {
                    let updatedDeck = Deck(id: deck.id, name: deckName, color: selectedColor)
                    folderStore.editDeck(in: parentFolder, deck: updatedDeck, newName: deckName, newColor: selectedColor)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(deckName.isEmpty)
            )
        }
    }
}

// Estensione per semplificare la rimozione degli spazi bianchi
extension String {
    func trimmedSpacesAndNewlines() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

