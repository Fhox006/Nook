import SwiftUI

// Struttura per rappresentare una cartella
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

// Classe per gestire lo stato delle cartelle
class FolderStore: ObservableObject {
    @Published var rootFolder: Folder
    
    init() {
        self.rootFolder = Folder(name: "File Manager", icon: "folder")
        loadFolders()
    }
    
    // Funzioni per aggiungere, modificare ed eliminare cartelle e mazzi
    func addFolder(to parentFolder: Folder, newFolder: Folder) {
        if parentFolder.id == rootFolder.id {
            rootFolder.subfolders.append(newFolder)
        } else {
            updateSubfolder(parentFolder) { $0.subfolders.append(newFolder) }
        }
        saveFolders()
    }
    
    func addDeck(to parentFolder: Folder, newDeck: Deck) {
            updateSubfolder(parentFolder) { $0.decks.append(newDeck) }
            saveFolders()
        }
    
    func deleteFolder(from parentFolder: Folder, folderToDelete: Folder) {
        if parentFolder.id == rootFolder.id {
            rootFolder.subfolders.removeAll { $0.id == folderToDelete.id }
        } else {
            updateSubfolder(parentFolder) { $0.subfolders.removeAll { $0.id == folderToDelete.id } }
        }
        saveFolders()
    }
    
    func deleteDeck(from parentFolder: Folder, deckToDelete: Deck) {
        updateSubfolder(parentFolder) { $0.decks.removeAll { $0.id == deckToDelete.id } }
        saveFolders()
    }
    
    func editFolder(folder: Folder, newName: String, newIcon: String) {
        updateSubfolder(folder) { $0.name = newName; $0.icon = newIcon }
        saveFolders()
    }
    func editDeck(in parentFolder: Folder, deck: Deck, newName: String, newColor: DeckColor) {
        updateSubfolder(parentFolder) { folder in
            if let index = folder.decks.firstIndex(where: { $0.id == deck.id }) {
                folder.decks[index].name = newName
                folder.decks[index].color = newColor
            }
        }
        saveFolders()
    }
    
    // Funzione helper per aggiornare una sottocartella
    private func updateSubfolder(_ folder: Folder, updateAction: (inout Folder) -> Void) {
        func update(_ folders: inout [Folder]) {
            for index in folders.indices {
                if folders[index].id == folder.id {
                    updateAction(&folders[index])
                    return
                }
                update(&folders[index].subfolders)
            }
        }
        update(&rootFolder.subfolders)
      
    }
    
    // Funzioni per salvare e caricare le cartelle
    private func saveFolders() {
        if let encoded = try? JSONEncoder().encode(rootFolder) {
            UserDefaults.standard.set(encoded, forKey: "SavedFolders")
        }
    }
    
    func loadFolders() {
        if let savedFolders = UserDefaults.standard.data(forKey: "SavedFolders"),
           let decodedFolders = try? JSONDecoder().decode(Folder.self, from: savedFolders) {
            self.rootFolder = decodedFolders
         
        }
    }
}

// Vista principale per la gestione dei file
struct FileView: View {
    @EnvironmentObject var folderStore: FolderStore
    
    var body: some View {
        NavigationStack {
            FolderDetailView(folder: folderStore.rootFolder, isRoot: true)
        }
    }
}

// Vista dettagliata per una cartella
struct FolderDetailView: View {
    @EnvironmentObject var folderStore: FolderStore
    let folder: Folder
    let isRoot: Bool
    
    @State private var showingAddFolder = false
    @State private var showingAddDeck = false
    @State private var showingEditFolder = false
    
    var body: some View {
        VStack {
            if folder.subfolders.isEmpty && folder.decks.isEmpty {
                Text("No files yet")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    // Sezione per le sottocartelle
                    if !folder.subfolders.isEmpty {
                        Section(header: Text("Cartelle")) {
                            ForEach(folder.subfolders) { subfolder in
                                NavigationLink(destination: FolderDetailView(folder: subfolder, isRoot: false)) {
                                    Label(subfolder.name, systemImage: subfolder.icon)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        folderStore.deleteFolder(from: folder, folderToDelete: subfolder)
                                    } label: {
                                        Label("Elimina", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                            }
                        }
                    }
                    
                    // Sezione per i mazzi
                    if !folder.decks.isEmpty {
                        Section(header: Text("Mazzi")) {
                            ForEach(folder.decks) { deck in
                                NavigationLink(destination: DeckView(deck: deck, parentFolder: folder)) {
                                    Label {
                                        Text(deck.name)
                                    } icon: {
                                        Circle()
                                            .fill(deck.color.color)
                                            .frame(width: 20, height: 20)
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        folderStore.deleteDeck(from: folder, deckToDelete: deck)
                                    } label: {
                                        Label("Elimina", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: { showingAddFolder = true }) {
                        Image(systemName: "folder.badge.plus")
                    }
                    if !isRoot {
                        Button(action: { showingAddDeck = true }) {
                            Image(systemName: "plus")
                        }
                        Button(action: { showingEditFolder = true }) {
                            Image(systemName: "pencil")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddFolder) {
            AddFolderView(parentFolder: folder)
        }
        .sheet(isPresented: $showingAddDeck) {
            AddDeckView(parentFolder: folder)
        }
        .sheet(isPresented: $showingEditFolder) {
            EditFolderView(folder: folder)
        }
    }
}


// Vista per aggiungere una nuova cartella
struct AddFolderView: View {
    @EnvironmentObject var folderStore: FolderStore
    @Environment(\.presentationMode) var presentationMode
    let parentFolder: Folder
    
    @State private var folderName = ""
    @State private var selectedIcon = "folder"
    
    let icons = ["folder", "doc", "photo", "video"]
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Nome Cartella", text: $folderName)
                
                Picker("Icona", selection: $selectedIcon) {
                    ForEach(icons, id: \.self) { icon in
                        Image(systemName: icon).tag(icon)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .navigationTitle("Aggiungi Cartella")
            .navigationBarItems(
                leading: Button("Annulla") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Salva") {
                    let newFolder = Folder(name: folderName, icon: selectedIcon)
                    folderStore.addFolder(to: parentFolder, newFolder: newFolder)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(folderName.isEmpty)
            )
        }
    }
}

// Vista per modificare una cartella esistente
struct EditFolderView: View {
    @EnvironmentObject var folderStore: FolderStore
    @Environment(\.presentationMode) var presentationMode
    let folder: Folder
    
    @State private var folderName: String
    @State private var selectedIcon: String
    
    let icons = ["folder", "doc", "photo", "video"]
    
    init(folder: Folder) {
        self.folder = folder
        _folderName = State(initialValue: folder.name)
        _selectedIcon = State(initialValue: folder.icon)
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Nome Cartella", text: $folderName)
                
                Picker("Icona", selection: $selectedIcon) {
                    ForEach(icons, id: \.self) { icon in
                        Image(systemName: icon).tag(icon)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .navigationTitle("Modifica Cartella")
            .navigationBarItems(
                leading: Button("Annulla") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Salva") {
                    folderStore.editFolder(folder: folder, newName: folderName, newIcon: selectedIcon)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(folderName.isEmpty)
            )
        }
    }
}
