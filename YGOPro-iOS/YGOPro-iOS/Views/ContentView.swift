//
//  ContentView.swift
//  YGOPro-iOS
//
//  Main menu view
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showDeckEditor = false
    @State private var showMultiplayer = false
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    // Title
                    Text("YGOPro")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 10)

                    VStack(spacing: 20) {
                        // Single Duel Button
                        NavigationLink(destination: DuelView()) {
                            MenuButton(title: "Single Duel", icon: "person.2.fill")
                        }

                        // Deck Editor Button
                        NavigationLink(destination: DeckEditorView()) {
                            MenuButton(title: "Deck Editor", icon: "rectangle.stack.fill")
                        }

                        // Multiplayer Button
                        NavigationLink(destination: MultiplayerView()) {
                            MenuButton(title: "Multiplayer", icon: "network")
                        }

                        // Replay Button
                        NavigationLink(destination: ReplayView()) {
                            MenuButton(title: "Replays", icon: "play.circle.fill")
                        }

                        // Settings Button
                        NavigationLink(destination: SettingsView()) {
                            MenuButton(title: "Settings", icon: "gearshape.fill")
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MenuButton: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 40)

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.title3)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.2))
                .shadow(radius: 5)
        )
        .foregroundColor(.white)
        .padding(.horizontal)
    }
}

#Preview {
    ContentView()
        .environmentObject(GameManager.shared)
        .environmentObject(NetworkManager.shared)
        .environmentObject(DeckManager.shared)
}
