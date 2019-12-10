//
//  GameOverScene.swift
//  SpaceInvadersClone
//
//  Created by Vander Hoeven, Evan on 11/12/19.
//  Copyright © 2019 Vander Hoeven, Evan. All rights reserved.
//

import UIKit
import SpriteKit

class GameOverScene : SKScene {
    
    // MARK: Private constants
    private let MAIN_MENU_NAME = "return to main menu"
    private let PLAY_AGAIN_NAME = "play again"
    private let SHARE_NAME = "share"
    // MARK: Private variables
    private var labelsCreated = false
    
    /**
     Creates the two labels for the game over scene if
     they haven't already been created.
     
     - Parameter view: the SKView that moved.
     */
    override func didMove(to view: SKView) {
        if (!self.labelsCreated) {
            self.createLabels()
            self.labelsCreated = true
        }
    }
    
    /**
     Creates two labels for when the game is over and adds them to the scene.
     */
    func createLabels() {
        // Create a label for game over
        let gameOverLabel = SKLabelNode(fontNamed: "Courier")
        gameOverLabel.fontSize = 50
        gameOverLabel.fontColor = SKColor.white
        gameOverLabel.text = "Game Over"
        // position the game over text in the center, two-thirds of the way up the screen.
        gameOverLabel.position = CGPoint(x: self.size.width / 2, y: 2.0 / 3.0 * self.size.height)
        // Add the game over label to the scene
        self.addChild(gameOverLabel)
        
        // Create a label allowing the user to play again
        let playAgainLabel = SKLabelNode(fontNamed: "Courier")
        playAgainLabel.fontSize = 25
        playAgainLabel.fontColor = SKColor.white
        playAgainLabel.text = "Play Again?"
        playAgainLabel.name = self.PLAY_AGAIN_NAME
        // position the label below the game over label
        playAgainLabel.position = CGPoint(x: self.size.width / 2, y: gameOverLabel.frame.origin.y - gameOverLabel.frame.size.height * 2)
        // add the play again label to the scene
        self.addChild(playAgainLabel)
        
        // Create a label allowing the user to return to the main menu
        let mainMenuLabel = SKLabelNode(fontNamed: "Courier")
        mainMenuLabel.fontSize = 25
        mainMenuLabel.fontColor = SKColor.white
        mainMenuLabel.text = "Return to main menu"
        mainMenuLabel.name = self.MAIN_MENU_NAME
        // position the label below the play again label
        mainMenuLabel.position = CGPoint(x: self.size.width / 2, y: playAgainLabel.frame.origin.y - mainMenuLabel.frame.size.height * 2)
        self.addChild(mainMenuLabel)
        
        // Create a button that allows a person to share their high score
        // ONLY if we have the data necessary to display the activityController
        if let _ = self.view {
            let shareLabel = SKLabelNode(fontNamed: "Courier")
            shareLabel.fontSize = 25
            shareLabel.fontColor = SKColor.white
            shareLabel.text = "Share your High Score"
            shareLabel.name = self.SHARE_NAME
            // position the label below the main menu label
            shareLabel.position = CGPoint(x: self.size.width / 2, y: mainMenuLabel.frame.origin.y - shareLabel.frame.size.height * 2)
            self.addChild(shareLabel)
        }
    }
    
    /**
     Handles the presses when the user has lifted their finger from a button.
     - Parameter touches: A set of UITouches which we check if they lie on any of our buttons.
     - Parameter event: An optional UIEvent, not used in this implementation.
     */
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)  {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNode = atPoint(location)
            if touchedNode.name == self.PLAY_AGAIN_NAME {
                // navigate to the game scene
                let gameScene = GameScene(size: self.size)
                gameScene.scaleMode = .aspectFill
                self.view?.presentScene(gameScene, transition: SKTransition.doorsCloseHorizontal(withDuration: 1.0))
            } else if touchedNode.name == self.MAIN_MENU_NAME {
                // navigate to the main menu
                let mainMenuScene = MainMenuScene(size: self.size)
                mainMenuScene.scaleMode = .aspectFill
                self.view?.presentScene(mainMenuScene, transition: SKTransition.doorway(withDuration: 1.0))
            } else if touchedNode.name == self.SHARE_NAME {
                shareHighScore()
            }
        }
    }
    
    /**
     Allows the user to share a brief message about their high score and the score they got in the game.
     */
    func shareHighScore() {
        // Create a message for the user to share.
        let gameScene = GameScene(size: self.size)
        let message = String(format: "Check out my high score in this space invaders clone! My high score is %04u", gameScene.loadHighScore())
        // Create an activity controller which can share the user's info.
        let activityController = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        activityController.popoverPresentationController?.sourceView = self.view
        // Present the activity controller to the user
        if let hostViewController = self.view?.window?.rootViewController {
            hostViewController.present(activityController, animated: true, completion: nil)
        }
    }
}
