import SwiftUI

struct DeckToolbarMenu: View {
    @Binding var showingImportExportMenu: Bool
    let deckFlashcards: [Flashcard]
    @Binding var isCopyingInProgress: Bool
    @Binding var showCopySuccessAlert: Bool
    
    var body: some View {
        Menu {
            Button(action: copyAndSaveToNotes) {
                Label("Copy and Save to Notes", systemImage: "doc.on.clipboard")
            }
            Button(action: {
                // Implement save as .txt file functionality
            }) {
                Label("Save as .txt file", systemImage: "square.and.arrow.down")
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .imageScale(.large)
        }
    }
    
    private func copyAndSaveToNotes() {
        isCopyingInProgress = true
        DispatchQueue.global(qos: .userInitiated).async {
            let exportString = deckFlashcards.map { "+\($0.question)::\($0.answer)" }.joined()
            UIPasteboard.general.string = exportString
            DispatchQueue.main.async {
                isCopyingInProgress = false
                showCopySuccessAlert = true
            }
        }
    }
}

struct DeckView: View {
    @EnvironmentObject var deckStore: DeckStore
    @EnvironmentObject var folderStore: FolderStore
    let deck: Deck
    let parentFolder: Folder
    
    @State private var inputText = ""
    @FocusState private var isTextEditorFocused: Bool
    
    @State private var isEditingDeckName = false
    @State private var editedDeckName = ""
    @State private var selectedColor: DeckColor
    
    @State private var showingImportExportMenu = false
    @State private var isCopyingInProgress = false
    @State private var showCopySuccessAlert = false
    
    init(deck: Deck, parentFolder: Folder) {
        self.deck = deck
        self.parentFolder = parentFolder
        _editedDeckName = State(initialValue: deck.name)
        _selectedColor = State(initialValue: deck.color)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            EditableDeckView(
                isEditingDeckName: $isEditingDeckName,
                editedDeckName: $editedDeckName,
                selectedColor: $selectedColor,
                onCommit: { newName, newColor in
                    folderStore.editDeck(in: parentFolder, deck: deck, newName: newName, newColor: newColor)
                    editedDeckName = newName
                    selectedColor = newColor
                }
            )
            .padding(.top, 8)
            
            List {
                CreationSection(inputText: $inputText, isTextEditorFocused: $isTextEditorFocused, addFlashcards: addFlashcardsFromInput)
                
                if !deckFlashcards.isEmpty {
                    FlashcardListSection(deckFlashcards: deckFlashcards, deleteFlashcards: deleteFlashcards)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            DeckToolbarMenu(
                showingImportExportMenu: $showingImportExportMenu,
                deckFlashcards: deckFlashcards,
                isCopyingInProgress: $isCopyingInProgress,
                showCopySuccessAlert: $showCopySuccessAlert
            )
        }
        .overlay(
            Group {
                if showingImportExportMenu {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showingImportExportMenu = false
                        }
                }
            }
        )
        .onAppear {
            editedDeckName = deck.name
            selectedColor = deck.color
        }
        .alert(isPresented: $showCopySuccessAlert) {
            Alert(
                title: Text("Success"),
                message: Text("Flashcards have been copied to clipboard."),
                dismissButton: .default(Text("OK"))
            )
        }
        .disabled(isCopyingInProgress) // Disabilita l'interazione quando in copia
    }
    
    private var deckFlashcards: [Flashcard] {
        deckStore.flashcards.filter { $0.deckId == deck.id }
    }
    
    private func addFlashcardsFromInput() {
        let flashcards = createFlashcards(inputText)
        flashcards.forEach { deckStore.addFlashcard($0) }
        inputText = ""
    }
    
    private func deleteFlashcards(at offsets: IndexSet) {
        offsets.map { deckFlashcards[$0] }.forEach { deckStore.deleteFlashcard($0) }
    }
    
    private func createFlashcards(_ content: String) -> [Flashcard] {
        let components = content.components(separatedBy: "+")
        return components.compactMap { component -> Flashcard? in
            let parts = component.components(separatedBy: "::")
            guard parts.count == 2 else { return nil }
            return Flashcard(question: parts[0].trimmingCharacters(in: .whitespacesAndNewlines),
                             answer: parts[1].trimmingCharacters(in: .whitespacesAndNewlines),
                             deckId: deck.id)
        }
    }
}

struct EditableDeckView: View {
    @Binding var isEditingDeckName: Bool
    @Binding var editedDeckName: String
    @Binding var selectedColor: DeckColor
    @FocusState private var isDeckNameFocused: Bool
    
    let colors = DeckColor.allCases
    let colorNames: [DeckColor: String] = [
        .blue: "Blue",
        .red: "Red",
        .green: "Green",
        .purple: "Purple",
        .yellow: "Yellow",
        .orange: "Orange",
        .pink: "Pink",
        .brown: "Brown",
        .gray: "Gray",
        .black: "Black",
        .teal: "Teal",
        .cyan: "Cyan",
        .indigo: "Indigo"
    ]
    
    var onCommit: (String, DeckColor) -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            Menu {
                Picker(selection: $selectedColor, label: Text("Color")) {
                    ForEach(colors, id: \.self) { color in
                        HStack(spacing: 2) {
                            Circle()
                                .fill(color.color)
                                .frame(width: 24, height: 24)
                            
                            Text(colorNames[color] ?? "Unknown")
                                .foregroundColor(.primary)
                        }
                        .tag(color)
                    }
                }
                .onChange(of: selectedColor) { _ in
                    commitChanges()
                }
            } label: {
                Circle()
                    .fill(selectedColor.color)
                    .frame(width: 24, height: 24)
            }
            
            TextField("", text: $editedDeckName, onCommit: {
                commitChanges()
            })
            .font(.system(size: 28, weight: .bold))
            .textFieldStyle(PlainTextFieldStyle())
            .multilineTextAlignment(.leading)
            .focused($isDeckNameFocused)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(Color(.systemBackground))
    }
    
    private func commitChanges() {
        if !editedDeckName.isEmpty {
            onCommit(editedDeckName, selectedColor)
            withAnimation {
                isEditingDeckName = false
                isDeckNameFocused = false
            }
        }
    }
}

struct CreationSection: View {
    @Binding var inputText: String
    var isTextEditorFocused: FocusState<Bool>.Binding
    let addFlashcards: () -> Void

    var body: some View {
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
                    .focused(isTextEditorFocused)

                HStack {
                    Button(action: addFlashcards) {
                        Text("Crea Flashcard")
                    }
                    .disabled(inputText.isEmpty)

                    Spacer()

                    Button(action: {
                        isTextEditorFocused.wrappedValue = false
                    }) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .imageScale(.large)
                    }
                }
            }
            .padding()
        }
    }
}

struct FlashcardListSection: View {
    let deckFlashcards: [Flashcard]
    let deleteFlashcards: (IndexSet) -> Void

    var body: some View {
        Section(header: Text("Flashcards").textCase(.uppercase)) {
            ForEach(deckFlashcards) { flashcard in
                HStack {
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
