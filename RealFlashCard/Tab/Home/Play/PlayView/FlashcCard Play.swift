import SwiftUI

// MARK: - FlashcardPlayView
struct FlashcardPlayView: View {
    let card: Flashcard
    @Binding var showingAnswer: Bool
    var markCardIncorrect: () -> Void
    var markCardCorrect: () -> Void
    @EnvironmentObject var deckStore: DeckStore
    @EnvironmentObject var folderStore: FolderStore
    
    @State private var isFlipped = false
    @State private var timeElapsed = 0
    @State private var timerRunning = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            FlashcardHeaderView(card: card)
            
            Spacer()
            
            FlashcardContentView(card: card, isFlipped: $isFlipped, showingAnswer: $showingAnswer)
            
            Spacer()
            
            AnswerButtonsView(markCardIncorrect: markCardIncorrect, markCardCorrect: markCardCorrect)
            
            TimerView(timeElapsed: $timeElapsed)
        }
        .padding()
        .onReceive(timer) { _ in
            if timerRunning {
                timeElapsed += 1
            }
        }
        .onAppear {
            startTimer()
        }
        .onChange(of: card) { _ in
            resetTimer()
        }
    }
    
    private func startTimer() {
        timerRunning = true
    }
    
    private func resetTimer() {
        timeElapsed = 0
        timerRunning = true
    }
}

// MARK: - FlashcardHeaderView
struct FlashcardHeaderView: View {
    let card: Flashcard
    @EnvironmentObject var deckStore: DeckStore
    @EnvironmentObject var folderStore: FolderStore
    
    var body: some View {
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
}

// MARK: - FlashcardContentView
struct FlashcardContentView: View {
    let card: Flashcard
    @Binding var isFlipped: Bool
    @Binding var showingAnswer: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Text(card.question)
                    .font(.system(size: 20, weight: .regular, design: .default))
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .opacity(isFlipped ? 0 : 1)
                
                Text(card.answer)
                    .font(.system(size: 20, weight: .regular, design: .default))
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(
                        .degrees(isFlipped ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .center,
                        perspective: 0.5
                    )
            }
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            anchor: .center,
            perspective: 0.5
        )
        .animation(.spring(), value: isFlipped)
        .onTapGesture {
            withAnimation {
                isFlipped.toggle()
            }
        }
    }
}

// MARK: - AnswerButtonsView
struct AnswerButtonsView: View {
    var markCardIncorrect: () -> Void
    var markCardCorrect: () -> Void
    
    var body: some View {
        HStack {
            Button(action: markCardIncorrect) {
                Image(systemName: "x.circle")
                    .font(.system(size: 30))
                    .foregroundColor(.red)
            }
            
            Spacer()
            
            Button(action: markCardCorrect) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 30))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 50)
        .padding(.bottom)
    }
}

// MARK: - TimerView
struct TimerView: View {
    @Binding var timeElapsed: Int
    
    var body: some View {
        Text(formattedTime(timeElapsed))
            .font(.caption)
            .foregroundColor(.gray)
            .padding(.bottom)
    }
    
    private func formattedTime(_ time: Int) -> String {
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct ProgressBarView: View {
    let selectedDeckIds: [UUID]
    let flashcards: [Flashcard]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(selectedDeckIds, id: \.self) { deckId in
                    ProgressBarForDeck(deckId: deckId, flashcards: flashcards, geometry: geometry)
                }
            }
        }
        .frame(height: 30)
        .padding(.horizontal)
    }
}

struct ProgressBarForDeck: View {
    let deckId: UUID
    let flashcards: [Flashcard]
    let geometry: GeometryProxy
    
    private var deckFlashcards: [Flashcard] {
        flashcards.filter { $0.deckId == deckId }
    }
    
    private var deckCompletedFlashcards: Int {
        deckFlashcards.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        let width = (geometry.size.width / CGFloat(flashcards.count)) * CGFloat(deckFlashcards.count)
        
        VStack(alignment: .leading, spacing: 2) {
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
}
