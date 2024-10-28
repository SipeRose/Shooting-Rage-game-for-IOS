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
    let goalNames = ["goal", "pumpkin", "goal"]
    let velocities = [
        20: 400...500,
        40: 250...350,
        80: 200...250
    ]
    var gameTimer: Timer?
    
    
    override func didMove(to view: SKView) {
        
        backgroundColor = .black
        makeBorder(yPosition: 120)
        makeBorder(yPosition: 240)
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(makeGoal), userInfo: nil, repeats: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            makeBullet(xPosition: location.x)
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
        
        if (firstNode.name == "bullet" && secondNode.name == "target") || (firstNode.name == "target" && secondNode.name == "bullet") {
            destroy(bullet: firstNode, target: secondNode, contact: contact)
            firstNode.removeFromParent()
            secondNode.removeFromParent()
        }
    }
}





extension GameScene {
    
    func makeBorder(yPosition: Int) {
        let border = SKSpriteNode(color: .brown, size: CGSize(width: 1560, height: 5))
        border.zPosition = -1
        border.position = CGPoint(x: 0, y: yPosition)
        addChild(border)
    }
    
    @objc func makeGoal() {
        
        gameTimer?.invalidate()
        guard let goal = goalNames.randomElement() else { return }
        let size: Int
        let xVelocity: Int
        let yPosition = possibleYPositions.randomElement()!
        
        if goal == "pumpkin" {
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
            sprite.name = "target"
            
            sprite.physicsBody = SKPhysicsBody(texture: sprite.texture!, size: sprite.size)
            //sprite.physicsBody?.velocity = CGVector(dx: xVelocity, dy: 0)
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
            if node.name == "target" {
                if node.position.y == yPosition && (node.physicsBody?.velocity.dx)! < velocity {
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
    }
    
    func destroy(bullet: SKNode, target: SKNode, contact: SKPhysicsContact) {
        if let explosion = SKEffectNode(fileNamed: "FireParticles") {
            explosion.position = contact.contactPoint
            addChild(explosion)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                explosion.self.removeFromParent()
            }
        }
    }
}
