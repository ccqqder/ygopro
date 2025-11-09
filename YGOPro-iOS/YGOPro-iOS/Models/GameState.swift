//
//  GameState.swift
//  YGOPro-iOS
//
//  Game state management for duels
//

import Foundation
import Combine

class GameManager: ObservableObject {
    static let shared = GameManager()

    @Published var currentGame: GameState?
    @Published var gameMode: GameMode = .none
    @Published var isInDuel: Bool = false

    enum GameMode {
        case none
        case singleDuel // Online 1v1
        case tagDuel    // 4-player team
        case singleMode // AI or puzzle
        case replay     // Replay viewing
    }

    private init() {}

    func startDuel(mode: GameMode, deck: Deck) {
        gameMode = mode
        currentGame = GameState(deck: deck)
        isInDuel = true
    }

    func endDuel() {
        isInDuel = false
        currentGame = nil
        gameMode = .none
    }
}

class GameState: ObservableObject {
    @Published var player: PlayerState
    @Published var opponent: PlayerState
    @Published var currentPhase: Phase = .draw
    @Published var currentPlayer: Int = 0
    @Published var turnCount: Int = 0
    @Published var chainStack: [ChainLink] = []

    // Field zones
    @Published var playerField: FieldState
    @Published var opponentField: FieldState

    let deck: Deck

    init(deck: Deck) {
        self.deck = deck
        self.player = PlayerState(name: "You")
        self.opponent = PlayerState(name: "Opponent")
        self.playerField = FieldState()
        self.opponentField = FieldState()
    }

    enum Phase: String {
        case draw = "Draw Phase"
        case standby = "Standby Phase"
        case main1 = "Main Phase 1"
        case battle = "Battle Phase"
        case main2 = "Main Phase 2"
        case end = "End Phase"
    }
}

class PlayerState: ObservableObject {
    let name: String
    @Published var lifePoints: Int = 8000
    @Published var deckCount: Int = 0
    @Published var extraDeckCount: Int = 0

    init(name: String) {
        self.name = name
    }
}

class FieldState: ObservableObject {
    // Monster zones (0-6, where 5-6 are for link format)
    @Published var monsterZone: [ClientCard?] = Array(repeating: nil, count: 7)

    // Spell/Trap zones (0-4)
    @Published var spellZone: [ClientCard?] = Array(repeating: nil, count: 5)

    // Field spell
    @Published var fieldCard: ClientCard?

    // Pendulum zones
    @Published var pendulumLeft: ClientCard?
    @Published var pendulumRight: ClientCard?

    // Graveyard
    @Published var graveyard: [ClientCard] = []

    // Banished zone
    @Published var banished: [ClientCard] = []

    // Hand
    @Published var hand: [ClientCard] = []

    // Extra deck
    @Published var extraDeck: [ClientCard] = []

    func cardAt(location: CardLocation, sequence: Int) -> ClientCard? {
        switch location {
        case .monsterZone:
            guard sequence < monsterZone.count else { return nil }
            return monsterZone[sequence]
        case .spellZone:
            guard sequence < spellZone.count else { return nil }
            return spellZone[sequence]
        case .hand:
            guard sequence < hand.count else { return nil }
            return hand[sequence]
        case .graveyard:
            guard sequence < graveyard.count else { return nil }
            return graveyard[sequence]
        default:
            return nil
        }
    }

    func setCard(_ card: ClientCard?, at location: CardLocation, sequence: Int) {
        switch location {
        case .monsterZone:
            guard sequence < monsterZone.count else { return }
            monsterZone[sequence] = card
        case .spellZone:
            guard sequence < spellZone.count else { return }
            spellZone[sequence] = card
        default:
            break
        }
    }
}

struct ChainLink {
    let card: ClientCard
    let player: Int
    let description: String
}
