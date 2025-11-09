//
//  DeckManager.swift
//  YGOPro-iOS
//
//  Manager for deck operations and persistence
//

import Foundation
import Combine

class DeckManager: ObservableObject {
    static let shared = DeckManager()

    @Published var decks: [Deck] = []
    @Published var currentDeck: Deck?

    private let fileManager = FileManager.default
    private var decksDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory.appendingPathComponent("decks")
    }

    private init() {
        createDecksDirectoryIfNeeded()
        loadDecks()
    }

    private func createDecksDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: decksDirectory.path) {
            try? fileManager.createDirectory(at: decksDirectory, withIntermediateDirectories: true)
        }
    }

    func loadDecks() {
        do {
            let deckFiles = try fileManager.contentsOfDirectory(at: decksDirectory, includingPropertiesForKeys: nil)
            decks = deckFiles.compactMap { url in
                if url.pathExtension == "ydk" {
                    guard let content = try? String(contentsOf: url) else { return nil }
                    let deckName = url.deletingPathExtension().lastPathComponent
                    return Deck.fromYDK(content, name: deckName)
                } else if url.pathExtension == "json" {
                    guard let data = try? Data(contentsOf: url),
                          let deck = try? JSONDecoder().decode(Deck.self, from: data) else { return nil }
                    return deck
                }
                return nil
            }
        } catch {
            print("Error loading decks: \(error)")
        }
    }

    func saveDeck(_ deck: Deck) {
        // Save as .ydk format
        let ydkURL = decksDirectory.appendingPathComponent("\(deck.name).ydk")
        do {
            try deck.toYDK().write(to: ydkURL, atomically: true, encoding: .utf8)

            // Also save as JSON for metadata
            let jsonURL = decksDirectory.appendingPathComponent("\(deck.name).json")
            let data = try JSONEncoder().encode(deck)
            try data.write(to: jsonURL)

            // Update decks list
            if let index = decks.firstIndex(where: { $0.id == deck.id }) {
                decks[index] = deck
            } else {
                decks.append(deck)
            }
        } catch {
            print("Error saving deck: \(error)")
        }
    }

    func deleteDeck(_ deck: Deck) {
        let ydkURL = decksDirectory.appendingPathComponent("\(deck.name).ydk")
        let jsonURL = decksDirectory.appendingPathComponent("\(deck.name).json")

        try? fileManager.removeItem(at: ydkURL)
        try? fileManager.removeItem(at: jsonURL)

        decks.removeAll { $0.id == deck.id }
    }

    func createNewDeck(name: String) -> Deck {
        let deck = Deck(name: name)
        saveDeck(deck)
        return deck
    }
}
