import SwiftUI

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
}
