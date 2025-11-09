//
//  YGOProApp.swift
//  YGOPro-iOS
//
//  Main entry point for the YGOPro iOS application
//  Implements Yu-Gi-Oh! card game client using SwiftUI and SceneKit
//

import SwiftUI

@main
struct YGOProApp: App {
    @StateObject private var gameManager = GameManager.shared
    @StateObject private var networkManager = NetworkManager.shared
    @StateObject private var deckManager = DeckManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager)
                .environmentObject(networkManager)
                .environmentObject(deckManager)
                .preferredColorScheme(.dark)
        }
    }
}
