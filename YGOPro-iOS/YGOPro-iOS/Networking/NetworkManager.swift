//
//  NetworkManager.swift
//  YGOPro-iOS
//
//  Network manager for multiplayer functionality
//

import Foundation
import Network
import Combine

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()

    @Published var isConnected: Bool = false
    @Published var availableHosts: [HostInfo] = []
    @Published var connectionState: ConnectionState = .disconnected

    private var connection: NWConnection?
    private var listener: NWListener?
    private var udpListener: NWListener? // For host discovery

    enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case error(String)
    }

    private init() {}

    // MARK: - Client Functions

    func connectToHost(_ host: String, port: UInt16, password: String = "") {
        connectionState = .connecting

        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host),
                                          port: NWEndpoint.Port(integerLiteral: port))

        connection = NWConnection(to: endpoint, using: .tcp)

        connection?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.connectionState = .connected
                    self?.isConnected = true
                    self?.startReceiving()
                case .failed(let error):
                    self?.connectionState = .error(error.localizedDescription)
                    self?.isConnected = false
                case .waiting(let error):
                    self?.connectionState = .error("Waiting: \(error.localizedDescription)")
                default:
                    break
                }
            }
        }

        connection?.start(queue: .global())
    }

    func disconnect() {
        connection?.cancel()
        connection = nil
        isConnected = false
        connectionState = .disconnected
    }

    func sendPacket(_ data: Data) {
        connection?.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                print("Send error: \(error)")
            }
        }))
    }

    private func startReceiving() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.handleReceivedData(data)
            }

            if isComplete {
                self?.disconnect()
            } else if error == nil {
                self?.startReceiving()
            }
        }
    }

    private func handleReceivedData(_ data: Data) {
        // Parse STOC (Server-To-Client) packets
        // This would implement the same protocol as the C++ version
        // Format: [length: 2 bytes][type: 1 byte][data: variable]

        guard data.count >= 3 else { return }

        let length = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: UInt16.self) }
        let type = data[2]

        let packetData = data.subdata(in: 3..<min(Int(length) + 2, data.count))

        DispatchQueue.main.async {
            self.processPacket(type: type, data: packetData)
        }
    }

    private func processPacket(type: UInt8, data: Data) {
        // Implement packet processing based on packet type
        // This would handle game messages, updates, etc.
        switch type {
        case 0x01: // STOC_GameMsg
            handleGameMessage(data)
        case 0x02: // STOC_ErrorMsg
            handleErrorMessage(data)
        case 0x03: // STOC_SelectHand
            break
        case 0x04: // STOC_SelectTP
            break
        case 0x11: // STOC_DuelStart
            GameManager.shared.isInDuel = true
        case 0x12: // STOC_DuelEnd
            GameManager.shared.endDuel()
        default:
            break
        }
    }

    private func handleGameMessage(_ data: Data) {
        // Process game state updates
        // This would update GameManager.shared.currentGame
    }

    private func handleErrorMessage(_ data: Data) {
        // Display error to user
        if let message = String(data: data, encoding: .utf8) {
            connectionState = .error(message)
        }
    }

    // MARK: - Host Discovery

    func startHostDiscovery() {
        // Start UDP broadcast listener for LAN host discovery
        do {
            udpListener = try NWListener(using: .udp, on: 7911)

            udpListener?.newConnectionHandler = { [weak self] connection in
                connection.start(queue: .global())
                self?.receiveHostBroadcast(on: connection)
            }

            udpListener?.start(queue: .global())
        } catch {
            print("Failed to start host discovery: \(error)")
        }
    }

    func stopHostDiscovery() {
        udpListener?.cancel()
        udpListener = nil
        availableHosts = []
    }

    private func receiveHostBroadcast(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, _, _ in
            guard let data = data, data.count >= 72 else { return }

            // Parse host packet (72 bytes - same as C++ version)
            let hostInfo = self?.parseHostPacket(data)

            DispatchQueue.main.async {
                if let info = hostInfo {
                    self?.availableHosts.append(info)
                }
            }
        }
    }

    private func parseHostPacket(_ data: Data) -> HostInfo? {
        // Parse the 72-byte host packet structure
        guard data.count >= 72 else { return nil }

        var offset = 0

        // Parse IP (16 bytes)
        let ipData = data.subdata(in: offset..<offset+16)
        offset += 16

        // Parse port (2 bytes)
        let port = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt16.self) }
        offset += 2

        // Parse host name (20 bytes, null-terminated)
        let nameData = data.subdata(in: offset..<offset+20)
        let name = String(data: nameData, encoding: .utf16LittleEndian)?.trimmingCharacters(in: .controlCharacters) ?? "Unknown"
        offset += 20

        return HostInfo(name: name, address: "", port: port)
    }

    // MARK: - Server Functions

    func createHost(port: UInt16, hostName: String, password: String = "") {
        do {
            listener = try NWListener(using: .tcp, on: NWEndpoint.Port(integerLiteral: port))

            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewClient(connection)
            }

            listener?.start(queue: .global())

            // Start broadcasting host info via UDP
            broadcastHostInfo(port: port, name: hostName)
        } catch {
            print("Failed to create host: \(error)")
        }
    }

    func stopHost() {
        listener?.cancel()
        listener = nil
    }

    private func handleNewClient(_ connection: NWConnection) {
        connection.start(queue: .global())
        // Handle client connection
        // This would manage game state and relay messages between clients
    }

    private func broadcastHostInfo(port: UInt16, name: String) {
        // Broadcast host information via UDP
        // This allows clients to discover the game via LAN
    }
}

// MARK: - Supporting Types

struct HostInfo: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let port: UInt16
    var players: Int = 0
    var maxPlayers: Int = 2
}

// Packet builders for CTOS (Client-To-Server) messages
extension NetworkManager {
    func sendPlayerInfo(name: String) {
        var data = Data()
        // CTOS_PlayerInfo packet
        data.append(contentsOf: [0x10]) // packet type
        data.append(name.data(using: .utf16LittleEndian) ?? Data())
        sendPacket(data)
    }

    func sendJoinGame(password: String = "") {
        var data = Data()
        // CTOS_JoinGame packet
        data.append(contentsOf: [0x12])
        // Add version and password
        sendPacket(data)
    }

    func sendDeckData(_ deck: Deck) {
        var data = Data()
        // CTOS_UpdateDeck packet
        data.append(contentsOf: [0x02])

        // Main deck
        for cardID in deck.mainDeck {
            var id = UInt32(cardID)
            data.append(Data(bytes: &id, count: 4))
        }
        // Extra deck
        for cardID in deck.extraDeck {
            var id = UInt32(cardID)
            data.append(Data(bytes: &id, count: 4))
        }
        // Side deck
        for cardID in deck.sideDeck {
            var id = UInt32(cardID)
            data.append(Data(bytes: &id, count: 4))
        }

        sendPacket(data)
    }

    func sendResponse(_ response: UInt8) {
        var data = Data()
        data.append(contentsOf: [0x01]) // CTOS_Response
        data.append(response)
        sendPacket(data)
    }
}
