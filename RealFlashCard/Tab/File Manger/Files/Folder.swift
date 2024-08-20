import SwiftUI

// MARK: - FileView
struct FileView: View {
    @EnvironmentObject var folderStore: FolderStore

    var body: some View {
        NavigationStack {
            FolderDetailView(folder: folderStore.rootFolder, isRoot: true)
        }
    }
}

// MARK: - FolderDetailView
struct FolderDetailView: View {
    @EnvironmentObject var folderStore: FolderStore
    let folder: Folder
    let isRoot: Bool

    @State private var showingAddDeck = false
    @State private var newDeck: Deck? // For keeping track of the new deck

    @State private var selectMode: Bool = false
    @State private var moveMode: Bool = false

    @State private var selectedFolders = Set<UUID>()
    @State private var selectedDecks = Set<UUID>()

    @State private var isEditingTitle = false
    @State private var editedTitle = ""

    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                if folder.name != "File Manager" {
                    EditableTitleView(
                        isEditingTitle: $isEditingTitle,
                        editedTitle: $editedTitle,
                        folder: folder,
                        onCommit: { newName, newIcon in
                            folderStore.editFolder(folder: folder, newName: newName, newIcon: newIcon)
                        }
                    )
                    .focused($isTitleFocused)
                    .onChange(of: selectMode) { newValue in
                        if newValue {
                            withAnimation {
                                isEditingTitle = true
                                isTitleFocused = true
                            }
                        }
                    }
                } else {
                    Text(folder.name)
                        .font(.system(size: 28, weight: .bold))
                        .padding(.leading, 16)
                        .padding(.top, 8)
                }

                if folder.subfolders.isEmpty && folder.decks.isEmpty {
                    Text("No files yet")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    FolderListView(
                        folder: folder,
                        selectMode: $selectMode,
                        moveMode: $moveMode,
                        selectedFolders: $selectedFolders,
                        selectedDecks: $selectedDecks
                    )
                }

                Spacer()

                AddButtonView(isRoot: isRoot, selectMode: $selectMode, moveMode: $moveMode, folder: folder, newDeck: $newDeck)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarMenuView(
                    isRoot: isRoot,
                    selectMode: $selectMode,
                    moveMode: $moveMode,
                    isEditingTitle: $isEditingTitle,
                    isTitleFocused: $isTitleFocused,
                    selectedFolders: $selectedFolders,
                    selectedDecks: $selectedDecks
                )
            }
            .navigationDestination(for: Deck.self) { deck in
                DeckView(deck: deck, parentFolder: folder)
            }
        }
    }
}

// MARK: - AddButtonView
struct AddButtonView: View {
    let isRoot: Bool
    @EnvironmentObject var folderStore: FolderStore
    @Binding var selectMode: Bool
    @Binding var moveMode: Bool
    var folder: Folder?
    @Binding var newDeck: Deck?

    var body: some View {
        HStack {
            if isRoot {
                Button(action: {
                    let newFolder = Folder(name: "New Folder", icon: "folder")
                    folderStore.addFolder(to: folderStore.rootFolder, newFolder: newFolder)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .imageScale(.large)
                        .font(.system(size: 48))
                        .padding()
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Menu {
                    Button {
                        guard let folder = folder else { return }
                        let newFolder = Folder(name: "New Folder", icon: "folder")
                        folderStore.addFolder(to: folder, newFolder: newFolder)
                    } label: {
                        Label("Add Folder", systemImage: "folder.badge.plus")
                    }
                    Button {
                        guard let folder = folder else { return }
                        var newDeck = Deck(name: "New Deck", color: .blue)
                        folderStore.addDeck(to: folder, newDeck: newDeck)
                        newDeck = newDeck
                    } label: {
                        Label("Add Deck", systemImage: "square.and.pencil")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .imageScale(.large)
                        .font(.system(size: 48))
                        .padding()
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

// MARK: - EditableTitleView
struct EditableTitleView: View {
    @Binding var isEditingTitle: Bool
    @Binding var editedTitle: String
    @State private var selectedIcon: String
    @FocusState private var isTitleFocused: Bool
    
    var folder: Folder
    var onCommit: (String, String) -> Void
    let icons = Icons.all
    
    init(isEditingTitle: Binding<Bool>, editedTitle: Binding<String>, folder: Folder, onCommit: @escaping (String, String) -> Void) {
        self._isEditingTitle = isEditingTitle
        self._editedTitle = editedTitle
        self.folder = folder
        self._selectedIcon = State(initialValue: folder.icon)
        self.onCommit = onCommit
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 4) {
                Menu {
                    Picker(selection: $selectedIcon, label: Text("Icona")) {
                        ForEach(icons, id: \.self) { icon in
                            HStack {
                                Image(systemName: icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                Text(icon.capitalized)
                                    .foregroundColor(.primary)
                            }
                            .tag(icon)
                        }
                    }
                    .onChange(of: selectedIcon) { _ in
                        commitChanges()
                    }
                } label: {
                    Image(systemName: selectedIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                TextField("", text: $editedTitle, onCommit: {
                    commitChanges()
                })
                .font(.system(size: 28, weight: .bold))
                .textFieldStyle(PlainTextFieldStyle())
                .multilineTextAlignment(.leading)
                .focused($isTitleFocused)
                .foregroundColor(.primary) // Ensure text color is appropriate for both themes
            }
            .padding(.top, 8)
            .onAppear {
                editedTitle = folder.name
                selectedIcon = folder.icon
                // Ensure the text field does not become focused automatically
                DispatchQueue.main.async {
                    isTitleFocused = false
                }
            }
        }
        .padding(.leading, 16)
    }

    private func commitChanges() {
        if !editedTitle.isEmpty {
            onCommit(editedTitle, selectedIcon)
            withAnimation {
                isEditingTitle = false
                isTitleFocused = false
            }
        }
    }
}

// MARK: - ToolbarMenuView
struct ToolbarMenuView: View {
    let isRoot: Bool
    @Binding var selectMode: Bool
    @Binding var moveMode: Bool
    @Binding var isEditingTitle: Bool
    @FocusState.Binding var isTitleFocused: Bool
    @Binding var selectedFolders: Set<UUID>
    @Binding var selectedDecks: Set<UUID>
    
    var body: some View {
        if selectMode {
            Button("Done") {
                withAnimation {
                    selectMode = false
                    selectedFolders.removeAll()
                    selectedDecks.removeAll()
                }
            }
        } else if moveMode {
            Button("Done") {
                withAnimation {
                    moveMode = false
                    selectedFolders.removeAll()
                    selectedDecks.removeAll()
                }
            }
        } else {
            Menu {
                if !isRoot {
                    Button {
                        withAnimation {
                            isEditingTitle = true
                            isTitleFocused = true
                        }
                    } label: {
                        Label("Edit", systemImage: "square.and.pencil")
                    }
                }
                Button {
                    selectMode = true
                } label: {
                    Label("Select", systemImage: "checkmark.circle")
                }
                Button {
                    moveMode = true
                } label: {
                    Label("Move", systemImage: "arrow.up.arrow.down")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .imageScale(.large)
            }
        }
    }
}

// MARK: - FolderListView
struct FolderListView: View {
    @EnvironmentObject var folderStore: FolderStore
    let folder: Folder
    
    @Binding var selectMode: Bool
    @Binding var moveMode: Bool
    @Binding var selectedFolders: Set<UUID>
    @Binding var selectedDecks: Set<UUID>
    
    var body: some View {
        List {
            if !folder.subfolders.isEmpty {
                Section(header: Text("Folders")) {
                    ForEach(folder.subfolders) { subfolder in
                        FolderRowView(subfolder: subfolder, folder: folder, selectMode: $selectMode, moveMode: $moveMode, selectedFolders: $selectedFolders)
                    }
                    .onMove { indices, newOffset in
                        folderStore.moveSubfolders(in: folder, from: indices, to: newOffset)
                    }
                }
            }
            if !folder.decks.isEmpty {
                Section(header: Text("Decks")) {
                    ForEach(folder.decks) { deck in
                        DeckRowView(deck: deck, parentFolder: folder, selectMode: $selectMode, moveMode: $moveMode, selectedDecks: $selectedDecks)
                    }
                    .onMove { indices, newOffset in
                        folderStore.moveDecks(in: folder, from: indices, to: newOffset)
                    }
                }
            }
        }
    }
}

// MARK: - FolderRowView
struct FolderRowView: View {
    @EnvironmentObject var folderStore: FolderStore
    let subfolder: Folder
    let folder: Folder
    
    @Binding var selectMode: Bool
    @Binding var moveMode: Bool
    @Binding var selectedFolders: Set<UUID>
    
    @State private var editingFolder: Folder?
    @State private var draggingFolder: Folder?
    
    var body: some View {
        HStack {
            NavigationLink(destination: FolderDetailView(folder: subfolder, isRoot: false)) {
                HStack {
                    Image(systemName: subfolder.icon)
                        .frame(width: 24, height: 24)
                    Text(subfolder.name)
                        .opacity(selectedFolders.contains(subfolder.id) ? 0.5 : 1.0)
                }
                .contentShape(Rectangle())
            }
            if selectMode {
                Image(systemName: selectedFolders.contains(subfolder.id) ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
                    .onTapGesture {
                        toggleFolderSelection(subfolder)
                    }
            }
        }
        .swipeActions(edge: .trailing) {
            if !selectMode && !moveMode {
                Button(role: .destructive) {
                    folderStore.deleteFolder(from: folder, folderToDelete: subfolder)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                Button {
                    editingFolder = subfolder
                } label: {
                    Label("Edit", systemImage: "square.and.pencil")
                }
                .tint(.blue)
            }
        }
        .contextMenu {
            if !selectMode && !moveMode {
                Button("Edit") {
                    editingFolder = subfolder
                }
                Button("Delete", role: .destructive) {
                    folderStore.deleteFolder(from: folder, folderToDelete: subfolder)
                }
            }
        }
        .gesture(
            LongPressGesture().onEnded { _ in
                if !selectMode {
                    withAnimation {
                        selectMode = true
                    }
                }
            }
        )
        .gesture(
            DragGesture().onChanged { value in
                if selectMode {
                    draggingFolder = subfolder
                    // Logica per il raggruppamento dei file
                }
            }
            .onEnded { _ in
                draggingFolder = nil
            }
        )
    }
    
    private func toggleFolderSelection(_ folder: Folder) {
        if selectedFolders.contains(folder.id) {
            selectedFolders.remove(folder.id)
        } else {
            selectedFolders.insert(folder.id)
        }
    }
}


// MARK: - DeckRowView
struct DeckRowView: View {
    @EnvironmentObject var folderStore: FolderStore
    let deck: Deck
    let parentFolder: Folder
    
    @Binding var selectMode: Bool
    @Binding var moveMode: Bool
    @Binding var selectedDecks: Set<UUID>
    
    @State private var editingDeck: Deck?
    
    var body: some View {
        HStack {
            NavigationLink(destination: DeckView(deck: deck, parentFolder: parentFolder)) {
                HStack {
                    Circle()
                        .fill(deck.color.color)
                        .frame(width: 24, height: 24)
                    Text(deck.name)
                        .opacity(selectedDecks.contains(deck.id) ? 0.5 : 1.0)
                }
                .contentShape(Rectangle())
            }
            if selectMode || moveMode {
                Image(systemName: selectedDecks.contains(deck.id) ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
                    .onTapGesture {
                        toggleDeckSelection(deck)
                    }
            }
        }
        .swipeActions(edge: .trailing) {
            if !selectMode {
                Button(role: .destructive) {
                    folderStore.deleteDeck(from: parentFolder, deckToDelete: deck)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                Button {
                    editingDeck = deck
                } label: {
                    Label("Edit", systemImage: "square.and.pencil")
                }
                .tint(.blue)
            }
        }
        .contextMenu {
            if !selectMode {
                Button("Edit") {
                    editingDeck = deck
                }
                Button("Delete", role: .destructive) {
                    folderStore.deleteDeck(from: parentFolder, deckToDelete: deck)
                }
            }
        }
        .gesture(
            LongPressGesture().onEnded { _ in
                if !selectMode {
                    withAnimation {
                        selectMode = true
                    }
                }
            }
        )
    }
    
    private func toggleDeckSelection(_ deck: Deck) {
        if selectedDecks.contains(deck.id) {
            selectedDecks.remove(deck.id)
        } else {
            selectedDecks.insert(deck.id)
        }
    }
}
