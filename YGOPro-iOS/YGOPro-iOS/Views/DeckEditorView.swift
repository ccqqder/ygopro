//
//  DeckEditorView.swift
//  YGOPro-iOS
//
//  Deck editor interface
//

import SwiftUI

struct DeckEditorView: View {
    @EnvironmentObject var deckManager: DeckManager
    @State private var selectedDeck: Deck?
    @State private var showingNewDeckSheet = false
    @State private var searchText = ""
    @State private var selectedSection: DeckSection = .main

    enum DeckSection: String, CaseIterable {
        case main = "Main Deck"
        case extra = "Extra Deck"
        case side = "Side Deck"
    }

    var body: some View {
        NavigationView {
            VStack {
                // Deck selector
                if selectedDeck == nil {
                    deckListView
                } else {
                    deckEditorView
                }
            }
            .navigationTitle("Deck Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if selectedDeck != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") {
                            selectedDeck = nil
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            if let deck = selectedDeck {
                                deckManager.saveDeck(deck)
                            }
                        }
                    }
                }
            }
        }
    }

    var deckListView: some View {
        VStack {
            List {
                ForEach(deckManager.decks) { deck in
                    DeckRow(deck: deck)
                        .onTapGesture {
                            selectedDeck = deck
                        }
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        deckManager.deleteDeck(deckManager.decks[index])
                    }
                }
            }

            Button(action: { showingNewDeckSheet = true }) {
                Label("New Deck", systemImage: "plus.circle.fill")
                    .font(.title3)
                    .padding()
            }
        }
        .sheet(isPresented: $showingNewDeckSheet) {
            NewDeckSheet(isPresented: $showingNewDeckSheet) { deckName in
                let newDeck = deckManager.createNewDeck(name: deckName)
                selectedDeck = newDeck
            }
        }
    }

    var deckEditorView: some View {
        VStack {
            // Deck info
            if let deck = selectedDeck {
                DeckInfoBar(deck: deck)

                // Section selector
                Picker("Section", selection: $selectedSection) {
                    ForEach(DeckSection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // Current deck cards
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                        ForEach(getCurrentSectionCards(deck), id: \.self) { cardID in
                            if let card = DatabaseManager.shared.getCard(id: cardID) {
                                CardThumbnailView(card: card)
                                    .onTapGesture {
                                        removeCard(cardID, from: selectedSection)
                                    }
                            }
                        }
                    }
                    .padding()
                }
                .frame(height: 200)
                .background(Color.gray.opacity(0.1))

                Divider()

                // Card search and database
                CardSearchView(onCardSelected: { card in
                    addCard(card.id, to: selectedSection)
                })
            }
        }
    }

    func getCurrentSectionCards(_ deck: Deck) -> [Int64] {
        switch selectedSection {
        case .main: return deck.mainDeck
        case .extra: return deck.extraDeck
        case .side: return deck.sideDeck
        }
    }

    func addCard(_ cardID: Int64, to section: DeckSection) {
        guard var deck = selectedDeck else { return }
        switch section {
        case .main:
            if deck.mainDeck.count < 60 {
                deck.mainDeck.append(cardID)
            }
        case .extra:
            if deck.extraDeck.count < 15 {
                deck.extraDeck.append(cardID)
            }
        case .side:
            if deck.sideDeck.count < 15 {
                deck.sideDeck.append(cardID)
            }
        }
        selectedDeck = deck
    }

    func removeCard(_ cardID: Int64, from section: DeckSection) {
        guard var deck = selectedDeck else { return }
        switch section {
        case .main:
            if let index = deck.mainDeck.firstIndex(of: cardID) {
                deck.mainDeck.remove(at: index)
            }
        case .extra:
            if let index = deck.extraDeck.firstIndex(of: cardID) {
                deck.extraDeck.remove(at: index)
            }
        case .side:
            if let index = deck.sideDeck.firstIndex(of: cardID) {
                deck.sideDeck.remove(at: index)
            }
        }
        selectedDeck = deck
    }
}

struct DeckRow: View {
    let deck: Deck

    var body: some View {
        VStack(alignment: .leading) {
            Text(deck.name)
                .font(.headline)
            HStack {
                Label("\(deck.mainDeck.count)", systemImage: "rectangle.stack")
                Label("\(deck.extraDeck.count)", systemImage: "star")
                Label("\(deck.sideDeck.count)", systemImage: "tray")
                Spacer()
                if deck.isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 5)
    }
}

struct DeckInfoBar: View {
    let deck: Deck

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(deck.name)
                    .font(.title3)
                    .fontWeight(.bold)
                HStack {
                    Text("Main: \(deck.mainDeck.count)")
                    Text("Extra: \(deck.extraDeck.count)")
                    Text("Side: \(deck.sideDeck.count)")
                }
                .font(.caption)
            }
            Spacer()
            if deck.isValid {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.green)
                    .font(.title)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
    }
}

struct CardSearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [Card] = []
    let onCardSelected: (Card) -> Void

    var body: some View {
        VStack {
            TextField("Search cards...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: searchText) { _, newValue in
                    if newValue.isEmpty {
                        searchResults = Array(DatabaseManager.shared.getAllCards().prefix(50))
                    } else {
                        searchResults = DatabaseManager.shared.searchCards(query: newValue)
                    }
                }

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                    ForEach(searchResults) { card in
                        CardThumbnailView(card: card)
                            .onTapGesture {
                                onCardSelected(card)
                            }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            searchResults = Array(DatabaseManager.shared.getAllCards().prefix(50))
        }
    }
}

struct CardThumbnailView: View {
    let card: Card

    var body: some View {
        VStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(59.0/86.0, contentMode: .fit)
                .overlay(
                    Text(String(card.id))
                        .font(.caption2)
                        .foregroundColor(.white)
                )
                .cornerRadius(5)

            Text(card.name)
                .font(.caption2)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80)
    }
}

struct NewDeckSheet: View {
    @Binding var isPresented: Bool
    @State private var deckName = ""
    let onCreate: (String) -> Void

    var body: some View {
        NavigationView {
            Form {
                TextField("Deck Name", text: $deckName)
            }
            .navigationTitle("New Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        if !deckName.isEmpty {
                            onCreate(deckName)
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    DeckEditorView()
        .environmentObject(DeckManager.shared)
}
