import SwiftUI

// MARK: - SettingsPlayView
struct SettingsPlayView: View {
    @EnvironmentObject var folderStore: FolderStore
    @EnvironmentObject var deckStore: DeckStore
    @State private var showingPlayView = false
    @State private var selectedDecks: Set<UUID> = []

    var body: some View {
        NavigationView {
            List {
                // MARK: - Sezioni per cartelle e mazzi
                ForEach(foldersWithAvailableDecks()) { folder in
                    Section(header: Text(folder.name)) {
                        ForEach(availableDecksInFolder(folder)) { deck in
                            DeckRow(deck: deck, folderName: folder.name, isSelected: selectedDecks.contains(deck.id))
                                .onTapGesture {
                                    toggleDeckSelection(deck.id)
                                }
                        }
                    }
                }
            }
            .navigationTitle("Play")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    playButton
                }
            }
            .sheet(isPresented: $showingPlayView) {
                PlayView(selectedDeckIds: Array(selectedDecks))
                    .environmentObject(deckStore)
                    .environmentObject(folderStore)
            }
        }
    }
    
    // MARK: - Funzioni di supporto
    private func foldersWithAvailableDecks() -> [Folder] {
        folderStore.rootFolder.subfolders.filter { folder in
            folder.decks.contains { !deckStore.flashcardsForReview(for: $0.id).isEmpty }
        }
    }
    
    private func availableDecksInFolder(_ folder: Folder) -> [Deck] {
        folder.decks.filter { !deckStore.flashcardsForReview(for: $0.id).isEmpty }
    }
    
    private func toggleDeckSelection(_ deckId: UUID) {
        if selectedDecks.contains(deckId) {
            selectedDecks.remove(deckId)
        } else {
            selectedDecks.insert(deckId)
        }
    }
    
    // MARK: - Componenti UI
    private var playButton: some View {
        Button(action: {
            showingPlayView = true
        }) {
            Image(systemName: "play")
        }
        .disabled(selectedDecks.isEmpty)
    }
}

// MARK: - DeckRow
struct DeckRow: View {
    let deck: Deck
    let folderName: String
    let isSelected: Bool
    @EnvironmentObject var deckStore: DeckStore
    
    var body: some View {
        HStack {
            Circle()
                .fill(deck.color.color)
                .frame(width: 20, height: 20)
            Text(deck.name.uppercased())
            Spacer()
            Text("\(deckStore.flashcardsForReview(for: deck.id).count)")
                .foregroundColor(.secondary)
            Toggle("", isOn: .constant(isSelected))
                .labelsHidden()
        }
        .contentShape(Rectangle())
    }
}

// MARK: - PlayView
struct PlayView: View {
    @EnvironmentObject var deckStore: DeckStore
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var folderStore: FolderStore
    let selectedDeckIds: [UUID]
    
    // MARK: - Stato
    @State private var currentFlashcardIndex = 0
    @State private var showingAnswer = false
    @State private var flashcards: [Flashcard] = []
    @State private var flashcardsToRepeatToday: Set<UUID> = []
    @State private var showingCongratulations = false
    @State private var cardTimer = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            if !showingCongratulations {
                progressBar
                    .padding(.top)
            }
            
            if showingCongratulations {
                CongratulationsView()
            } else if currentFlashcardIndex < flashcards.count {
                flashcardView(for: flashcards[currentFlashcardIndex])
            } else {
                Text("No flashcards available for review")
                    .font(.headline)
                    .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Play All")
        .onReceive(timer) { _ in
            cardTimer += 1
        }
        .onAppear {
            loadFlashcards()
        }
    }
    
    // MARK: - Componenti UI
    private var progressBar: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(selectedDeckIds, id: \.self) { deckId in
                    progressBarForDeck(deckId, geometry: geometry)
                }
            }
        }
        .frame(height: 30)
        .padding(.horizontal)
    }
    
    private func progressBarForDeck(_ deckId: UUID, geometry: GeometryProxy) -> some View {
        let deckFlashcards = flashcardsForDeck(deckId)
        let deckCompletedFlashcards = deckFlashcards.filter { $0.isCompleted }.count
        let width = (geometry.size.width / CGFloat(flashcards.count)) * CGFloat(deckFlashcards.count)
        
        return VStack(alignment: .leading, spacing: 2) {
            Text("nome folder")
                .font(.caption2)
                .foregroundColor(.secondary)
            Capsule()
                .fill(Color(UIColor.systemGray6))
                .frame(width: width, height: 6)
                .overlay(
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: width * CGFloat(deckCompletedFlashcards) / CGFloat(deckFlashcards.count), height: 6)
                , alignment: .leading)
        }
    }
    
    private func flashcardView(for card: Flashcard) -> some View {
        VStack(spacing: 20) {
            flashcardHeader(for: card)
            
            Spacer()
            
            flashcardContent(for: card)
            
            Spacer()
            
            answerButtons
        }
        .padding()
    }
    
    private func flashcardHeader(for card: Flashcard) -> some View {
        Group {
            if let deck = deckStore.decks.first(where: { $0.id == card.deckId }),
               let folder = folderStore.rootFolder.subfolders.first(where: { $0.decks.contains(deck) }) {
                Text("\(folder.name): \(deck.name)")
                    .font(.headline)
                    .padding(.top)
            } else {
                Text("Deck non trovato")
                    .font(.headline)
                    .padding(.top)
            }
        }
    }
    
    private func flashcardContent(for card: Flashcard) -> some View {
        ZStack {
            VStack {
                Text(showingAnswer ? card.answer : card.question)
                    .font(.system(size: 20, weight: .regular, design: .default))
                    .multilineTextAlignment(.center)
                    .padding()
                    .onTapGesture {
                        withAnimation(.spring()) {
                            showingAnswer.toggle()
                        }
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: 400)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 5)
        }
    }
    
    private var answerButtons: some View {
        HStack {
            Button(action: { markCardIncorrect() }) {
                Image(systemName: "x.circle")
                    .font(.system(size: 30))
                    .foregroundColor(.red)
            }
            
            Spacer()
            
            Button(action: { markCardCorrect() }) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 30))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 50)
        .padding(.bottom)
    }
    
    // MARK: - Funzioni di supporto
    private func loadFlashcards() {
        flashcards = selectedDeckIds.flatMap { deckStore.flashcardsForReview(for: $0) }.shuffled()
    }
    
    private func handleAnswer(correct: Bool) {
        let flashcard = flashcards[currentFlashcardIndex]
        let answerTime = Double(cardTimer)
        
        if correct {
            deckStore.updateFlashcardInterval(flashcard, correct: true)
            statsManager.addCorrectAnswer(time: answerTime)
        } else {
            deckStore.updateFlashcardInterval(flashcard, correct: false)
            flashcardsToRepeatToday.insert(flashcard.id)
            statsManager.addIncorrectAnswer(time: answerTime)
        }
        
        flashcards[currentFlashcardIndex].isCompleted = true
        currentFlashcardIndex += 1
        showingAnswer = false
        cardTimer = 0

        if currentFlashcardIndex >= flashcards.count {
            showingCongratulations = true
        }
    }

    private func markCardCorrect() {
        handleAnswer(correct: true)
    }

    private func markCardIncorrect() {
        handleAnswer(correct: false)
    }
    
    private func flashcardsForDeck(_ deckId: UUID) -> [Flashcard] {
        flashcards.filter { $0.deckId == deckId }
    }
}

// MARK: - CongratulationsView
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

// MARK: - Estensioni
extension Flashcard {
    var isCompleted: Bool {
        get { false }
        set { }
    }
}
