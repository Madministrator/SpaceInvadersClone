//
//  MainMenuScene.swift
//  SpaceInvadersClone
//
//  Created by Vander Hoeven, Evan on 12/5/19.
//  Copyright © 2019 Vander Hoeven, Evan. All rights reserved.
//

import UIKit
import SpriteKit

class MainMenuScene: SKScene {
    
    // MARK: Private constants
    private let BEGIN_NAME = "play the game"
    private let LABEL_OFFSETS : CGFloat = 20.0 // pixels
    
    // MARK: Private variables
    private var menuCreated = false
    private var gameScene : GameScene
    
    override init(size: CGSize) {
        self.gameScene = GameScene(size: size)
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        // I don't like this initializer, but it is necessary to compile, and will be overwritten
        // during the didMove function.
        self.gameScene = GameScene(size: CGSize(width: 0, height: 0))
        super.init(coder: aDecoder)
    }
    
    /**
     Creates the labels / buttons for the main menu if they haven't already been created
     - Parameter view: the SKView that wwe have moved to
     */
    override func didMove(to view: SKView) {
        if (!self.menuCreated) {
            self.gameScene = GameScene(size: self.size)
            createMenu()
            self.menuCreated = true
        }
    }
    
    func createMenu() {
        // create a label for the game
        // Go to http://iosfonts.com/ for a list of all fonts we can use
        let titleLabel = SKLabelNode(fontNamed: "DINCondensed-Bold")
        titleLabel.fontSize = 50
        titleLabel.fontColor = SKColor.white
        titleLabel.text = "Space Invaders"
        // put the title in the exact center
        titleLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        
        // Create a label allowing the user to begin the game
        let playLabel = SKLabelNode(fontNamed: "Courier")
        playLabel.fontSize = 25
        playLabel.fontColor = SKColor.white
        playLabel.text = "Begin"
        playLabel.name = self.BEGIN_NAME
        playLabel.position = CGPoint(x: self.size.width / 2,
                                     y: titleLabel.frame.minY - self.LABEL_OFFSETS - playLabel.frame.size.height / 2)
        
        // Create a label which tells the user their current high score
        let highScore = self.gameScene.loadHighScore()
        let highScoreLabel = SKLabelNode(fontNamed: "Courier")
        highScoreLabel.fontSize = 25
        highScoreLabel.fontColor = SKColor.white
        highScoreLabel.text = String(format: "Current High Score: %04u", highScore)
        highScoreLabel.position = CGPoint(x: self.size.width / 2,
                                          y: playLabel.frame.minY - self.LABEL_OFFSETS - playLabel.frame.size.height / 2)
        
        // add all the labels to the scene
        self.addChild(titleLabel)
        self.addChild(playLabel)
        self.addChild(highScoreLabel)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNode = atPoint(location)
            if touchedNode.name == self.BEGIN_NAME {
                // navigate to the game scene
                gameScene.scaleMode = .aspectFill
                self.view?.presentScene(gameScene, transition: SKTransition.doorway(withDuration: 1.3))
            }
        }
    }

}
