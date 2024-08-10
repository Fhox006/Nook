import SwiftUI
import UniformTypeIdentifiers

struct FlashcardExportData: Codable {
    let flashcards: [Flashcard]
}

struct FlashcardExportImportManager {
    static func exportFlashcards(_ flashcards: [Flashcard]) -> URL? {
        let exportData = FlashcardExportData(flashcards: flashcards)
        
        guard let jsonData = try? JSONEncoder().encode(exportData) else {
            print("Error encoding flashcards")
            return nil
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Flashcards.flashcards")
        
        do {
            try jsonData.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving file: \(error)")
            return nil
        }
    }
    
    static func importFlashcards(from url: URL) -> [Flashcard]? {
        do {
            let jsonData = try Data(contentsOf: url)
            let importedData = try JSONDecoder().decode(FlashcardExportData.self, from: jsonData)
            return importedData.flashcards
        } catch {
            print("Error importing flashcards: \(error)")
            return nil
        }
    }
}

extension UTType {
    static var flashcards: UTType {
        UTType(importedAs: "com.yourcompany.flashcards")
    }
}
