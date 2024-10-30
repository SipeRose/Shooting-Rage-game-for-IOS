//
//  GameScene.swift
//  Shooting Range
//
//  Created by Никита Волков on 27.10.2024.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let possibleSizes = [20, 40, 80]   // размеры целей
    let possibleYPositions = [60, 180, 300]
    let goalNames = ["goal", "man", "goal"]
    let velocities = [
        20: 400...500,
        40: 250...350,
        80: 200...250
    ]
    var gameTimer: Timer?
    var countTheTime: Timer?
    var isReloading = false
    var isGameOver = false
    
    var scoreLabel: SKLabelNode!
    var bulletsCountLabel: SKLabelNode!
    var timeLabel: SKLabelNode!
    
    var bulletsCount = 6 {
        didSet {
            bulletsCountLabel.text = "Bullets: \(bulletsCount)"
        }
    }
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    var timeInSeconds = 300 {
        didSet {
            if timeInSeconds == 0 {
                stopTheGame()
            }
            let minutes = Int(timeInSeconds / 60)
            let seconds = timeInSeconds % 60
            if seconds < 10 {
                timeLabel.text = "\(minutes):0\(seconds)"
            } else {
                timeLabel.text = "\(minutes):\(seconds)"
            }
        }
    }
    
    
    override func didMove(to view: SKView) {
        
        makeBackground()
        makeBorder(yPosition: 120)
        makeBorder(yPosition: 240)
        makeLabels()
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        makeTimers()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if isGameOver {
                restartTheGame()
            } else if !isReloading {
                if bulletsCount == 0 {
                    reload()
                } else {
                    let location = touch.location(in: self)
                    makeBullet(xPosition: location.x)
                    bulletsCount -= 1
                }
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        for node in children {
            if node.position.y > 360 || node.position.x > 800 {
                node.removeFromParent()
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let firstNode = contact.bodyA.node else { return }
        guard let secondNode = contact.bodyB.node else { return }
        
        if (firstNode.name == "bullet" &&  ["target", "man"].contains(secondNode.name)) || (["target", "man"].contains(firstNode.name) && secondNode.name == "bullet") {
            
            destroy(bullet: firstNode, target: secondNode, contact: contact)
            countThePointsAndMakeSound(firstNode: firstNode, secondNode: secondNode)
            
            firstNode.removeFromParent()
            secondNode.removeFromParent()
        }
    }
}





extension GameScene {
    
    func makeLabels() {
        
        scoreLabel = SKLabelNode()
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontName = "Charter"
        scoreLabel.fontColor = .white
        scoreLabel.fontSize = 30
        scoreLabel.position = CGPoint(x: 90, y: 20)
        scoreLabel.zPosition = 3
        addChild(scoreLabel)
        
        bulletsCountLabel = SKLabelNode()
        bulletsCountLabel.text = "Bullets: \(bulletsCount)"
        bulletsCountLabel.fontName = "Charter"
        bulletsCountLabel.fontColor = .white
        bulletsCountLabel.fontSize = 30
        bulletsCountLabel.position = CGPoint(x: 700, y: 320)
        bulletsCountLabel.zPosition = 3
        addChild(bulletsCountLabel)
        
        timeLabel = SKLabelNode()
        timeLabel.text = "5:00"
        timeLabel.fontName = "Charter"
        timeLabel.fontColor = .white
        timeLabel.fontSize = 30
        timeLabel.position = CGPoint(x: 70, y: 320)
        timeLabel.zPosition = 3
        addChild(timeLabel)
    }
    
    func makeBackground() {
        let image = SKSpriteNode(imageNamed: "wood")
        image.position = CGPoint(x: 390, y: 180)
        image.size = CGSize(width: 780, height: 360)
        image.zPosition = -2
        addChild(image)
    }
    
    func makeBorder(yPosition: Int) {
        let border = SKSpriteNode(color: .systemYellow, size: CGSize(width: 1560, height: 5))
        border.zPosition = -1
        border.position = CGPoint(x: 0, y: yPosition)
        addChild(border)
    }
    
    func makeTimers() {
        countTheTime = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(minusOneSecond), userInfo: nil, repeats: true)
        gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(makeGoal), userInfo: nil, repeats: true)
    }
    
    @objc func minusOneSecond() {
        timeInSeconds -= 1
    }
    
    @objc func makeGoal() {
        
        gameTimer?.invalidate()
        let goal = goalNames.randomElement()!
        let yPosition = possibleYPositions.randomElement()!
        let size: Int
        let xVelocity: Int
        
        if goal == "man" {
            size = 80
            xVelocity = Int.random(in: velocities[80]!)
        } else {
            size = possibleSizes.randomElement()!
            xVelocity = Int.random(in: velocities[size]!)
        }

        if !containsLessVelocity(yPosition: CGFloat(yPosition), velocity: CGFloat(xVelocity)){
            
            let sprite = SKSpriteNode(imageNamed: goal)
            sprite.size = CGSize(width: size, height: size)
            sprite.position = CGPoint(x: -size, y: yPosition)
            if goal == "man" {
                sprite.name = "man"
            } else {
                sprite.name = "target"
            }
            
            sprite.physicsBody = SKPhysicsBody(texture: sprite.texture!, size: sprite.size)
            sprite.physicsBody?.angularVelocity = 0
            sprite.physicsBody?.linearDamping = 0
            sprite.physicsBody?.angularDamping = 0
            sprite.physicsBody?.contactTestBitMask = 1
            sprite.physicsBody?.velocity = CGVector(dx: xVelocity, dy: 0)
            
            addChild(sprite)
        }
        
        makeNewTimer()
    }
    
    func containsLessVelocity(yPosition: CGFloat, velocity: CGFloat) -> Bool {

        for node in children {
            if node.name == "target" || node.name == "man" {
                if round(node.position.y) == yPosition && (node.physicsBody?.velocity.dx)! < velocity {
                    return true
                }
            }
        }
        return false
    }
    
    func makeNewTimer() {
        let timeInterval = TimeInterval.random(in: 1...1.5)
        gameTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(makeGoal), userInfo: nil, repeats: false)
    }
    
    func makeBullet(xPosition: CGFloat) {
        let bullet = SKSpriteNode(imageNamed: "ballYellow")
        bullet.size = CGSize(width: 15, height: 15)
        bullet.position = CGPoint(x: xPosition, y: 0)
        bullet.physicsBody = SKPhysicsBody(circleOfRadius: bullet.size.width)
        bullet.physicsBody?.velocity = CGVector(dx: 0, dy: 600)
        bullet.physicsBody?.linearDamping = 0
        bullet.physicsBody?.angularDamping = 0
        bullet.physicsBody?.categoryBitMask = 1
        bullet.name = "bullet"
        addChild(bullet)
        
        run(SKAction.playSoundFileNamed("shootSound.mp3", waitForCompletion: false))
    }
    
    func destroy(bullet: SKNode, target: SKNode, contact: SKPhysicsContact) {
        let bangSticker = SKSpriteNode(imageNamed: "bang")
        bangSticker.size = CGSize(width: 80, height: 80)
        bangSticker.position = contact.contactPoint
        bangSticker.zPosition = 2
        addChild(bangSticker)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            bangSticker.self.removeFromParent()
        }
    }
    
    func countThePointsAndMakeSound(firstNode: SKNode, secondNode: SKNode) {
        if firstNode.name == "target" || secondNode.name == "target" {
            run(SKAction.playSoundFileNamed("rightOnTarget.mp3", waitForCompletion: false))
            
            if firstNode.name == "target" {
                addPoints(node: firstNode)
            } else {
                addPoints(node: secondNode)
            }

        } else {
            run(SKAction.playSoundFileNamed("manPain.mp3", waitForCompletion: false))
            score -= 200
        }
    }
    
    func addPoints(node: SKNode) {
        switch node.frame.width {
        case 20:
            score += 100
        case 40:
            score += 30
        default:
            score += 5
        }
    }
    
    func reload() {
        isReloading = true
        
        let reloadingLabel = SKSpriteNode(imageNamed: "reloading")
        reloadingLabel.size = CGSize(width: 400, height: 100)
        reloadingLabel.position = CGPoint(x: 390, y: 180)
        reloadingLabel.zPosition = 2
        addChild(reloadingLabel)
        
        run(SKAction.playSoundFileNamed("reloading.mp3", waitForCompletion: false))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            reloadingLabel.self.removeFromParent()
            self.bulletsCount = 6
            self.isReloading = false
        }
    }
    
    func stopTheGame() {
        
        isGameOver = true
        gameTimer?.invalidate()
        countTheTime?.invalidate()
        
        for node in children {
            if node.zPosition != -2 && node.zPosition != -1 { node.removeFromParent() }
        }
        
        let gameOverSprite = SKSpriteNode(imageNamed: "gameOver")
        gameOverSprite.position = CGPoint(x: 390, y: 180)
        gameOverSprite.size = CGSize(width: 400, height: 100)
        gameOverSprite.zPosition = 2
        addChild(gameOverSprite)
        
        let yourScoreLabel = SKLabelNode(fontNamed: "Charter")
        yourScoreLabel.text = "Your score is \(score)"
        yourScoreLabel.position = CGPoint(x: 390, y: 130)
        yourScoreLabel.fontSize = 30
        yourScoreLabel.zPosition = 2
        addChild(yourScoreLabel)
        
        let tapToRestartLabel = SKLabelNode(fontNamed: "Charter")
        tapToRestartLabel.text = "Tap to restart"
        tapToRestartLabel.position = CGPoint(x: 390, y: 100)
        tapToRestartLabel.fontSize = 20
        tapToRestartLabel.zPosition = 2
        addChild(tapToRestartLabel)
    }
    
    func restartTheGame() {
        for node in children {
            if node.zPosition == 2 { node.removeFromParent() }
        }
        isGameOver = false
        score = 0
        timeInSeconds = 10
        bulletsCount = 6
        makeLabels()
        makeTimers()
    }
}
