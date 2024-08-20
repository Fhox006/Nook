import SwiftUI

class FolderStore: ObservableObject {
    @Published var rootFolder: Folder
    
    init() {
        self.rootFolder = Folder(name: "File Manager", icon: "folder")
        loadFolders()
    }
    
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
    
    func moveSubfolders(in parentFolder: Folder, from indices: IndexSet, to newOffset: Int) {
        if parentFolder.id == rootFolder.id {
            rootFolder.subfolders.move(fromOffsets: indices, toOffset: newOffset)
        } else {
            updateSubfolder(parentFolder) { $0.subfolders.move(fromOffsets: indices, toOffset: newOffset) }
        }
        saveFolders()
    }
    
    func moveDecks(in parentFolder: Folder, from indices: IndexSet, to newOffset: Int) {
        updateSubfolder(parentFolder) { $0.decks.move(fromOffsets: indices, toOffset: newOffset) }
        saveFolders()
    }
    
    func getDeck(for folder: Folder) -> Deck? {
        return folder.decks.first
    }
    
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
    
    private func saveFolders() {
        if let encoded = try? JSONEncoder().encode(rootFolder) {
            UserDefaults.standard.set(encoded, forKey: "SavedFolders")
        }
    }
    
    func moveFolder(_ folder: Folder, to destinationId: UUID) {
        var newRoot = self.rootFolder
        
        if removeFolder(&newRoot, folderId: folder.id) {
            if addFolder(&newRoot, folderToAdd: folder, to: destinationId) {
                self.rootFolder = newRoot
                saveFolders()
            }
        }
    }
    
    func moveDeck(_ deck: Deck, to destinationId: UUID) {
        var newRoot = self.rootFolder
        if removeDeck(&newRoot, deckId: deck.id) {
            if addDeck(&newRoot, deckToAdd: deck, to: destinationId) {
                self.rootFolder = newRoot
                saveFolders()
            }
        }
    }
    
    private func removeFolder(_ folder: inout Folder, folderId: UUID) -> Bool {
        if let index = folder.subfolders.firstIndex(where: { $0.id == folderId }) {
            folder.subfolders.remove(at: index)
            return true
        }
        
        for i in 0..<folder.subfolders.count {
            if removeFolder(&folder.subfolders[i], folderId: folderId) {
                return true
            }
        }
        
        return false
    }
    
    private func removeDeck(_ folder: inout Folder, deckId: UUID) -> Bool {
        if let index = folder.decks.firstIndex(where: { $0.id == deckId }) {
            folder.decks.remove(at: index)
            return true
        }
        
        for i in 0..<folder.subfolders.count {
            if removeDeck(&folder.subfolders[i], deckId: deckId) {
                return true
            }
        }
        
        return false
    }
    
    private func addFolder(_ folder: inout Folder, folderToAdd: Folder, to destinationId: UUID) -> Bool {
        if folder.id == destinationId {
            folder.subfolders.append(folderToAdd)
            return true
        }
        
        for i in 0..<folder.subfolders.count {
            if addFolder(&folder.subfolders[i], folderToAdd: folderToAdd, to: destinationId) {
                return true
            }
        }
        
        return false
    }
    
    private func addDeck(_ folder: inout Folder, deckToAdd: Deck, to destinationId: UUID) -> Bool {
        if folder.id == destinationId {
            folder.decks.append(deckToAdd)
            return true
        }
        
        for i in 0..<folder.subfolders.count {
            if addDeck(&folder.subfolders[i], deckToAdd: deckToAdd, to: destinationId) {
                return true
            }
        }
        
        return false
    }
    
    func loadFolders() {
        if let savedFolders = UserDefaults.standard.data(forKey: "SavedFolders"),
           let decodedFolders = try? JSONDecoder().decode(Folder.self, from: savedFolders) {
            self.rootFolder = decodedFolders
        }
    }
}
