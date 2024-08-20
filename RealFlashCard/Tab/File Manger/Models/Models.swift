import SwiftUI

//MARK: - Folder
struct Folder: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var subfolders: [Folder]
    var decks: [Deck]
    
    init(id: UUID = UUID(), name: String, icon: String, subfolders: [Folder] = [], decks: [Deck] = []) {
        self.id = id
        self.name = name
        self.icon = icon
        self.subfolders = subfolders
        self.decks = decks
    }
}

//MARK: - Deck
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

enum DeckColor: String, CaseIterable, Codable {
    case red, green, blue, purple, yellow, orange, pink, brown, gray, black, teal, cyan, indigo
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .red: return .red
        case .green: return .green
        case .purple: return .purple
        case .yellow: return .yellow
        case .orange: return .orange
        case .pink: return .pink
        case .brown: return .brown
        case .gray: return .gray
        case .black: return .black
        case .teal: return .teal
        case .cyan: return .cyan
        case .indigo: return .indigo
        }
    }
}

// MARK: - Flashcard
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

    var isCompleted: Bool {
        get { false }
        set { }
    }
}
