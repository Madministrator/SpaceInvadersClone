//
//  GameViewController.swift
//  SpaceInvadersClone
//
//  Created by Vander Hoeven, Evan on 11/7/19.
//  Copyright © 2019 Vander Hoeven, Evan. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view.
        let skView = self.view as! SKView
        skView.showsFPS = false
        skView.showsNodeCount = false
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
        // Create and configure the scene.
        let scene = MainMenuScene(size: skView.frame.size)
        skView.presentScene(scene)
    }
    
    /**
     Tells the operating system that we would like the status bar with icons such as the battery
     hidden from view. The operating system can ignore this statement.
     */
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    /**
     Tells the operating system that we should not enable rotation while in this view.
     */
    override var shouldAutorotate: Bool {
        return false
    }
    
    /**
     Informs the operating system of which orientations this view controller supports.
     */
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    /**
     Notified when the application has lost focus, this function pauses the game so that it doesn't run
     in the background when the app is not the user's primary focus.
     */
    @objc func handleApplicationWillResignActive (_ note: Notification) {
        let skView = self.view as! SKView
        skView.isPaused = true
    }
    
    /**
     Notified when the application has gained focus, this function resumes the game so that it resumes
     activity when the user has entered the application.
     */
    @objc func handleApplicationDidBecomeActive (_ note: Notification) {
        let skView = self.view as! SKView
        skView.isPaused = false
    }
}
