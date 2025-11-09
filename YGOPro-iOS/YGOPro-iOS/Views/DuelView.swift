//
//  DuelView.swift
//  YGOPro-iOS
//
//  Main duel view with 3D field
//

import SwiftUI
import SceneKit

struct DuelView: View {
    @EnvironmentObject var gameManager: GameManager
    @StateObject private var sceneController = DuelSceneController()
    @State private var showMenu = false
    @State private var selectedCard: ClientCard?

    var body: some View {
        ZStack {
            // 3D Field View
            SceneView(
                scene: sceneController.scene,
                options: [.allowsCameraControl, .autoenablesDefaultLighting]
            )
            .ignoresSafeArea()

            VStack {
                // Top HUD
                HStack {
                    // Opponent info
                    PlayerInfoView(player: gameManager.currentGame?.opponent ?? PlayerState(name: "Opponent"),
                                 isOpponent: true)
                    Spacer()
                    // Menu button
                    Button(action: { showMenu.toggle() }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                }
                .padding()

                Spacer()

                // Phase indicator
                if let phase = gameManager.currentGame?.currentPhase {
                    Text(phase.rawValue)
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.7)))
                        .foregroundColor(.white)
                }

                Spacer()

                // Bottom HUD
                HStack {
                    // Player info
                    PlayerInfoView(player: gameManager.currentGame?.player ?? PlayerState(name: "You"),
                                 isOpponent: false)
                    Spacer()
                    // Action buttons
                    HStack(spacing: 15) {
                        ActionButton(icon: "arrow.right.circle.fill", label: "Next")
                        ActionButton(icon: "xmark.circle.fill", label: "Cancel")
                    }
                }
                .padding()
            }

            // Card detail overlay
            if let card = selectedCard {
                CardDetailOverlay(card: card, onDismiss: { selectedCard = nil })
            }

            // Menu overlay
            if showMenu {
                DuelMenuOverlay(isPresented: $showMenu)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Initialize duel if not already started
            if gameManager.currentGame == nil {
                // TODO: Select deck
                let sampleDeck = Deck(name: "Sample")
                gameManager.startDuel(mode: .singleDuel, deck: sampleDeck)
            }
        }
    }
}

struct PlayerInfoView: View {
    let player: PlayerState
    let isOpponent: Bool

    var body: some View {
        VStack(alignment: isOpponent ? .leading : .trailing, spacing: 5) {
            Text(player.name)
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 5) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("\(player.lifePoints)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            HStack(spacing: 10) {
                Label("\(player.deckCount)", systemImage: "rectangle.stack")
                Label("\(player.extraDeckCount)", systemImage: "star.fill")
            }
            .font(.caption)
            .foregroundColor(.white)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.6))
        )
    }
}

struct ActionButton: View {
    let icon: String
    let label: String

    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title)
            Text(label)
                .font(.caption)
        }
        .foregroundColor(.white)
        .padding()
        .background(Circle().fill(Color.blue.opacity(0.7)))
    }
}

struct CardDetailOverlay: View {
    let card: ClientCard
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack {
                if let cardData = card.cardData {
                    VStack(spacing: 20) {
                        // Card image
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 300)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(10)

                        // Card info
                        VStack(alignment: .leading, spacing: 10) {
                            Text(cardData.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(cardData.cardTypeName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            if cardData.isMonster {
                                HStack {
                                    Text("\(cardData.attributeName) | \(cardData.raceName)")
                                    Spacer()
                                    Text("ATK/\(cardData.atk) DEF/\(cardData.def)")
                                }
                                .font(.caption)
                            }

                            Text(cardData.desc)
                                .font(.body)
                                .padding(.top, 5)
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .frame(maxWidth: 500)
        }
    }
}

struct DuelMenuOverlay: View {
    @Binding isPresented: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 20) {
                Text("Duel Menu")
                    .font(.title)
                    .fontWeight(.bold)

                Button("Resume") {
                    isPresented = false
                }
                .buttonStyle(MenuButtonStyle())

                Button("Surrender") {
                    // TODO: Implement surrender
                    dismiss()
                }
                .buttonStyle(MenuButtonStyle())

                Button("Settings") {
                    // TODO: Show settings
                }
                .buttonStyle(MenuButtonStyle())
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground))
            )
            .padding()
        }
    }
}

struct MenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

class DuelSceneController: ObservableObject {
    let scene: DuelFieldScene

    init() {
        scene = DuelFieldScene()
    }
}

#Preview {
    DuelView()
        .environmentObject(GameManager.shared)
}
