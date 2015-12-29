//
//  ViewController.swift
//  CTShowcase
//
//  Created by Cihan Tek on 17/12/15.
//  Copyright © 2015 Cihan Tek. All rights reserved.
//

import UIKit
import CTShowcase

class ViewController: UIViewController {

    @IBOutlet weak var button: UIButton!
    var token: dispatch_once_t = 0
    
    override func viewDidAppear(animated: Bool) {
        
        dispatch_once(&token) {
            let showcase = CTShowcaseView(withTitle: "New Feature!", message: "Here's a brand new button you can tap!", key: nil) { () -> Void in
                print("dismissed")
            }
            
            let highlighter = CTDynamicGlowHighlighter()
            highlighter.highlightColor = UIColor.yellowColor()
            highlighter.animDuration = 0.5
            highlighter.glowSize = 5
            highlighter.maxOffset = 10
            
            showcase.highlighter = highlighter

            showcase.setupShowcaseForView(self.button, offset: CGPointZero, margin: 0)
            showcase.show()
        }
    }
}

