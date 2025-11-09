//
//  DuelFieldScene.swift
//  YGOPro-iOS
//
//  SceneKit scene for 3D duel field rendering
//

import SceneKit
import SwiftUI

class DuelFieldScene: SCNScene {
    // Camera
    private var cameraNode: SCNNode!

    // Field nodes
    private var playerFieldNode: SCNNode!
    private var opponentFieldNode: SCNNode!

    // Zone nodes
    private var playerMonsterZones: [SCNNode] = []
    private var playerSpellZones: [SCNNode] = []
    private var opponentMonsterZones: [SCNNode] = []
    private var opponentSpellZones: [SCNNode] = []

    // Card nodes
    private var cardNodes: [String: CardNode] = [:]

    override init() {
        super.init()
        setupScene()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupScene()
    }

    private func setupScene() {
        // Add lighting
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.6, alpha: 1.0)
        rootNode.addChildNode(ambientLight)

        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.color = UIColor.white
        directionalLight.position = SCNVector3(x: 0, y: 10, z: 10)
        directionalLight.eulerAngles = SCNVector3(x: -.pi / 4, y: 0, z: 0)
        rootNode.addChildNode(directionalLight)

        // Setup camera
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 15, z: 12)
        cameraNode.eulerAngles = SCNVector3(x: -.pi / 3, y: 0, z: 0)
        rootNode.addChildNode(cameraNode)

        // Create field
        createField()
        createZones()
    }

    private func createField() {
        // Create field plane
        let fieldGeometry = SCNPlane(width: 24, height: 16)
        fieldGeometry.firstMaterial?.diffuse.contents = UIColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1.0)
        fieldGeometry.firstMaterial?.specular.contents = UIColor(white: 0.2, alpha: 1.0)

        let fieldNode = SCNNode(geometry: fieldGeometry)
        fieldNode.eulerAngles = SCNVector3(x: -.pi / 2, y: 0, z: 0)
        fieldNode.position = SCNVector3(x: 0, y: 0, z: 0)
        rootNode.addChildNode(fieldNode)

        // Create player field container
        playerFieldNode = SCNNode()
        playerFieldNode.position = SCNVector3(x: 0, y: 0.01, z: 4)
        rootNode.addChildNode(playerFieldNode)

        // Create opponent field container
        opponentFieldNode = SCNNode()
        opponentFieldNode.position = SCNVector3(x: 0, y: 0.01, z: -4)
        opponentFieldNode.eulerAngles = SCNVector3(x: 0, y: .pi, z: 0)
        rootNode.addChildNode(opponentFieldNode)
    }

    private func createZones() {
        // Player zones
        playerMonsterZones = createZoneRow(parent: playerFieldNode, z: 0, count: 5, color: UIColor(red: 0.3, green: 0.1, blue: 0.1, alpha: 0.5))
        playerSpellZones = createZoneRow(parent: playerFieldNode, z: 2, count: 5, color: UIColor(red: 0.1, green: 0.3, blue: 0.1, alpha: 0.5))

        // Opponent zones
        opponentMonsterZones = createZoneRow(parent: opponentFieldNode, z: 0, count: 5, color: UIColor(red: 0.3, green: 0.1, blue: 0.1, alpha: 0.5))
        opponentSpellZones = createZoneRow(parent: opponentFieldNode, z: 2, count: 5, color: UIColor(red: 0.1, green: 0.3, blue: 0.1, alpha: 0.5))
    }

    private func createZoneRow(parent: SCNNode, z: Float, count: Int, color: UIColor) -> [SCNNode] {
        var zones: [SCNNode] = []
        let spacing: Float = 2.5
        let startX = -Float(count - 1) * spacing / 2

        for i in 0..<count {
            let zoneGeometry = SCNPlane(width: 2.0, height: 2.8)
            zoneGeometry.firstMaterial?.diffuse.contents = color
            zoneGeometry.firstMaterial?.transparency = 0.3

            let zoneNode = SCNNode(geometry: zoneGeometry)
            zoneNode.eulerAngles = SCNVector3(x: -.pi / 2, y: 0, z: 0)
            zoneNode.position = SCNVector3(x: startX + Float(i) * spacing, y: 0, z: z)
            parent.addChildNode(zoneNode)
            zones.append(zoneNode)
        }

        return zones
    }

    // Add card to field
    func addCard(_ card: ClientCard, to location: CardLocation, sequence: Int, controller: Int) {
        let cardNode = CardNode(card: card)
        let key = "\(controller)-\(location.rawValue)-\(sequence)"
        cardNodes[key] = cardNode

        var zones: [SCNNode]
        switch (location, controller) {
        case (.monsterZone, 0):
            zones = playerMonsterZones
        case (.spellZone, 0):
            zones = playerSpellZones
        case (.monsterZone, 1):
            zones = opponentMonsterZones
        case (.spellZone, 1):
            zones = opponentSpellZones
        default:
            return
        }

        guard sequence < zones.count else { return }
        let zoneNode = zones[sequence]
        zoneNode.addChildNode(cardNode)
        cardNode.position = SCNVector3(x: 0, y: 0.1, z: 0)

        // Animate card placement
        cardNode.opacity = 0
        cardNode.scale = SCNVector3(0.1, 0.1, 0.1)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        cardNode.opacity = 1
        cardNode.scale = SCNVector3(1, 1, 1)
        SCNTransaction.commit()
    }

    func removeCard(from location: CardLocation, sequence: Int, controller: Int) {
        let key = "\(controller)-\(location.rawValue)-\(sequence)"
        if let cardNode = cardNodes[key] {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            SCNTransaction.completionBlock = {
                cardNode.removeFromParentNode()
            }
            cardNode.opacity = 0
            cardNode.scale = SCNVector3(0.1, 0.1, 0.1)
            SCNTransaction.commit()
            cardNodes[key] = nil
        }
    }

    func updateCardPosition(_ card: ClientCard, position: CardPosition, at location: CardLocation, sequence: Int, controller: Int) {
        let key = "\(controller)-\(location.rawValue)-\(sequence)"
        guard let cardNode = cardNodes[key] else { return }

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3

        if position.isAttack {
            cardNode.eulerAngles = SCNVector3(x: -.pi / 2, y: 0, z: 0)
        } else {
            cardNode.eulerAngles = SCNVector3(x: -.pi / 2, y: 0, z: .pi / 2)
        }

        if !position.isFaceUp {
            cardNode.showBack()
        } else {
            cardNode.showFront()
        }

        SCNTransaction.commit()
    }
}

// Individual card node
class CardNode: SCNNode {
    private let card: ClientCard
    private var frontNode: SCNNode!
    private var backNode: SCNNode!

    init(card: ClientCard) {
        self.card = card
        super.init()
        setupCard()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCard() {
        // Card dimensions (Yu-Gi-Oh! cards are 59mm x 86mm, aspect ratio ~1.46)
        let width: CGFloat = 1.8
        let height: CGFloat = 2.6
        let thickness: CGFloat = 0.02

        // Create card box
        let box = SCNBox(width: width, height: height, length: thickness, chamferRadius: 0.05)

        // Front face (card image)
        let frontMaterial = SCNMaterial()
        if let imagePath = Bundle.main.path(forResource: "\(card.code)", ofType: "jpg", inDirectory: "pics") {
            frontMaterial.diffuse.contents = UIImage(contentsOfFile: imagePath)
        } else {
            // Placeholder if image not found
            frontMaterial.diffuse.contents = UIColor(red: 0.2, green: 0.2, blue: 0.5, alpha: 1.0)
        }
        frontMaterial.specular.contents = UIColor(white: 0.3, alpha: 1.0)

        // Back face (card back)
        let backMaterial = SCNMaterial()
        if let backPath = Bundle.main.path(forResource: "card-back", ofType: "jpg", inDirectory: "textures") {
            backMaterial.diffuse.contents = UIImage(contentsOfFile: backPath)
        } else {
            backMaterial.diffuse.contents = UIColor(red: 0.5, green: 0.2, blue: 0.2, alpha: 1.0)
        }

        // Side materials (edge of card)
        let edgeMaterial = SCNMaterial()
        edgeMaterial.diffuse.contents = UIColor(white: 0.9, alpha: 1.0)

        // Assign materials (right, left, top, bottom, front, back)
        box.materials = [edgeMaterial, edgeMaterial, edgeMaterial, edgeMaterial, frontMaterial, backMaterial]

        geometry = box

        // Add subtle glow for selected cards
        if card.isSelected {
            let glowMaterial = SCNMaterial()
            glowMaterial.emission.contents = UIColor(red: 1.0, green: 1.0, blue: 0.5, alpha: 0.3)
            geometry?.insertMaterial(glowMaterial, at: 0)
        }
    }

    func showFront() {
        // Rotate to show front
        eulerAngles = SCNVector3(x: -.pi / 2, y: 0, z: 0)
    }

    func showBack() {
        // Rotate to show back
        eulerAngles = SCNVector3(x: .pi / 2, y: 0, z: 0)
    }

    func flip() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        if eulerAngles.x < 0 {
            showBack()
        } else {
            showFront()
        }
        SCNTransaction.commit()
    }
}
