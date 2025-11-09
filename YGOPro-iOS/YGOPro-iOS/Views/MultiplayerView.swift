//
//  MultiplayerView.swift
//  YGOPro-iOS
//
//  Multiplayer lobby and host browser
//

import SwiftUI

struct MultiplayerView: View {
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var deckManager: DeckManager
    @State private var showingCreateHost = false
    @State private var showingJoinHost = false
    @State private var isScanning = false
    @State private var playerName = "Player"

    var body: some View {
        VStack(spacing: 20) {
            // Player name
            HStack {
                Text("Player Name:")
                    .font(.headline)
                TextField("Enter name", text: $playerName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()

            // Host/Join buttons
            HStack(spacing: 20) {
                Button(action: { showingCreateHost = true }) {
                    VStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.largeTitle)
                        Text("Create Host")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }

                Button(action: {
                    isScanning.toggle()
                    if isScanning {
                        networkManager.startHostDiscovery()
                    } else {
                        networkManager.stopHostDiscovery()
                    }
                }) {
                    VStack {
                        Image(systemName: isScanning ? "stop.circle" : "magnifyingglass")
                            .font(.largeTitle)
                        Text(isScanning ? "Stop Scan" : "Scan LAN")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isScanning ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
            }
            .padding(.horizontal)

            // Available hosts
            VStack(alignment: .leading) {
                Text("Available Games")
                    .font(.headline)
                    .padding(.horizontal)

                if networkManager.availableHosts.isEmpty {
                    Text("No games found. Tap 'Scan LAN' to search.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    List(networkManager.availableHosts) { host in
                        HostRow(host: host)
                            .onTapGesture {
                                joinHost(host)
                            }
                    }
                }
            }

            Spacer()
        }
        .navigationTitle("Multiplayer")
        .sheet(isPresented: $showingCreateHost) {
            CreateHostView(playerName: playerName)
        }
        .onDisappear {
            networkManager.stopHostDiscovery()
        }
    }

    func joinHost(_ host: HostInfo) {
        networkManager.connectToHost(host.address, port: host.port)
        networkManager.sendPlayerInfo(name: playerName)
        // TODO: Navigate to lobby or duel
    }
}

struct HostRow: View {
    let host: HostInfo

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(host.name)
                    .font(.headline)
                Text("\(host.address):\(host.port)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack {
                Image(systemName: "person.fill")
                Text("\(host.players)/\(host.maxPlayers)")
            }
            .foregroundColor(.secondary)

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 5)
    }
}

struct CreateHostView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var deckManager: DeckManager

    let playerName: String
    @State private var hostName = "My Game"
    @State private var port: UInt16 = 7911
    @State private var password = ""
    @State private var selectedDeck: Deck?
    @State private var requirePassword = false

    var body: some View {
        NavigationView {
            Form {
                Section("Host Settings") {
                    TextField("Host Name", text: $hostName)
                    HStack {
                        Text("Port")
                        Spacer()
                        TextField("Port", value: $port, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Password") {
                    Toggle("Require Password", isOn: $requirePassword)
                    if requirePassword {
                        SecureField("Password", text: $password)
                    }
                }

                Section("Deck") {
                    Picker("Select Deck", selection: $selectedDeck) {
                        Text("None").tag(nil as Deck?)
                        ForEach(deckManager.decks) { deck in
                            Text(deck.name).tag(deck as Deck?)
                        }
                    }

                    if let deck = selectedDeck {
                        HStack {
                            Text("Main: \(deck.mainDeck.count)")
                            Text("Extra: \(deck.extraDeck.count)")
                            Text("Side: \(deck.sideDeck.count)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        if !deck.isValid {
                            Text("⚠️ Deck is not valid")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Create Host")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createHost()
                    }
                    .disabled(selectedDeck == nil || !(selectedDeck?.isValid ?? false))
                }
            }
        }
    }

    func createHost() {
        networkManager.createHost(port: port, hostName: hostName, password: password)
        if let deck = selectedDeck {
            networkManager.sendDeckData(deck)
        }
        dismiss()
        // TODO: Navigate to lobby
    }
}

struct ReplayView: View {
    var body: some View {
        VStack {
            Image(systemName: "play.circle")
                .font(.system(size: 100))
                .foregroundColor(.gray)
            Text("Replay feature coming soon")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Replays")
    }
}

struct SettingsView: View {
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("musicEnabled") private var musicEnabled = true
    @AppStorage("soundVolume") private var soundVolume = 0.7
    @AppStorage("autoChain") private var autoChain = true

    var body: some View {
        Form {
            Section("Audio") {
                Toggle("Sound Effects", isOn: $soundEnabled)
                Toggle("Music", isOn: $musicEnabled)
                HStack {
                    Text("Volume")
                    Slider(value: $soundVolume, in: 0...1)
                    Text("\(Int(soundVolume * 100))%")
                        .frame(width: 50)
                }
            }

            Section("Gameplay") {
                Toggle("Auto Chain", isOn: $autoChain)
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text("iOS SwiftUI + SceneKit")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    MultiplayerView()
        .environmentObject(NetworkManager.shared)
        .environmentObject(DeckManager.shared)
}
