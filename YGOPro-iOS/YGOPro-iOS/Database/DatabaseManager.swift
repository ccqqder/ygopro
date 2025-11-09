//
//  DatabaseManager.swift
//  YGOPro-iOS
//
//  SQLite database manager for card data
//

import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: OpaquePointer?
    private var cards: [Int64: Card] = [:]
    private var cardNames: [Int64: String] = [:]
    private var cardDescriptions: [Int64: String] = [:]

    private init() {
        openDatabase()
        loadCards()
    }

    deinit {
        sqlite3_close(db)
    }

    private func openDatabase() {
        // Try to open cards.cdb from app bundle or documents directory
        if let bundlePath = Bundle.main.path(forResource: "cards", ofType: "cdb") {
            if sqlite3_open(bundlePath, &db) != SQLITE_OK {
                print("Error opening database")
            }
        } else if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dbPath = documentsPath.appendingPathComponent("cards.cdb").path
            if sqlite3_open(dbPath, &db) != SQLITE_OK {
                print("Error opening database")
            }
        }
    }

    func loadCards() {
        guard let db = db else { return }

        // Load card data
        let query = "SELECT id, ot, alias, setcode, type, atk, def, level, race, attribute, category FROM datas"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let card = Card(
                    id: id,
                    ot: Int(sqlite3_column_int(statement, 1)),
                    alias: sqlite3_column_int64(statement, 2),
                    setcode: sqlite3_column_int64(statement, 3),
                    type: Int(sqlite3_column_int(statement, 4)),
                    atk: Int(sqlite3_column_int(statement, 5)),
                    def: Int(sqlite3_column_int(statement, 6)),
                    level: Int(sqlite3_column_int(statement, 7)),
                    race: Int(sqlite3_column_int(statement, 8)),
                    attribute: Int(sqlite3_column_int(statement, 9)),
                    category: sqlite3_column_int64(statement, 10)
                )
                cards[id] = card
            }
        }
        sqlite3_finalize(statement)

        // Load card strings (names and descriptions)
        let stringsQuery = "SELECT id, name, desc FROM texts"
        if sqlite3_prepare_v2(db, stringsQuery, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                if let namePtr = sqlite3_column_text(statement, 1) {
                    let name = String(cString: namePtr)
                    cardNames[id] = name
                }
                if let descPtr = sqlite3_column_text(statement, 2) {
                    let desc = String(cString: descPtr)
                    cardDescriptions[id] = desc
                }
            }
        }
        sqlite3_finalize(statement)

        // Merge strings into cards
        for (id, var card) in cards {
            card.name = cardNames[id] ?? "Unknown Card"
            card.desc = cardDescriptions[id] ?? ""
            cards[id] = card
        }
    }

    func getCard(id: Int64) -> Card? {
        return cards[id]
    }

    func searchCards(query: String) -> [Card] {
        let lowercaseQuery = query.lowercased()
        return cards.values.filter { card in
            card.name.lowercased().contains(lowercaseQuery) ||
            card.desc.lowercased().contains(lowercaseQuery)
        }.sorted { $0.name < $1.name }
    }

    func getAllCards() -> [Card] {
        return Array(cards.values).sorted { $0.name < $1.name }
    }

    func filterCards(type: CardFilterType? = nil, race: Int? = nil, attribute: Int? = nil) -> [Card] {
        var filtered = Array(cards.values)

        if let type = type {
            filtered = filtered.filter { card in
                switch type {
                case .monster: return card.isMonster
                case .spell: return card.isSpell
                case .trap: return card.isTrap
                }
            }
        }

        if let race = race {
            filtered = filtered.filter { $0.race == race }
        }

        if let attribute = attribute {
            filtered = filtered.filter { $0.attribute == attribute }
        }

        return filtered.sorted { $0.name < $1.name }
    }

    enum CardFilterType {
        case monster, spell, trap
    }
}
