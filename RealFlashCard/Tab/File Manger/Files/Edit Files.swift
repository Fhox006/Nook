/*
import SwiftUI
struct AddFolderView: View {
    @EnvironmentObject var folderStore: FolderStore
    @Environment(\.presentationMode) var presentationMode
    let parentFolder: Folder

    @State private var folderName = ""
    @State private var selectedIcon = Icons.all.first ?? "folder"

    var body: some View {
        NavigationView {
            Form {
                TextField("Nome Cartella", text: $folderName)
                
                Picker("Icona", selection: $selectedIcon) {
                    ForEach(Icons.all, id: \.self) { icon in
                        HStack {
                            Image(systemName: icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .padding(8)
                            Text(icon.capitalized)
                        }
                        .tag(icon)
                    }
                }
                .pickerStyle(MenuPickerStyle())
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

struct EditFolderView: View {
    @EnvironmentObject var folderStore: FolderStore
    @Environment(\.presentationMode) var presentationMode
    let folder: Folder
    
    @State private var folderName: String
    @State private var selectedIcon: String
    let icons = Icons.all
    
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
                        HStack {
                            Image(systemName: icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .padding(8)
                            Text(icon.capitalized)
                        }
                        .tag(icon)
                    }
                }
                .pickerStyle(MenuPickerStyle())
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

struct AddDeckView: View {
    @EnvironmentObject var folderStore: FolderStore
    @Environment(\.presentationMode) var presentationMode
    let parentFolder: Folder
    
    @State private var deckName = ""
    @State private var selectedColor = DeckColor.blue
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Nome Mazzo", text: $deckName)
                
                Picker("Colore", selection: $selectedColor) {
                    ForEach(DeckColor.allCases, id: \.self) { deckColor in
                        HStack {
                            Circle()
                                .fill(deckColor.color)
                                .frame(width: 30, height: 30)
                            Text(deckColor.rawValue.capitalized)
                        }
                        .tag(deckColor)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .navigationTitle("Aggiungi Mazzo")
            .navigationBarItems(
                leading: Button("Annulla") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Salva") {
                    let newDeck = Deck(name: deckName, color: selectedColor)
                    folderStore.addDeck(to: parentFolder, newDeck: newDeck)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(deckName.isEmpty)
            )
        }
    }
}

//MARK: - Deck
struct EditDeckView: View {
    @EnvironmentObject var folderStore: FolderStore
    @Environment(\.presentationMode) var presentationMode
    
    var parentFolder: Folder
    var deck: Deck
    
    @State private var deckName: String
    @State private var selectedColor: DeckColor
    
    init(parentFolder: Folder, deck: Deck) {
        self.parentFolder = parentFolder
        self.deck = deck
        _deckName = State(initialValue: deck.name)
        _selectedColor = State(initialValue: deck.color)
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Nome Mazzo", text: $deckName)
                
                Picker("Colore", selection: $selectedColor) {
                    ForEach(DeckColor.allCases, id: \.self) { deckColor in
                        HStack {
                            Circle()
                                .fill(deckColor.color)
                                .frame(width: 30, height: 30)
                            Text(deckColor.rawValue.capitalized)
                        }
                        .tag(deckColor)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .navigationTitle("Modifica Mazzo")
            .navigationBarItems(
                leading: Button("Annulla") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Salva") {
                    let updatedDeck = Deck(id: deck.id, name: deckName, color: selectedColor)
                    folderStore.editDeck(in: parentFolder, deck: updatedDeck, newName: deckName, newColor: selectedColor)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(deckName.isEmpty)
            )
        }
    }
}

extension String {
    func trimmedSpacesAndNewlines() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
*/
