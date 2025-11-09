//
//  Deck.swift
//  YGOPro-iOS
//
//  Deck model for managing card collections
//

import Foundation

struct Deck: Identifiable, Codable {
    let id: UUID
    var name: String
    var mainDeck: [Int64] // Card IDs
    var extraDeck: [Int64]
    var sideDeck: [Int64]
    var createdDate: Date
    var modifiedDate: Date

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.mainDeck = []
        self.extraDeck = []
        self.sideDeck = []
        self.createdDate = Date()
        self.modifiedDate = Date()
    }

    var totalCards: Int {
        return mainDeck.count + extraDeck.count + sideDeck.count
    }

    var isValid: Bool {
        return mainDeck.count >= 40 && mainDeck.count <= 60 &&
               extraDeck.count <= 15 &&
               sideDeck.count <= 15
    }

    // Check if deck is legal according to ban list
    func isLegal(banList: BanList) -> Bool {
        var cardCounts: [Int64: Int] = [:]

        // Count all cards
        for cardID in mainDeck + extraDeck + sideDeck {
            cardCounts[cardID, default: 0] += 1
        }

        // Check against ban list
        for (cardID, count) in cardCounts {
            if let limit = banList.limits[cardID] {
                if count > limit {
                    return false
                }
            }
        }

        return isValid
    }

    // Export to .ydk format
    func toYDK() -> String {
        var ydk = "#created by YGOPro iOS\n"
        ydk += "#main\n"
        for cardID in mainDeck {
            ydk += "\(cardID)\n"
        }
        ydk += "#extra\n"
        for cardID in extraDeck {
            ydk += "\(cardID)\n"
        }
        ydk += "!side\n"
        for cardID in sideDeck {
            ydk += "\(cardID)\n"
        }
        return ydk
    }

    // Import from .ydk format
    static func fromYDK(_ content: String, name: String) -> Deck? {
        var deck = Deck(name: name)
        var currentSection: String = ""

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#created") {
                continue
            }

            if trimmed.hasPrefix("#main") {
                currentSection = "main"
            } else if trimmed.hasPrefix("#extra") {
                currentSection = "extra"
            } else if trimmed.hasPrefix("!side") {
                currentSection = "side"
            } else if let cardID = Int64(trimmed) {
                switch currentSection {
                case "main":
                    deck.mainDeck.append(cardID)
                case "extra":
                    deck.extraDeck.append(cardID)
                case "side":
                    deck.sideDeck.append(cardID)
                default:
                    break
                }
            }
        }

        return deck
    }
}

struct BanList: Codable {
    let name: String
    let limits: [Int64: Int] // Card ID -> limit (0=forbidden, 1=limited, 2=semi-limited)

    static let unlimited = BanList(name: "Unlimited", limits: [:])

    // Parse from lflist.conf format
    static func parse(from content: String) -> [BanList] {
        var banLists: [BanList] = []
        var currentName: String?
        var currentLimits: [Int64: Int] = [:]

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            if trimmed.hasPrefix("!") {
                // Save previous ban list
                if let name = currentName {
                    banLists.append(BanList(name: name, limits: currentLimits))
                }

                // Start new ban list
                currentName = String(trimmed.dropFirst())
                currentLimits = [:]
            } else {
                // Parse card limit
                let components = trimmed.components(separatedBy: .whitespaces)
                if components.count >= 2,
                   let cardID = Int64(components[0]),
                   let limit = Int(components[1]) {
                    currentLimits[cardID] = limit
                }
            }
        }

        // Save last ban list
        if let name = currentName {
            banLists.append(BanList(name: name, limits: currentLimits))
        }

        return banLists
    }
}
