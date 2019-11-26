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
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
        // Create and configure the scene.
        let scene = GameScene(size: skView.frame.size)
        skView.presentScene(scene)
        
        // TODO Pause the view (and thus the game) when the app is interrupted or backgrounded
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    @objc func handleApplicationWillResignActive (_ note: Notification) {
        let skView = self.view as! SKView
        skView.isPaused = true
    }
    
    @objc func handleApplicationDidBecomeActive (_ note: Notification) {
        let skView = self.view as! SKView
        skView.isPaused = false
    }
}
