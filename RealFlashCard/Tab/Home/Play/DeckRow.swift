import SwiftUI

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
