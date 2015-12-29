//
//  CTShowcaseView.swift
//  CTShowcase
//
//  Created by Cihan Tek on 17/12/15.
//  Copyright © 2015 Cihan Tek. All rights reserved.
//

import UIKit

/// A class that highligts a given view in the layout
@objc public class CTShowcaseView: UIView {

    // MARK: Properties
   
    /// Label used to display the title
    public let titleLabel: UILabel
    
    /// Label used to display the message
    public let messageLabel : UILabel
    
    /// Highlighter object that creates the highlighting effect
    public var highlighter : CTRegionHighlighter = CTStaticGlowHighlighter()
    
    private let containerView: UIView = (UIApplication.sharedApplication().delegate!.window!)!
    private var targetView : UIView!
    private var targetRect : CGRect!
    
    private var willShow = true
    private var title, message : String
    private var key : String?
    private var dismissHandler : (() -> Void)?
    
    private var targetOffset = CGPointZero
    private var targetMargin: CGFloat = 0
    private var effectLayer : CALayer?
    
    // MARK: Class lifecyle
    
    /**
    Setup showcase to highlight a view on the screen
    
    - parameter title: Title to display in the showcase
    - parameter message: Message to display in the showcase
    */
    public convenience init(withTitle title: String, message: String) {
        self.init(withTitle: title, message: message, key: nil, dismissHandler: nil)
    }
    
    /**
    Setup showcase to highlight a view on the screen
    
    - parameter title: Title to display in the showcase
    - parameter message: Message to display in the showcase
    - parameter key: An optional key to prevent the showcase from getting displayed again if it was displayed before
    - parameter dismissHandler: An optional handler to be executed after the showcase is dismissed by tapping
    */
    public init(withTitle title: String, message: String, key: String?, dismissHandler: (() -> Void)?) {

        titleLabel = UILabel(frame: CGRectZero)
        messageLabel = UILabel(frame: CGRectZero)

        if let storageKey = key, _ = NSUserDefaults.standardUserDefaults().objectForKey(storageKey) {
            willShow = false
        }
        
        self.title = title
        self.message = message
        self.key = key
        self.dismissHandler = dismissHandler
        
        super.init(frame: CGRectZero)
    
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
        
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = true
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.font = UIFont.boldSystemFontOfSize(18)
        titleLabel.textAlignment = .Center
        titleLabel.text = title
        addSubview(titleLabel)
        
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = true
        messageLabel.textColor = UIColor.lightGrayColor()
        messageLabel.font = UIFont.boldSystemFontOfSize(18)
        messageLabel.textAlignment = .Center
        messageLabel.text = message
        addSubview(messageLabel)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "enteredForeground", name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: Client interface

    /**
    Setup showcase to highlight a view on the screen
    
    - parameter view: View to highlight
    - parameter offset: The offset to apply to the highlight relative to the views location
    - parameter margin: Distance between the highlight border and the view
    */
    public func setupShowcaseForView(view: UIView, offset: CGPoint, margin: CGFloat) {
    
        targetView = view
        targetOffset = offset
        targetMargin = margin
    
        targetRect = targetView.convertRect(targetView.bounds, toView: containerView)

        targetRect = CGRectOffset(targetRect, offset.x, offset.y)
        targetRect = CGRectInset(targetRect, -margin, -margin)
        
        let (titleRegion, messageRegion) = textRegionsForHighlightedRect(targetRect)
        
        titleLabel.frame = titleRegion
        messageLabel.frame = messageRegion

        updateEffectLayer()
    }
    
    /**
    Setup showcase to highlight a view on the screen with no offset and margin
     
    - parameter view: View to highlight
    */
    public func setupShowcaseForView(view: UIView) {
        setupShowcaseForView(view, offset: targetOffset, margin: targetMargin)
    }
    
    /**
    Setup showcase to highlight a UIBarButtonItem on the screen
     
     - parameter item: UIBarButtonItem to highlight
     - parameter offset: The offset to apply to the highlight relative to the views location
     - parameter margin: Distance between the highlight border and the view
     */
    public func setupShowcaseForBarButtonItem(item: UIBarButtonItem, offset: CGPoint, margin: CGFloat) {
        if let view = item.valueForKey("view") as? UIView {
            setupShowcaseForView(view, offset: offset, margin: margin)
        }
    }
    
    /**
    Setup showcase to highlight a UIBarButtonItem with no offset and margin
     
    - parameter view: View to highlight
    */
    public func setupShowcaseForBarButtonItem(item: UIBarButtonItem) {
        setupShowcaseForBarButtonItem(item, offset: targetOffset, margin: targetMargin)
    }
    
    
    /// Displays the showcase. The showcase needs to be setup before calling this method
    public func show() {
        
        if (!willShow) {
            return
        }
        
        // Show the showcase with a fade-in animation
        self.alpha = 0
        
        containerView.addSubview(self)
        
        let views = ["self": self]
        var constraints = NSLayoutConstraint.constraintsWithVisualFormat("|[self]|", options: .DirectionLeadingToTrailing, metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|[self]|", options: .DirectionLeadingToTrailing, metrics: nil, views: views)
        
        containerView.addConstraints(constraints)
        
        UIView.animateWithDuration(CTGlobalConstants.DefaultAnimationDuration) { () -> Void in
            self.alpha = 1
        }
        
        // Mark the showcase as "displayed"
        if let storageKey = key {
            NSUserDefaults.standardUserDefaults().setObject(true, forKey: storageKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }

    // MARK: Private methods
    
    private func updateEffectLayer() {
        // Remove the effect layer
        effectLayer?.removeFromSuperlayer()
        
        // add a new one if the new highlighter provides one
        if let layer = highlighter.layerForRect(targetRect){
            self.layer.addSublayer(layer)
            effectLayer = layer
        }
        
    }
    
    private func textRegionsForHighlightedRect(rect: CGRect) -> (CGRect, CGRect) {
    
        let margin: CGFloat = 15.0
        let spacingBetweenTitleAndText: CGFloat = 10.0
        
        let titleSize = titleLabel.sizeThatFits(CGSize(width: containerView.frame.size.width - 2 * margin, height: CGFloat.max))
        let messageSize = messageLabel.sizeThatFits(CGSize(width: containerView.frame.size.width - 2 * margin, height: CGFloat.max))
        
        let textRegionWidth = containerView.frame.size.width - 2 * margin
        let textRegionHeight = titleSize.height + messageSize.height + spacingBetweenTitleAndText
    
        let spacingBelowHighlight = containerView.frame.size.height - targetRect.origin.y - targetRect.size.height
        var originY :CGFloat
        
        // If there is more space above the highlight than below, then display the text above the highlight, else display it below
        if (targetRect.origin.y > spacingBelowHighlight) {
            originY = targetRect.origin.y - textRegionHeight - margin*2
        }
        else {
            originY = targetRect.origin.y + targetRect.size.height + margin*2
        }
        
        let titleRegion = CGRect(x: margin, y: originY, width: textRegionWidth, height: titleSize.height)
        let messageRegion = CGRect(x: margin, y: originY + spacingBetweenTitleAndText + titleSize.height, width: textRegionWidth, height: messageSize.height)
   
    
        return (titleRegion, messageRegion)
    }
    
    
    // MARK: Overridden methods
    
    override public func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        let ctx = UIGraphicsGetCurrentContext()

        // Draw the highlight using the given highlighter
        highlighter.drawOnContext(ctx, targetRect: targetRect)
    }
    
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        setupShowcaseForView(targetView)
        setNeedsDisplay()
    }
    
    
    override public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        UIView.animateWithDuration(CTGlobalConstants.DefaultAnimationDuration, animations: { () -> Void in
            self.alpha = 0
            }, completion: { (finished) -> Void in
                self.removeFromSuperview()
                self.dismissHandler?()
        })
    }
    
    // MARK: Notification handler
    
    public func enteredForeground() {
        updateEffectLayer()
    }
}

struct CTGlobalConstants {
    static let DefaultAnimationDuration = 0.5
}


