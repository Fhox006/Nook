import SwiftUI

struct PlayView: View {
    @EnvironmentObject var deckStore: DeckStore
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var folderStore: FolderStore
    let selectedDeckIds: [UUID]
    
    @State private var currentFlashcardIndex = 0
    @State private var showingAnswer = false
    @State private var flashcards: [Flashcard] = []
    @State private var incorrectFlashcards: [Flashcard] = []
    @State private var showingCongratulations = false
    @State private var cardTimer = 0
    @State private var nextReviewDate: Date?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            if showingCongratulations {
                CongratulationsView()
            } else {
                ProgressBarView(selectedDeckIds: selectedDeckIds, flashcards: flashcards + incorrectFlashcards)
                    .padding(.top)
                
                if currentFlashcardIndex < flashcards.count || !incorrectFlashcards.isEmpty {
                    if let currentCard = currentCard {
                        FlashcardPlayView(
                            card: currentCard,
                            showingAnswer: $showingAnswer,
                            markCardIncorrect: markCardIncorrect,
                            markCardCorrect: markCardCorrect
                        )
                    }
                } else {
                    Text("No flashcards available for review")
                        .font(.headline)
                        .padding()
                }
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
    
    private var currentCard: Flashcard? {
        if currentFlashcardIndex < flashcards.count {
            return flashcards[currentFlashcardIndex]
        } else if !incorrectFlashcards.isEmpty {
            return incorrectFlashcards.first
        } else {
            return nil
        }
    }
    
    private func loadFlashcards() {
        let today = Calendar.current.startOfDay(for: Date())
        
        flashcards = selectedDeckIds.flatMap { deckStore.flashcardsForReview(for: $0) }
            .filter { Calendar.current.isDate($0.nextReviewDate, inSameDayAs: today) }
            .shuffled()
        
        nextReviewDate = selectedDeckIds.flatMap { deckStore.flashcardsForReview(for: $0) }
            .filter { $0.nextReviewDate > today }
            .map { $0.nextReviewDate }
            .min()
    }
    
    private func handleAnswer(correct: Bool) {
        guard let flashcard = currentCard else { return }
        let answerTime = Double(cardTimer)
        
        if correct {
            updateFlashcardInterval(flashcard, correct: true)
            statsManager.addCorrectAnswer(time: answerTime)
            if let index = incorrectFlashcards.firstIndex(where: { $0.id == flashcard.id }) {
                incorrectFlashcards.remove(at: index)
            }
        } else {
            updateFlashcardInterval(flashcard, correct: false)
            if currentFlashcardIndex < flashcards.count {
                incorrectFlashcards.append(flashcard)
            }
            statsManager.addIncorrectAnswer(time: answerTime)
        }
        
        if currentFlashcardIndex < flashcards.count {
            currentFlashcardIndex += 1
        } else if !incorrectFlashcards.isEmpty {
            incorrectFlashcards.removeFirst()
        }
        
        showingAnswer = false
        cardTimer = 0

        if currentFlashcardIndex >= flashcards.count && incorrectFlashcards.isEmpty {
            showingCongratulations = true
        }
    }

    private func markCardCorrect() {
        handleAnswer(correct: true)
    }

    private func markCardIncorrect() {
        handleAnswer(correct: false)
    }

    private func updateFlashcardInterval(_ flashcard: Flashcard, correct: Bool) {
        if var updatedFlashcard = deckStore.flashcards.first(where: { $0.id == flashcard.id }) {
            if correct {
                updatedFlashcard.interval *= 2
                updatedFlashcard.correctReviews += 1
            } else {
                updatedFlashcard.interval = 1
                updatedFlashcard.incorrectReviews += 1
            }

            if correct || updatedFlashcard.interval > 1 {
                updatedFlashcard.nextReviewDate = Calendar.current.date(byAdding: .day, value: Int(updatedFlashcard.interval), to: Date())!
            } else {
                updatedFlashcard.nextReviewDate = Date() // Imposta la revisione per lo stesso giorno se è sbagliata e l'intervallo è 1
            }

            updatedFlashcard.lastReviewDate = Date()
            updatedFlashcard.reviewTimes.append(TimeInterval(cardTimer))
            deckStore.updateFlashcard(updatedFlashcard)
        }
    }
}
