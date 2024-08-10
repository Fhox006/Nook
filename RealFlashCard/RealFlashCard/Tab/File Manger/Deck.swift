import SwiftUI
import UniformTypeIdentifiers

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

    private let flashcardsKey = "SavedFlashcards"
    private let decksKey = "SavedDecks"

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
            UserDefaults.standard.set(encodedData, forKey: flashcardsKey)
        }
    }

    public func loadFlashcards() {
        if let data = UserDefaults.standard.data(forKey: flashcardsKey),
           let savedFlashcards = try? JSONDecoder().decode([Flashcard].self, from: data) {
            flashcards = savedFlashcards
        }
    }

    private func saveDecks() {
        if let encodedData = try? JSONEncoder().encode(decks) {
            UserDefaults.standard.set(encodedData, forKey: decksKey)
        }
    }

    public func loadDecks() {
        if let data = UserDefaults.standard.data(forKey: decksKey),
           let savedDecks = try? JSONDecoder().decode([Deck].self, from: data) {
            decks = savedDecks
        }
    }

    func flashcardsForReview(for deckId: UUID) -> [Flashcard] {
        flashcards.filter { $0.deckId == deckId && $0.nextReviewDate <= Date() }
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
    @State private var showingAIMaker = false
    @State private var showingEditDeck = false
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var inputText = ""
    @FocusState private var isTextEditorFocused: Bool

    private var deckFlashcards: [Flashcard] {
        deckStore.flashcards.filter { $0.deckId == deck.id }
    }

    var body: some View {
        List {
            Section(header: Text("Creazione").textCase(.uppercase)) {
                Button(action: { showingAIMaker = true }) {
                    Label("Crea Flashcard con AI", systemImage: "sparkles")
                }
                .sheet(isPresented: $showingAIMaker) {
                    AIMakerView(deck: deck)
                }

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
                        NavigationLink(destination: FlashcardView(flashcard: binding(for: flashcard))) {
                            VStack(alignment: .leading) {
                                Text(flashcard.question)
                                    .font(.headline)
                                Text(flashcard.answer)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteFlashcards)
                }
            }
        }
        .navigationTitle(deck.name)
        .navigationBarItems(trailing: HStack {
            Button(action: { showingExportSheet = true }) {
                Image(systemName: "square.and.arrow.up")
            }
            Button(action: { showingImportSheet = true }) {
                Image(systemName: "square.and.arrow.down")
            }
            Button(action: { showingEditDeck = true }) {
                            Image(systemName: "pencil")
                        }
                    })
                    .sheet(isPresented: $showingEditDeck) {
                        EditDeckView(parentFolder: parentFolder, deck: deck)
                    }
                    .fileImporter(
                        isPresented: $showingImportSheet,
                        allowedContentTypes: [.flashcards],
                        allowsMultipleSelection: false
                    ) { result in
                        do {
                            guard let selectedFile = try result.get().first else { return }
                            if let importedFlashcards = FlashcardExportImportManager.importFlashcards(from: selectedFile) {
                                for var flashcard in importedFlashcards {
                                    flashcard.deckId = deck.id
                                    deckStore.addFlashcard(flashcard)
                                }
                            }
                        } catch {
                            print("Error importing flashcards: \(error)")
                        }
                    }
                    .fileExporter(
                        isPresented: $showingExportSheet,
                        document: FlashcardDocument(flashcards: deckFlashcards),
                        contentType: .flashcards,
                        defaultFilename: "\(deck.name)_flashcards.flashcards"
                    ) { result in
                        switch result {
                        case .success(let url):
                            print("Flashcards exported successfully: \(url)")
                        case .failure(let error):
                            print("Error exporting flashcards: \(error)")
                    }
                }
            }

    private func addFlashcardsFromInput() {
        let flashcards = createFlashcards(inputText)
        flashcards.forEach { deckStore.addFlashcard($0) }
        inputText = "" // Clear input text after creating flashcards
    }

    private func createFlashcards(_ content: String) -> [Flashcard] {
        let components = content.components(separatedBy: "+")
        return components.compactMap { component in
            let parts = component.components(separatedBy: "::")
            guard parts.count == 2 else { return nil }
            return Flashcard(question: parts[0].trimmingCharacters(in: .whitespacesAndNewlines),
                             answer: parts[1].trimmingCharacters(in: .whitespacesAndNewlines),
                             deckId: deck.id)
        }
    }
    
    struct FlashcardDocument: FileDocument {
        var flashcards: [Flashcard]
        
        static var readableContentTypes: [UTType] { [.flashcards] }
        
        init(flashcards: [Flashcard]) {
            self.flashcards = flashcards
        }
        
        init(configuration: ReadConfiguration) throws {
            guard let data = configuration.file.regularFileContents else {
                throw CocoaError(.fileReadCorruptFile)
            }
            let decodedFlashcards = try JSONDecoder().decode(FlashcardExportData.self, from: data)
            self.flashcards = decodedFlashcards.flashcards
        }
        
        func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            let data = try JSONEncoder().encode(FlashcardExportData(flashcards: flashcards))
            return .init(regularFileWithContents: data)
        }
    }

    private func deleteFlashcards(at offsets: IndexSet) {
        offsets.map { deckFlashcards[$0] }.forEach { deckStore.deleteFlashcard($0) }
    }

    private func binding(for flashcard: Flashcard) -> Binding<Flashcard> {
        Binding(
            get: { flashcard },
            set: { updatedFlashcard in
                deckStore.updateFlashcard(updatedFlashcard)
            }
        )
    }
}

struct DeckDocument: FileDocument {
    var deck: Deck
    var flashcards: [Flashcard]
    
    static var readableContentTypes: [UTType] { [.flashcards] }
    
    init(deck: Deck, flashcards: [Flashcard]) {
        self.deck = deck
        self.flashcards = flashcards
    }
    
    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents!
        let exportData = try JSONDecoder().decode(DeckExportData.self, from: data)
        self.deck = exportData.deck
        self.flashcards = exportData.flashcards
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let exportData = DeckExportData(deck: deck, flashcards: flashcards)
        let jsonData = try JSONEncoder().encode(exportData)
        return FileWrapper(regularFileWithContents: jsonData)
    }
}

struct DeckExportData: Codable {
    let deck: Deck
    let flashcards: [Flashcard]
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
