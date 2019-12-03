//
//  GameScene.swift
//  SpaceInvadersClone
//
//  Created by Vander Hoeven, Evan on 11/7/19.
//  Copyright © 2019 Vander Hoeven, Evan. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: PRIVATE CONSTANTS
    
    /// Invading army constants
    private let INVADER_SPACING = CGSize(width: 12, height: 12)
    private let INVADER_ROW_COUNT = 6
    private let INVADER_COLUMN_COUNT = 6
    private let INVADER_VELOCITY : CGFloat = 10 // move the invaders 10 pixels per interval
    private let INVADER_MINIMUM_SPEED : CFTimeInterval = 0.03
    /// Core cannon constants
    private let CORE_CANNON_SIZE = CGSize(width: 30, height: 16)
    private let CORE_CANNON_NAME = "coreCannon" // Built for easy lookup later.
    private let CORE_CANNON_SPEED : CGFloat = 3 // How many pixels the core cannon moves when the button is pressed.
    /// HUD constants
    private let SCORE_HUD_NAME = "scoreHud"
    private let LIVES_HUD_NAME = "livesLeftHud"
    private let HIGHSCORE_HUD_NAME = "highscoreHud"
    private let LEFT_MOVEMENT_NAME = "leftButton"
    private let RIGHT_MOVEMENT_NAME = "rightButton"
    private let FIRE_BUTTON_NAME = "fireButton"
    private let PAUSE_PLAY_NAME = "pauseOrPlay"
    private let BUTTON_SIZE = CGSize(width: 60, height: 60)
    private let BUTTON_OFFSET : CGFloat = 15
    /// BITMASK constants for contact detection (not collision detection, we don't want physics)
    // NOTE: We can have a maximum of 32 of these, because they must be unique.
    private let INVADER_BULLET_BITMASK : UInt32 = 0x1 << 0
    private let INVADER_BITMASK : UInt32 = 0x1 << 1
    private let CORE_CANNON_BULLET_BITMASK : UInt32 = 0x1 << 2
    private let CORE_CANNON_BITMASK:  UInt32 = 0x1 << 3
    /// endgame detection constants
    private let INVADER_MINIMUM_HEIGHT : Float = 105 // 3 * BUTTON_OFFSET + BUTTON_SIZE.height
    /// data persistance constance
    private let HIGHSCORE_KEY : String = "highscore key"
    
    // MARK: PRIVATE VARIABLES
    
    /// Tells us if the scene has been built yet.
    private var sceneCreated = false
    /// The current direction the invaders are moving
    private var invaderDirection: InvaderDirection = .right
    private var invaderSpeed : CFTimeInterval = 1.0 // move the invaders once per second at the beginning
    /// The time that has passed since the aliens last moved
    private var timeOfLastMove: CFTimeInterval = 0.0
    /// Tells us if the left button is currently being pressed
    private var leftIsPressed = false;
    /// Tells us if the right button is currently being pressed
    private var rightIsPressed = false;
    /// An array of all queued object contact detection
    private var contactQueue = [SKPhysicsContact]()
    /// Tracks the user's current score
    private var score : Int = 0
    private var highScore : Int = 0
    /// Tracks how many lives the user has left.
    private var livesLeft : Int = 3
    /// Tracks if we have displayed the game over scene
    private var gameHasEnded : Bool = false
    private var gamePaused : Bool = false
    /// An enum for controlling the set of possible space invaders
    private enum InvaderType {
        case a
        case b
        case c
        
        static var size : CGSize {
            return CGSize(width: 24, height: 16)
        }
        
        static var name : String {
            return "invader"
        }
    }
    
    /// An enum for all the possible directions a space invader can go
    private enum InvaderDirection {
        case right
        case left
        case downThenRight
        case downThenLeft
        case none
    }
    /// An enum for determining the kind of bullet being fired and tracking bullet details
    private enum BulletType {
        case InvaderBullet
        case CoreCannonBullet
        static var invaderBulletName : String {
            return "InvaderBullet"
        }
        static var coreCannonBulletName : String {
            return "CoreCannonBullet"
        }
        static var bulletSize : CGSize {
            return CGSize(width: 4, height: 8)
        }
    }
    
    // MARK: SCENE SETUP FUNCTIONS
    
    // Scene Setup and Content Creation
    override func didMove(to view: SKView) {
        
        if (!self.sceneCreated) {
            self.createContent()
            self.sceneCreated = true
        }
        // Tell the physics engine that we are going to handle
        // contact detection events.
        physicsWorld.contactDelegate = self
    }
    
    private func createContent() {
        // Fill the screen with the invading army.
        self.setupInvaders()
        // Put in our intrepid hero, the core cannon
        self.setupCoreCannon()
        // give the user some information in a head's up display
        self.setupHudAndControls()
        // set the background to the inky black void of space
        self.backgroundColor = SKColor.black
    }
    
    /**
     Sets up the army of invaders.
    */
    private func setupInvaders() {
        // Establish the starting point of where we create the army
        // one third from the right of the screen and one half from
        // the bottom of the screen + offset from controls.
        let baseOrigin = CGPoint(x: size.width / 3, y: size.height / 2 + 2.0 * self.BUTTON_OFFSET + self.BUTTON_SIZE.height)
        
        for row in 1...self.INVADER_ROW_COUNT {
            var invaderType : InvaderType
            if (row * 3 <= self.INVADER_ROW_COUNT) {
                // if we are in the first third of the rows
                invaderType = .a
            } else if (row * 3 <= self.INVADER_ROW_COUNT * 2) {
                // if we are in the second third of the rows
                invaderType = .b
            } else {
                // if we are in the last third of the rows
                invaderType = .c
            }
            
            // Determine where the first invader of each row should go
            let invaderPositionY = CGFloat(row) * (InvaderType.size.height * 2) + baseOrigin.y
            var invaderPosition = CGPoint(x: baseOrigin.x, y: invaderPositionY)
            
            // Move through each column in each row
            for _ in 1..<self.INVADER_COLUMN_COUNT {
                // make an invader for the current row and column
                let invader = makeInvader(ofType: invaderType)
                invader.position = invaderPosition
                // add the invader to the scene
                self.addChild(invader)
                
                invaderPosition = CGPoint(x: invaderPosition.x + InvaderType.size.width + self.INVADER_SPACING.width,
                                          y: invaderPositionY)
            }
        }
    }
    
    /**
     Creates some hud objects, including the current score.
     */
    private func setupHudAndControls() {
        // setup the label which tells the user their score
        let scoreLabel = SKLabelNode(fontNamed: "Courier")
        scoreLabel.name = self.SCORE_HUD_NAME
        scoreLabel.fontSize = 15
        scoreLabel.fontColor = SKColor.green
        scoreLabel.text = String(format: "Score: %04u", self.score)
        scoreLabel.position = CGPoint(x: frame.size.width / 2,
                                      y: size.height - (60 - scoreLabel.frame.size.height / 2))
        self.addChild(scoreLabel)
        
        // setup the label which is the high score
        self.highScore = loadHighScore()
        let highScoreLabel = SKLabelNode(fontNamed: "Courier")
        highScoreLabel.name = self.HIGHSCORE_HUD_NAME
        highScoreLabel.fontSize = 15
        highScoreLabel.fontColor = SKColor.green
        highScoreLabel.text = String(format: "High Score: %04u", self.highScore)
        highScoreLabel.position = CGPoint(x: frame.size.width / 2,
                                          y: scoreLabel.frame.minY - highScoreLabel.frame.size.height)
        self.addChild(highScoreLabel)
        
        // setup the label which tells the user how many lives they have left
        let livesLabel = SKLabelNode(fontNamed: "Courier")
        livesLabel.name = self.LIVES_HUD_NAME
        livesLabel.fontSize = 15
        livesLabel.fontColor = SKColor.red
        livesLabel.text = String(format: "Lives: %01u", self.livesLeft)
        livesLabel.position = CGPoint(x: frame.size.width / 2,
                                      y: highScoreLabel.frame.minY - livesLabel.frame.size.height)
        self.addChild(livesLabel)
        
        // setup the buttons which lets the user move the core cannon left and right
        // TODO right now they're purple blocks, change that with graphics I get later.
        let rightButton = SKSpriteNode(color: SKColor.purple, size: self.BUTTON_SIZE)
        rightButton.name = self.RIGHT_MOVEMENT_NAME
        rightButton.position = CGPoint(x: frame.size.width - (self.BUTTON_OFFSET + rightButton.frame.size.width / 2),
                                       y: self.BUTTON_OFFSET + rightButton.frame.size.height / 2)
        let leftButton = SKSpriteNode(color: SKColor.purple, size: self.BUTTON_SIZE)
        leftButton.name = self.LEFT_MOVEMENT_NAME
        leftButton.position = CGPoint(x: rightButton.frame.minX - leftButton.frame.size.width,
                                      y: self.BUTTON_OFFSET + leftButton.frame.size.height / 2)
        // setup the button which fires the core cannon
        // TODO right now its an orange block, change that to a graphic.
        let fireButton = SKSpriteNode(color: SKColor.orange, size: self.BUTTON_SIZE)
        fireButton.name = self.FIRE_BUTTON_NAME
        fireButton.position = CGPoint(x: self.BUTTON_OFFSET + fireButton.frame.size.width / 2, y: BUTTON_OFFSET + fireButton.frame.size.height / 2)
        
        let pausePlayButton = SKSpriteNode(color: SKColor.gray, size: self.BUTTON_SIZE)
        pausePlayButton.name = self.PAUSE_PLAY_NAME
        pausePlayButton.position = CGPoint(x: self.frame.size.width - self.BUTTON_OFFSET - pausePlayButton.frame.size.width / 2, y: self.frame.height - self.BUTTON_OFFSET - pausePlayButton.frame.size.height / 2)
        
        // Add the buttons to the scene
        self.addChild(leftButton)
        self.addChild(rightButton)
        self.addChild(fireButton)
        self.addChild(pausePlayButton)
        
        // Add a line directly below the core cannon which represents the ground
        let point1 = CGPoint(x: 0, y: 2.0 * self.BUTTON_OFFSET + self.BUTTON_SIZE.height)
        let point2 = CGPoint(x: self.size.width, y: 2.0 * self.BUTTON_OFFSET + self.BUTTON_SIZE.height)
        
        let pathToDraw:CGMutablePath = CGMutablePath.init()
        let myLine:SKShapeNode = SKShapeNode(path:pathToDraw)

        pathToDraw.move(to: point1)
        pathToDraw.addLine(to: point2)

        myLine.path = pathToDraw
        myLine.strokeColor = SKColor.green

        self.addChild(myLine)
    }
    
    /**
     Creates the core cannon (the player character) and adds
     it to the scene.
     */
    private func setupCoreCannon() {
        let cc = makeCoreCannon()
        // Put the cannon in the middle of the screen at the bottom.
        cc.position = CGPoint(x: size.width / 2.0, y: self.CORE_CANNON_SIZE.height / 2.0 + 2.0 * self.BUTTON_OFFSET + self.BUTTON_SIZE.height)
        self.addChild(cc)
    }
    
    // MARK: ENDGAME FUNCTIONS
    
    /**
     Determines if the game is over based on the three endgame conditions:
     1. There are no invaders left on the screen.
     2. The player's core cannon is destroyed
     3. The invaders (if present) are too close to the bottom of the screen
     - Returns: True if any of the endgame conditions are true, false otherwise.
     */
    private func isGameOver() -> Bool {
        // if there are no more invaders, then game is over, we won.
        let invader = childNode(withName: InvaderType.name)
        if invader == nil {
            // There are no more invaders on the screen, we killed them all.
            return true;
        }
        // if the core cannon is destroyed, the game is over, we lost.
        let coreCannonRef = childNode(withName: self.CORE_CANNON_NAME)
        if coreCannonRef == nil {
            // Our core cannon is gone, we are dead.
            return true
        }
        // We return early in the other two cases so that we don't iterate
        // through nodes if we don't have to.
        
        // The core cannon and the invaders are present, check to make sure
        // that the invaders haven't gotten too close to the bottom of the screen.
        var invaderIsToClose = false;
        enumerateChildNodes(withName: InvaderType.name, using: { (node, stop) in
            if (Float(node.frame.minY) < self.INVADER_MINIMUM_HEIGHT) {
                invaderIsToClose = true;
                stop.pointee = true // akin to break, leave enumerate child nodes early.
            }
        })
        return invaderIsToClose
    }
    
    private func endGame() {
        if !self.gameHasEnded {
            self.gameHasEnded = true
            let gameOverScene = GameOverScene(size: self.size)
            
            view?.presentScene(gameOverScene, transition: SKTransition.doorsOpenHorizontal(withDuration: 1.0))
        }
    }
    
    // MARK: NODE MAKER FUNCTIONS
    /// Defined as functions which create an SKNode
    /// and their helper functions.

    /**
     Creates an invader node
     
     - Parameter invaderType: the type of invader we want.
     
     - Returns:An SKSpriteNode which contains an invader from space
     */
    private func makeInvader(ofType invaderType: InvaderType) -> SKNode {
        // Fetch the two textures for the corresponding invaderType
        let invaderTextures = loadInvaderTextures(ofType: invaderType)
        // Create the node using the two textures
        let invader = SKSpriteNode(texture: invaderTextures[0])
        // Animate between the two textures using the invader speed
        invader.run(SKAction.repeatForever(SKAction.animate(with: invaderTextures, timePerFrame: self.invaderSpeed)))
        invader.name = InvaderType.name
        // setup contact detection so we can shoot the invaders
        invader.physicsBody = SKPhysicsBody(rectangleOf: invader.frame.size)
        invader.physicsBody!.isDynamic = false
        invader.physicsBody!.categoryBitMask = self.INVADER_BITMASK
        // Don't detect contact from the invader (handled by the bullets)
        invader.physicsBody!.contactTestBitMask = 0x0
        invader.physicsBody!.collisionBitMask = 0x0
        return invader
    }
    
    /**
     Fetches the textures for a given space invader
     - Parameter invaderType: The type of invader which indicates its appearance.
     - Returns: an array of SKTexture where each SKTexture represents the desired texture at a different size.
     */
    private func loadInvaderTextures(ofType invaderType: InvaderType) -> [SKTexture] {
      
      var prefix: String
      
      switch(invaderType) {
      case .a:
        prefix = "InvaderA"
      case .b:
        prefix = "InvaderB"
      case .c:
        prefix = "InvaderC"
      }
      
      // 1
      return [SKTexture(imageNamed: String(format: "%@_00.png", prefix)),
              SKTexture(imageNamed: String(format: "%@_01.png", prefix))]
    }
    
    /**
     Creates a core cannon as an SKNode
     - Returns: A SKNode representing the Core Cannon
     */
    private func makeCoreCannon() -> SKNode {
        let coreCannon = SKSpriteNode(imageNamed: "CoreCannon.png")
        coreCannon.name = self.CORE_CANNON_NAME
        coreCannon.physicsBody = SKPhysicsBody(rectangleOf: coreCannon.frame.size)
        // set the core cannon's contact detection category
        coreCannon.physicsBody!.categoryBitMask = self.CORE_CANNON_BITMASK
        coreCannon.physicsBody!.isDynamic = false
        // don't let gravity take the cannon off of the screen
        coreCannon.physicsBody!.affectedByGravity = false
        // Don't detect contact from the core cannon (handled by the bullets)
        coreCannon.physicsBody!.contactTestBitMask = 0x0
        coreCannon.physicsBody!.collisionBitMask = 0x0
        return coreCannon
    }
    
    /**
     Creates a bullet as an SKNode
     - Parameter bulletType: A BulletType enum that indicates what type of bullet we are creating.
     - Returns: A SKNode representing the requested bullet
     */
    private func makeBullet(ofType bulletType: BulletType) -> SKNode {
        var bullet: SKNode
        
        switch bulletType {
        case .CoreCannonBullet:
            bullet = SKSpriteNode(color: SKColor.green, size: BulletType.bulletSize)
            bullet.name = BulletType.coreCannonBulletName
            // setup contact detection so the bullet knows when it hits an invader.
            bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.frame.size)
            // being dynamic means that the spritekit will check for contact from this object.
            // the invaders are static, meaning they aren't moved by the physics engine, and
            // thus two static objects are never checked for contact or collisions.
            bullet.physicsBody!.isDynamic = true
            bullet.physicsBody!.affectedByGravity = false
            bullet.physicsBody!.categoryBitMask = self.CORE_CANNON_BULLET_BITMASK
            // Detect contact, but not physics collisions, with invaders.
            bullet.physicsBody!.contactTestBitMask = self.INVADER_BITMASK
            bullet.physicsBody!.collisionBitMask = 0x0
            break
        case .InvaderBullet:
            bullet = SKSpriteNode(color: SKColor.magenta, size: BulletType.bulletSize)
            bullet.name = BulletType.invaderBulletName
            // setup contact detection so the bullet knows when it hits the player core cannon.
            bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.frame.size)
            // being dynamic means that the spritekit will check for contact from this object.
            // the core cannon is static, meaning it isn't moved by the physics engine, and
            // thus two static objecs are never checked for contact or collisions.
            bullet.physicsBody!.isDynamic = true
            bullet.physicsBody!.affectedByGravity = false
            bullet.physicsBody!.categoryBitMask = self.INVADER_BULLET_BITMASK
            // Detect contact, but not physics collisions, with the core cannon.
            bullet.physicsBody!.contactTestBitMask = self.CORE_CANNON_BITMASK
            bullet.physicsBody!.collisionBitMask = 0x0
            break
        }
        return bullet
    }
    
    // MARK: BUTTON CONTROLLER FUNCTIONS
    
    /**
     Determines if the left and right buttons are being pressed, and triggers
     the corresponding flags so that the Core Cannon is moved.
     - Parameter touches: A set of all the users touches
     - Parameter event: An optional UIEvent
    */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNode = atPoint(location)
            if touchedNode.name == self.LEFT_MOVEMENT_NAME {
                self.leftIsPressed = true
            } else if touchedNode.name == self.RIGHT_MOVEMENT_NAME {
                self.rightIsPressed = true
            } else if touchedNode.name == self.FIRE_BUTTON_NAME {
                fireTheCoreCannon()
            }
        }
    }

    /**
     Determines if the left and right buttons have stopped being pressed, and
     tiggers the corresponing flags to stop Core Cannon movement.
     - Parameter touches: A set of all the users touches
     - Parameter event: An optional UIEvent
     */
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNode = atPoint(location)
            if touchedNode.name == self.LEFT_MOVEMENT_NAME {
                self.leftIsPressed = false
            } else if touchedNode.name == self.RIGHT_MOVEMENT_NAME {
                self.rightIsPressed = false
            } else if touchedNode.name == self.FIRE_BUTTON_NAME {
                fireTheCoreCannon()
            } else if touchedNode.name == self.PAUSE_PLAY_NAME {
                self.isPaused = !self.isPaused
                // TODO switch out the icons when I have them.
            }
        }
    }
    
    /**
     Determines if the user's finger has left the button while still touching
     the screen, and will only activate the buttons that the user has their finger
     on.
     - Parameter touches: A set of all the users touches
     - Parameter event: An optional UIEvent
     */
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.leftIsPressed = false
        self.rightIsPressed = false
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNode = atPoint(location)
            if touchedNode.name == self.LEFT_MOVEMENT_NAME {
                self.leftIsPressed = true
            } else if touchedNode.name == self.RIGHT_MOVEMENT_NAME {
                self.rightIsPressed = true
            }
        }
    }
    
    // MARK: SCENE UPDATE & NODE MOVER FUNCTIONS & THEIR HELPERS
    
    /**
     Updates the scene at a target rate of 60 times a second
     */
    override func update(_ currentTime: TimeInterval) {
        if isPaused {
            return // do nothing, we're paused
        }
        if isGameOver() {
            endGame()
        }
        /* Called before each frame is rendered */
        processContacts(forUpdate: currentTime)
        moveInvaders(forUpdate: currentTime)
        if leftIsPressed {
            moveCoreCannonLeft()
        }
        else if rightIsPressed {
            moveCoreCannonRight()
        }
        fireInvaderBullets(forUpdate: currentTime)
    }
        
    /**
     Moves the invading army down the screen and back and forth.
     
     - Parameter currentTime: A CFTimeInterval for the current time in the game loop.
    */
    private func moveInvaders(forUpdate currentTime: CFTimeInterval) {
        if (currentTime - self.timeOfLastMove < self.invaderSpeed) {
            return // do nothing until it is time.
        }
        determineInvaderDirection()
        
        enumerateChildNodes(withName: InvaderType.name, using: { (node, stop) in
            switch self.invaderDirection {
            case .right:
                node.position = CGPoint(x: node.position.x + self.INVADER_VELOCITY, y: node.position.y)
            case .left:
                node.position = CGPoint(x: node.position.x - self.INVADER_VELOCITY, y: node.position.y)
            case .downThenLeft, .downThenRight:
                node.position = CGPoint(x: node.position.x, y: node.position.y - self.INVADER_VELOCITY)
            case .none:
                break
            }})
        
        // update the relevant variables for the next
        // time this function is called
        self.timeOfLastMove = currentTime
    }
    
    /**
     Helper function to moveInvaders()
     Determines what direction the invaders should move so they don't leave the screen.
     */
    private func determineInvaderDirection() {
        var proposedDirection = self.invaderDirection
         // check any and all nodes for colisions with the edge of the screen
        enumerateChildNodes(withName: InvaderType.name, using: { (node, stop) in
            switch self.invaderDirection {
            case .right:
                if (node.frame.maxX >= node.scene!.size.width - 1.0) {
                    // We've hit the right side of the screen
                    proposedDirection = .downThenLeft
                    self.setInvaderSpeed(to: self.invaderSpeed * 0.8)
                    stop.pointee = true
                }
            case .left:
                if (node.frame.minX <= 1.0) {
                    proposedDirection = .downThenRight
                    self.setInvaderSpeed(to: self.invaderSpeed * 0.8)
                    stop.pointee = true
                }
            case .downThenLeft:
                proposedDirection = .left
                stop.pointee = true
            case .downThenRight:
                proposedDirection = .right
                stop.pointee = true
            default:
                break
            }})
        
        // update the movement direction if it changed
        if (proposedDirection != self.invaderDirection) {
            invaderDirection = proposedDirection
        }
    }
    
    /**
     Updates the speed of the invaders and adjusts their animations accordingly.
     - Parameter timePerMove: The CFTimeInterval that we should change the invader speed to.
     */
    private func setInvaderSpeed(to timePerMove: CFTimeInterval) {
      // Prevent weird speeds and divide by zero errors
        if self.invaderSpeed <= 0 || timePerMove < self.INVADER_MINIMUM_SPEED {
        return
      }
      
      // Get a ratio of the old speed to the new speed
      let ratio: CGFloat = CGFloat(self.invaderSpeed / timePerMove)
      self.invaderSpeed = timePerMove
      
      // Update the sprite animations using that ratio
      enumerateChildNodes(withName: InvaderType.name) { node, stop in
        node.speed = node.speed * ratio
      }
    }
    
    /**
     Lets the invading army of aliens fire their lazers back at you,
     because the game would be too easy otherwise.
     However, they only get one bullet at a time.
     */
    private func fireInvaderBullets(forUpdate currentTime: CFTimeInterval) {
        let existingBullet = childNode(withName: BulletType.invaderBulletName)
        
        // only fire a bullet if there are none
        if existingBullet == nil {
            // get all of the invaders and store them in an array
            var allInvaders = [SKNode]()
            enumerateChildNodes(withName: InvaderType.name)  {node, stop in
                allInvaders.append(node)
            }
        
            if allInvaders.count > 0 {
                // get a random invader (STRETCH GOAL: Only fire from a bottom most invader)
                let invader = allInvaders[Int(arc4random_uniform(UInt32(allInvaders.count)))]
                
                // create a bullet to be fired from the invader
                let bullet = makeBullet(ofType: .InvaderBullet)
                bullet.position = CGPoint(x: invader.position.x, y: invader.position.y - invader.frame.size.height / 2 + bullet.frame.size.height / 2)
                
                // setup a destination to be just below the bottom of the screen below the invader
                let bulletDestination = CGPoint(x: invader.position.x, y: -(bullet.frame.size.height / 2))
                
                // fire the bullet
                fireBullet(bullet: bullet, toDestination: bulletDestination, withDuration: 2.0, andSoundFileName: "InvaderBullet.wav")
            }
        }
    }
    
    /**
     Moves the Core Cannon to the left.
    */
    private func moveCoreCannonLeft() {
        enumerateChildNodes(withName: self.CORE_CANNON_NAME, using: { (node, stop) in
            if (node.frame.minX > 1.0) {
                // there is more space to move left on the screen.
                node.position = CGPoint(x: node.position.x - self.CORE_CANNON_SPEED, y: node.position.y)
            } // else do nothing, we hit the edge of the screen.
        })
    }
    
    /*
     Moves the Core Cannon to the right.
    */
    private func moveCoreCannonRight() {
        enumerateChildNodes(withName: self.CORE_CANNON_NAME, using: { (node, stop) in
            if (node.frame.maxX < node.scene!.size.width - 1.0) {
                node.position = CGPoint(x: node.position.x + self.CORE_CANNON_SPEED, y: node.position.y)
            } // else do nothing, we hit the edge of the screen
        })
    }
    
    /**
     "Fires" a bullet from starting point of the bullet to the destination parameter while playing the shooting sound.
     - Parameter bullet: An SKNode that is our bullet node.
     - Parameter destination: The target of our bullet.
     - Parameter duration: The duration of the bullet's movement action.
     - Parameter soundName: A string representing the name of an audio file that we will play when the bullet enters the scene.
     */
    private func fireBullet(bullet: SKNode, toDestination destination: CGPoint, withDuration duration: CFTimeInterval, andSoundFileName soundName: String) {
        // Setup the movement from start to end and remove the bullet from the scene when it gets there.
        let bulletAction = SKAction.sequence([
            SKAction.move(to: destination, duration: duration),
            SKAction.wait(forDuration: 3.0 / 60.0),
            SKAction.removeFromParent()
            ])
        // setup the action that plays the shooting sound
        let soundAction = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        // move the bullet and play the sound at the same time by making it part of the same action group
        bullet.run(SKAction.group([bulletAction, soundAction]))
        // add the bullet to the scene, firing all the actions setup above
        addChild(bullet)
    }
    
    /*
     Fire the core cannon if and only if there is no other bullets from the core cannon
     already in the scene.
     */
    private func fireTheCoreCannon() {
        // see if there is already a bullet from the core cannon in the scene
        let existingBullet = childNode(withName: BulletType.coreCannonBulletName)
        
        if existingBullet == nil {
            // only fire the bullet if there isn't one already.
            if let coreCannonNode = childNode(withName: CORE_CANNON_NAME) {
                let bullet = makeBullet(ofType: .CoreCannonBullet)
                // set the bullet to start at the barrel of the core cannon
                bullet.position = CGPoint(x: coreCannonNode.position.x, y: coreCannonNode.position.y + coreCannonNode.frame.size.height - bullet.frame.size.height / 2)
                // make the destination be directly above the core cannon (so it appears to fly straight up)
                // just off the screen so that the bullets leave the screen.
                let bulletDestination = CGPoint(x: coreCannonNode.position.x, y: frame.size.height + bullet.frame.size.height / 2)
                // use the helper function to fire the bullet
                fireBullet(bullet: bullet, toDestination: bulletDestination, withDuration: 1.0, andSoundFileName: "CoreCannonBullet.wav")
            }
        }
    }
    
    /**
     Changes the user's current score and update the HUD to reflect the change.
     - Parameter points: an Int to modify the points by.
     */
    func modifyScore(by points: Int) {
        self.score += points
        
        if let score = childNode(withName: self.SCORE_HUD_NAME) as? SKLabelNode {
          score.text = String(format: "Score: %04u", self.score)
        }
        
        if self.score > self.highScore {
            // save the new high score
            self.highScore = self.score
            saveHighScore(score: self.highScore)
            if let highScore = childNode(withName: self.HIGHSCORE_HUD_NAME) as? SKLabelNode {
                highScore.text = String(format: "High Score: %04u", self.highScore)
            }
        }
    }
    
    /**
     Takes away a player's life point and modifies the HUD to reflect that change.
     - Returns: A boolean indicating if we the user has lives left
     */
    func looseALife() -> Bool {
        self.livesLeft -= 1
        if let lifeLabel = childNode(withName: self.LIVES_HUD_NAME) as? SKLabelNode {
            lifeLabel.text = String(format: "Lives: %01u", self.livesLeft)
        }
        return self.livesLeft > 0
    }
    
    // MARK: CONTACT DETECTION FUNCTIONS
    
    /**
     Processes all contacts between physics objects and removes them from the contactQueue.
     - Parameter currentTime: A CFTimeInterval which is the time of the game loop.
     */
    func processContacts(forUpdate currentTime: CFTimeInterval) {
        for contact in contactQueue {
            handle(contact)
            
            // remove the contact now that it has been handled
            if let index = contactQueue.firstIndex(of: contact) {
                contactQueue.remove(at: index)
            }
        }
    }
    
    /**
     Adds any detected contacts between physics objects to the contacts queue for processing.
     - Parameter contact: A detected contact between physics objects.
     */
    func didBegin(_ contact: SKPhysicsContact) {
        contactQueue.append(contact)
    }

    /**
     Handles the behavior of contacts between physics objects.
     - Parameter contact: A detected contact between physics objects.
     */
    func handle(_ contact: SKPhysicsContact) {
        // Ensure that we haven't handled this contact already
        if contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil {
            return // the nodes involved in the contact no longer exist, return early.
        }
        
        // get the names of the involved nodes in an array for sake of convenience in the following syntax
        let nodeNames = [contact.bodyA.node!.name!, contact.bodyB.node!.name!]
        // check if an invader bullet has hit our ship.
        if nodeNames.contains(self.CORE_CANNON_NAME) && nodeNames.contains(BulletType.invaderBulletName) {
            // An invader bullet hit our ship
            // play the game over sound of your core cannon being destroyed by enemy fire
            run(SKAction.playSoundFileNamed("CoreCannonHit.wav", waitForCompletion: false))
            // remove the core cannon and the bullet from the scene
            contact.bodyA.node!.removeFromParent()
            contact.bodyB.node!.removeFromParent()
            if looseALife() {// provide a penalty for the player
                setupCoreCannon() // recenter the player in the scene
            }
            
        } else if nodeNames.contains(InvaderType.name) && nodeNames.contains(BulletType.coreCannonBulletName) {
            // the core cannon hit an invader
            // play the sound of the death of the alien
            run(SKAction.playSoundFileNamed("InvaderHit.wav", waitForCompletion: false))
            // remove the invader and the bullet from the scene
            contact.bodyA.node!.removeFromParent()
            contact.bodyB.node!.removeFromParent()
            modifyScore(by: 100) // Stretch Goal: Find a way to modify the score based on invader type.
        }
    }
    
    // MARK: HIGH SCORE PERSISTANCE
    
    /**
     Uses NSUserDefaults to save the user's high score
     - Parameter score: An Integer which is the new high score we wish to save.
     */
    func saveHighScore(score: Int) {
        UserDefaults.standard.set(score, forKey: self.HIGHSCORE_KEY)
    }
    
    /**
    Uses NSUserDefaults to retrieve the user's high score
     - Returns: An Integer for the user's high score, or zero if there was no record of a high score.
     */
    func loadHighScore() -> Int {
        return UserDefaults.standard.integer(forKey: self.HIGHSCORE_KEY)
    }
    
}
