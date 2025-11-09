# YGOPro iOS - SwiftUI + SceneKit Implementation

An iOS implementation of YGOPro (Yu-Gi-Oh! Pro) trading card game client using SwiftUI for the interface and SceneKit for 3D card rendering.

## Features

### Implemented
- ✅ **3D Card Rendering** - SceneKit-based 3D visualization of the duel field
- ✅ **Deck Editor** - Full deck building interface with card search
- ✅ **Multiplayer Networking** - LAN multiplayer with host discovery
- ✅ **Game State Management** - Complete game state tracking
- ✅ **Card Database** - SQLite database integration
- ✅ **SwiftUI Interface** - Modern, native iOS UI

### Architecture

```
YGOPro-iOS/
├── Models/
│   ├── Card.swift              # Card data model and client instances
│   ├── Deck.swift              # Deck management and ban list
│   ├── GameState.swift         # Game state and field management
│   └── DeckManager.swift       # Deck persistence
├── Views/
│   ├── ContentView.swift       # Main menu
│   ├── DuelView.swift          # 3D duel field view
│   ├── DeckEditorView.swift    # Deck building interface
│   └── MultiplayerView.swift   # Multiplayer lobby
├── SceneKit/
│   └── DuelFieldScene.swift    # 3D scene rendering
├── Networking/
│   └── NetworkManager.swift    # Network communication
├── Database/
│   └── DatabaseManager.swift   # SQLite card database
└── YGOProApp.swift             # App entry point
```

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Building

### Prerequisites

1. Xcode 15 or later
2. iOS 16+ device or simulator
3. Card database (`cards.cdb`) - place in app bundle or documents directory
4. Card images (optional) - place in `pics/` directory

### Build Steps

1. Open `YGOPro-iOS.xcodeproj` in Xcode
2. Select your target device/simulator
3. Build and run (⌘R)

## Project Structure

### Core Components

#### Models
- **Card**: Represents Yu-Gi-Oh! cards with all attributes (ATK/DEF, type, race, etc.)
- **ClientCard**: Runtime card instances in duels with position, location, and visual state
- **Deck**: Deck structure with main/extra/side decks and validation
- **GameState**: Complete game state including player info, field zones, and phase management

#### Views
- **ContentView**: Main menu with navigation to all features
- **DuelView**: 3D duel field with SceneKit integration
- **DeckEditorView**: Deck building with card search and collection management
- **MultiplayerView**: LAN multiplayer with host discovery and connection

#### SceneKit
- **DuelFieldScene**: 3D scene with field zones, card nodes, and animations
- **CardNode**: Individual 3D card representation with flip animations

#### Networking
- **NetworkManager**: Handles TCP/UDP communication using Apple's Network framework
- Compatible with original YGOPro protocol (CTOS/STOC packets)

#### Database
- **DatabaseManager**: SQLite integration for card data
- Loads card information from `cards.cdb`

## Features in Detail

### 3D Duel Field
- SceneKit-based 3D rendering
- Realistic card placement and zones
- Card flip animations
- Position changes (attack/defense)
- Camera controls for viewing field

### Deck Editor
- Search cards by name/text
- Filter by type, attribute, race
- Drag and drop card management
- Ban list validation
- Import/export .ydk format
- Visual deck composition display

### Multiplayer
- LAN host discovery via UDP broadcast
- TCP connections for game data
- Compatible with desktop YGOPro protocol
- Host creation with customizable settings
- Password-protected games

### Game State Management
- Complete field state tracking
- Monster zones (7 slots for Link format)
- Spell/Trap zones (5 slots)
- Pendulum zones
- Graveyard, banished, extra deck
- Hand management
- Chain stack tracking

## Network Protocol

The iOS implementation uses the same network protocol as the desktop version:

### CTOS (Client-To-Server) Packets
- `0x01` - Response
- `0x02` - UpdateDeck
- `0x10` - PlayerInfo
- `0x12` - JoinGame

### STOC (Server-To-Client) Packets
- `0x01` - GameMsg
- `0x02` - ErrorMsg
- `0x11` - DuelStart
- `0x12` - DuelEnd

## Database Format

Card database (`cards.cdb`) structure:
- **datas** table: Card statistics (ATK, DEF, type, etc.)
- **texts** table: Card names and descriptions

## Asset Requirements

### Required
- `cards.cdb` - Card database file

### Optional
- `pics/*.jpg` - Card images (177×254 pixels)
- `pics/thumbnail/*.jpg` - Card thumbnails (44×64 pixels)
- `textures/card-back.jpg` - Card back image
- `sound/*.wav` - Sound effects
- `sound/*.mp3` - Background music

## Configuration

Game settings are managed via `@AppStorage`:
- Sound effects enable/disable
- Music enable/disable
- Volume control
- Auto-chain settings

## Development Notes

### SwiftUI + SceneKit Integration
The app uses `SceneView` to embed SceneKit scenes within SwiftUI views, providing:
- Native iOS controls and navigation
- 3D rendering for cards and field
- Smooth animations and transitions

### State Management
Uses `@StateObject`, `@ObservedObject`, and `@EnvironmentObject` for reactive state management:
- `GameManager` - Global game state
- `NetworkManager` - Network connections
- `DeckManager` - Deck persistence
- Individual view models for complex views

### Performance Considerations
- Lazy loading of card images
- Efficient SceneKit node management
- Background threading for database operations
- Network operations on global queue

## Known Limitations

- Card images must be provided separately
- Lua script integration not yet implemented (game logic is placeholder)
- AI opponent not implemented
- Replay system is placeholder
- Single player puzzles not implemented

## Future Enhancements

- [ ] Core game logic integration (Lua or Swift port)
- [ ] AI opponent
- [ ] Replay recording and playback
- [ ] Single player puzzles
- [ ] Card collection management
- [ ] Online multiplayer (beyond LAN)
- [ ] Push notifications
- [ ] iCloud deck sync
- [ ] Accessibility improvements
- [ ] Localization

## Compatibility

This iOS app is designed to be compatible with the original YGOPro network protocol, allowing iOS users to play with desktop users on the same LAN.

## License

This is a fan-made project. Yu-Gi-Oh! is a trademark of Konami Digital Entertainment.

## Credits

- Original YGOPro project: https://github.com/Fluorohydride/ygopro
- iOS implementation: SwiftUI + SceneKit port
- Network protocol: Based on original YGOPro specification

---

**Note**: This is a demonstration implementation showing how YGOPro could be built for iOS using modern Apple frameworks. Complete game logic integration would require additional work to port or interface with the existing Lua-based card scripts.
