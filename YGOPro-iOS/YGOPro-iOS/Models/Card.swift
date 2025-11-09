//
//  Card.swift
//  YGOPro-iOS
//
//  Card model representing a Yu-Gi-Oh! card
//

import Foundation

struct Card: Identifiable, Codable, Hashable {
    let id: Int64
    let ot: Int
    let alias: Int64
    let setcode: Int64
    let type: Int
    let atk: Int
    let def: Int
    let level: Int
    let race: Int
    let attribute: Int
    let category: Int64

    var name: String = ""
    var desc: String = ""

    // Computed properties
    var isMonster: Bool {
        return (type & 0x1) != 0
    }

    var isSpell: Bool {
        return (type & 0x2) != 0
    }

    var isTrap: Bool {
        return (type & 0x4) != 0
    }

    var isNormal: Bool {
        return (type & 0x10) != 0
    }

    var isEffect: Bool {
        return (type & 0x20) != 0
    }

    var isFusion: Bool {
        return (type & 0x40) != 0
    }

    var isRitual: Bool {
        return (type & 0x80) != 0
    }

    var isSynchro: Bool {
        return (type & 0x2000) != 0
    }

    var isXyz: Bool {
        return (type & 0x800000) != 0
    }

    var isPendulum: Bool {
        return (type & 0x1000000) != 0
    }

    var isLink: Bool {
        return (type & 0x4000000) != 0
    }

    var cardTypeName: String {
        if isMonster {
            var types: [String] = []
            if isFusion { types.append("Fusion") }
            if isSynchro { types.append("Synchro") }
            if isXyz { types.append("Xyz") }
            if isLink { types.append("Link") }
            if isRitual { types.append("Ritual") }
            if isPendulum { types.append("Pendulum") }
            if isEffect { types.append("Effect") }
            if isNormal { types.append("Normal") }
            return types.joined(separator: " ") + " Monster"
        } else if isSpell {
            return "Spell Card"
        } else if isTrap {
            return "Trap Card"
        }
        return "Unknown"
    }

    var attributeName: String {
        switch attribute {
        case 0x01: return "Earth"
        case 0x02: return "Water"
        case 0x04: return "Fire"
        case 0x08: return "Wind"
        case 0x10: return "Light"
        case 0x20: return "Dark"
        case 0x40: return "Divine"
        default: return "Unknown"
        }
    }

    var raceName: String {
        if isMonster {
            switch race {
            case 0x1: return "Warrior"
            case 0x2: return "Spellcaster"
            case 0x4: return "Fairy"
            case 0x8: return "Fiend"
            case 0x10: return "Zombie"
            case 0x20: return "Machine"
            case 0x40: return "Aqua"
            case 0x80: return "Pyro"
            case 0x100: return "Rock"
            case 0x200: return "Winged Beast"
            case 0x400: return "Plant"
            case 0x800: return "Insect"
            case 0x1000: return "Thunder"
            case 0x2000: return "Dragon"
            case 0x4000: return "Beast"
            case 0x8000: return "Beast-Warrior"
            case 0x10000: return "Dinosaur"
            case 0x20000: return "Fish"
            case 0x40000: return "Sea Serpent"
            case 0x80000: return "Reptile"
            case 0x100000: return "Psychic"
            case 0x200000: return "Divine-Beast"
            case 0x400000: return "Creator God"
            case 0x800000: return "Wyrm"
            case 0x1000000: return "Cyberse"
            default: return "Unknown"
            }
        }
        return ""
    }

    // Image path helpers
    var imagePath: String {
        return "pics/\(id).jpg"
    }

    var thumbnailPath: String {
        return "pics/thumbnail/\(id).jpg"
    }
}

// Client card instance in a duel
class ClientCard: ObservableObject, Identifiable {
    let id = UUID()
    var code: Int64
    var position: CardPosition = .faceDownDefense
    var location: CardLocation = .deck
    var sequence: Int = 0
    var controller: Int = 0
    var owner: Int = 0
    @Published var attack: Int = 0
    @Published var defense: Int = 0
    @Published var level: Int = 0
    @Published var counters: [Int: Int] = [:] // counter type -> count

    // Visual properties
    @Published var isSelected: Bool = false
    @Published var isSelectable: Bool = false
    @Published var isChaining: Bool = false

    // Reference to card data
    var cardData: Card?

    init(code: Int64) {
        self.code = code
    }
}

enum CardPosition: Int {
    case faceUpAttack = 0x1
    case faceDownAttack = 0x2
    case faceUpDefense = 0x4
    case faceDownDefense = 0x8

    var isFaceUp: Bool {
        return self == .faceUpAttack || self == .faceUpDefense
    }

    var isAttack: Bool {
        return self == .faceUpAttack || self == .faceDownAttack
    }
}

enum CardLocation: Int {
    case deck = 0x01
    case hand = 0x02
    case monsterZone = 0x04
    case spellZone = 0x08
    case graveyard = 0x10
    case removed = 0x20
    case extra = 0x40
    case overlay = 0x80
    case onField = 0x0c // monster or spell zone

    var name: String {
        switch self {
        case .deck: return "Deck"
        case .hand: return "Hand"
        case .monsterZone: return "Monster Zone"
        case .spellZone: return "Spell/Trap Zone"
        case .graveyard: return "Graveyard"
        case .removed: return "Banished"
        case .extra: return "Extra Deck"
        case .overlay: return "Overlay"
        case .onField: return "Field"
        }
    }
}
