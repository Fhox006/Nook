import SwiftUI

struct SettingsPlayView: View {
    @EnvironmentObject var folderStore: FolderStore
    @EnvironmentObject var deckStore: DeckStore
    @State private var showingPlayView = false
    @State private var selectedDecks: Set<UUID> = []
    @State private var nextReviewDate: Date?

    var body: some View {
        VStack {
            if foldersWithAvailableDecks().isEmpty {
                if let nextDate = nextReviewDate {
                    Text("Next review on \(nextDateFormatted)")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Text("No flashcards to review!")
                        .foregroundColor(.secondary)
                        .padding()
                }
            } else {
                List {
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
        .onAppear {
            selectedDecks = Set(foldersWithAvailableDecks().flatMap { folder in
                availableDecksInFolder(folder).map { $0.id }
            })
            calculateNextReviewDate()
        }
    }
    
    private func foldersWithAvailableDecks() -> [Folder] {
        func recursiveSubfolders(in folder: Folder) -> [Folder] {
            var result = [folder]
            for subfolder in folder.subfolders {
                result.append(contentsOf: recursiveSubfolders(in: subfolder))
            }
            return result
        }

        return recursiveSubfolders(in: folderStore.rootFolder).filter { folder in
            !availableDecksInFolder(folder).isEmpty
        }
    }
    
    private func availableDecksInFolder(_ folder: Folder) -> [Deck] {
        folder.decks.filter { deck in
            !deckStore.flashcardsForReview(for: deck.id).isEmpty
        }
    }
    
    private func toggleDeckSelection(_ deckId: UUID) {
        if selectedDecks.contains(deckId) {
            selectedDecks.remove(deckId)
        } else {
            selectedDecks.insert(deckId)
        }
    }
    
    private var playButton: some View {
        Button(action: {
            showingPlayView = true
        }) {
            Image(systemName: "play")
        }
        .disabled(selectedDecks.isEmpty)
    }
    
    private func calculateNextReviewDate() {
        let today = Calendar.current.startOfDay(for: Date())
        nextReviewDate = selectedDecks.flatMap { deckStore.flashcardsForReview(for: $0) }
            .filter { $0.nextReviewDate > today }
            .map { $0.nextReviewDate }
            .min()
    }

    private var nextDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: nextReviewDate ?? Date())
    }
}
