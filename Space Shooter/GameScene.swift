//
//  GameScene.swift
//  Space Shooter
//
//  Created by Charles Martin Reed on 12/23/18.
//  Copyright © 2018 Charles Martin Reed. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //MARK:- Game properties
    var starfield: SKEmitterNode!
    var player: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var gameTimer: Timer!
    var possibleAliens = ["alien", "alien2", "alien3"]
    
    //bitask properties
    let alienCategory: UInt32 = 0x1 << 1
    let photonTorpedoCategory: UInt32 = 0x1 << 0
    
    //motion properties
    let motionManager = CMMotionManager()
    var xAcceleration: CGFloat = 0

    override func didMove(to view: SKView) {
        initializeGameScene()
    }

    //MARK:- Game Init methods
    private func initializeGameScene() {
        initializeMotionControls()
        initializeGamePhysics()
        initializeGameScore()
        initializeLevelBackground()
        initializeCurrentPlayer()
        initializeGameTimer()
        
    }
    
    private func initializeMotionControls() {
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
            if let accelerometerData = data {
                let acceleration = accelerometerData.acceleration
                self.xAcceleration = CGFloat(acceleration.x) * 0.75 + self.xAcceleration * 0.25
            }
        }
        
    }
    
    private func initializeGameScore() {
        scoreLabel = SKLabelNode.scoreLabel
        scoreLabel.position = CGPoint(x: 175, y: self.frame.size.height - 125)
        score = 0
        self.addChild(scoreLabel)
    }
    
    private func initializeGamePhysics() {
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0) //no gravity in either direction
        self.physicsWorld.contactDelegate = self
    }
    
    private func initializeLevelBackground() {
        starfield = SKEmitterNode(fileNamed: "Starfield")
        starfield.position = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height)
        starfield.advanceSimulationTime(15) //fixes issue of starfield taking a bit to animate downward
        self.addChild(starfield)
        starfield.zPosition = -1 //always the background
    }
    
    private func initializeCurrentPlayer() {
        //no physics body for player since it won't interact with other items in this particular game demo
        //NOTE: This positioning is relative to the anchor point being set to x: 0.0, y: 0.0 in GameScene.sks
        player = SKSpriteNode(imageNamed: "shuttle")
        player.position = CGPoint(x: self.frame.size.width / 2, y: player.size.height / 2 + 40)
        self.addChild(player)
    }
    
    private func initializeGameTimer() {
        //how often we create enemies
        gameTimer = Timer.scheduledTimer(timeInterval: 0.50, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
    }
    
    //MARK:- Enemy creation
    @objc private func addAlien() {
        let min = 70
        let max = Int(self.frame.size.width - 70)
        //each time we add a new alien, our array is shuffled and the aliens get a new array index
        possibleAliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAliens) as! [String]
        let alien = SKSpriteNode(imageNamed: possibleAliens[0])
        
        //generate a random position for the generated alien
        let randomAlienPosition = GKRandomDistribution(lowestValue: min, highestValue: max)
        let position = CGFloat(randomAlienPosition.nextInt()) //need CGFloat for positioning
        alien.position = CGPoint(x: position, y: self.frame.size.height + alien.size.height)
        
        //alien physics and collision
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = photonTorpedoCategory
        alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(alien)
        
        //alien animation and "attack"
        let animationDuration: TimeInterval = 6
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -alien.size.height), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        alien.run(SKAction.sequence(actionArray))
    }
    
    //MARK:- Contact Delegate protocol methods
    func didBegin(_ contact: SKPhysicsContact) {
        //first body and second body, need to find out which is torpedo and which is alien
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        //bitwise compare
        if (firstBody.categoryBitMask & photonTorpedoCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0 {
            torpedoDidCollideWithAlien(torpedoNode: firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode)
        }
    }
    
    
    //MARK:- Gameplay logic
    override func didSimulatePhysics() {
     //updating the player position using acceleration data
        player.position.x += xAcceleration * 50
        
        //wrap the player sprite around the screen if it exceeds screen bounds
        if player.position.x < -20 {
            player.position = CGPoint(x: self.size.width + 20, y: player.position.y)
        } else if player.position.x > self.size.width + 20 {
            player.position = CGPoint(x: -20, y: player.position.y)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireTorpedo()
    }
    
    private func fireTorpedo() {
        self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        
        let torpedoNode = SKSpriteNode(imageNamed: "torpedo")
        torpedoNode.position = player.position
        torpedoNode.position.y += 5
        
        //torpedo physics and collision
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width / 2)
        torpedoNode.physicsBody?.isDynamic = true
        
        torpedoNode.physicsBody?.categoryBitMask = photonTorpedoCategory
        torpedoNode.physicsBody?.contactTestBitMask = alienCategory
        torpedoNode.physicsBody?.collisionBitMask = 0
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        
        self.addChild(torpedoNode)
        
        //animation logic
        let animationDuration: TimeInterval = 0.3 //could also be configured to screen size
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: self.frame.size.height + 10), duration: animationDuration)) //moving from player position to 10 pixels off screen
        actionArray.append(SKAction.removeFromParent())
        
        torpedoNode.run(SKAction.sequence(actionArray))
    }
    
    private func torpedoDidCollideWithAlien(torpedoNode: SKSpriteNode, alienNode: SKSpriteNode) {
        
        //add our explosion
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = alienNode.position
        self.addChild(explosion)
        
        //play the sound
        self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        
        //remove the torpedo and alien
        torpedoNode.removeFromParent()
        alienNode.removeFromParent()
        
        self.run(SKAction.wait(forDuration: 2)) {
            explosion.removeFromParent()
        }
        
        //increment the score
        score += 5
    }
    
    override func update(_ currentTime: TimeInterval) {
       
    }
}



