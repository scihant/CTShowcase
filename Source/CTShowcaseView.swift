//
//  CTShowcaseView.swift
//  CTShowcase
//
//  Created by Cihan Tek on 17/12/15.
//  Copyright © 2015 Cihan Tek. All rights reserved.
//

import UIKit

/// A class that highligts a given view in the layout
@objcMembers
open class CTShowcaseView: UIView {

    private struct CTGlobalConstants {
        static let DefaultAnimationDuration = 0.5
    }

    // MARK: Properties
   
    /// Label used to display the title
    public let titleLabel: UILabel
    
    // Label used to display the message
    public let messageLabel: UILabel
    
    // Highlighter object that creates the highlighting effect
    public var highlighter: CTRegionHighlighter = CTStaticGlowHighlighter()
    
    private let containerView: UIView = UIApplication.shared.keyWindow!
    private var targetView: UIView?
    private var targetRect: CGRect = CGRect.zero
    
    private var willShow = true
    private var title = "title"
    private var message = "message"
    private var key: String?
    private var dismissHandler: (() -> ())?
    
    private var targetOffset = CGPoint.zero
    private var targetMargin: CGFloat = 0
    private var effectLayer : CALayer?
    
    private var previousSize = CGSize.zero
    private var observing = false
    
    // MARK: Class lifecyle
    
    /**
    Setup showcase to highlight a view on the screen
    
    - parameter title: Title to display in the showcase
    - parameter message: Message to display in the showcase
    */
    public convenience init(title: String, message: String) {
        self.init(title: title, message: message, key: nil, dismissHandler: nil)
    }
    
    /**
    Setup showcase to highlight a view on the screen
    
    - parameter title: Title to display in the showcase
    - parameter message: Message to display in the showcase
    - parameter key: An optional key to prevent the showcase from getting displayed again if it was displayed before
    - parameter dismissHandler: An optional handler to be executed after the showcase is dismissed by tapping
    */
    public init(title: String, message: String, key: String?, dismissHandler: (() -> Void)?) {

        titleLabel = UILabel(frame: CGRect.zero)
        messageLabel = UILabel(frame: CGRect.zero)

        super.init(frame: CGRect.zero)
        
        if let storageKey = key, let _ = UserDefaults.standard.object(forKey: storageKey) {
            willShow = false
            return
        }
    
        self.title = title
        self.message = message
        self.key = key
        self.dismissHandler = dismissHandler
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
        
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = true
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.text = title
        addSubview(titleLabel)
        
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = true
        messageLabel.textColor = UIColor.lightGray
        messageLabel.font = UIFont.boldSystemFont(ofSize: 18)
        messageLabel.textAlignment = .center
        messageLabel.text = message
        addSubview(messageLabel)
        
        NotificationCenter.default.addObserver(self, selector: #selector(CTShowcaseView.enteredForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Should be instantiated from code.")
    }

    deinit {
        if observing {
            targetView?.removeObserver(self, forKeyPath: "frame")
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Client interface

    /**
    Setup showcase to highlight a view on the screen
    
    - parameter view: View to highlight
    - parameter offset: The offset to apply to the highlight relative to the views location
    - parameter margin: Distance between the highlight border and the view
    */
    @objc(setupForView:offset:margin:)
    public func setup(for view: UIView, offset: CGPoint, margin: CGFloat) {
        guard willShow == true else {return}
        
        targetView = view
        targetOffset = offset
        targetMargin = margin
        
        guard let targetView = targetView else {return}
        
        targetRect = targetView.convert(targetView.bounds, to: containerView)
        targetRect = targetRect.offsetBy(dx: offset.x, dy: offset.y)
        targetRect = targetRect.insetBy(dx: -margin, dy: -margin)
        
        // If less than %75 of the target area is inside the container, dismiss the showcase automatically
        let overlapRegion = containerView.bounds.intersection(targetRect)
        let overlapSize = overlapRegion.width * overlapRegion.height
        let targetSize = targetRect.width * targetRect.height
        
        if overlapSize/targetSize < 0.75 {
            dismiss()
            return
        }
        
        let (titleRegion, messageRegion) = textRegionsForHighlightedRect(targetRect)
        
        titleLabel.frame = titleRegion
        messageLabel.frame = messageRegion

        updateEffectLayer()
        setNeedsDisplay()
        
        // If the frame of the targetView changes, the showcase needs to be updated accordingly
        if !observing {
            targetView.addObserver(self, forKeyPath: "frame", options: .init(rawValue: 0), context: nil)
            observing = true
        }
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        setup(for: targetView!, offset: targetOffset, margin: targetMargin)
    }
    
    /**
    Setup showcase to highlight a view on the screen with no offset and margin
     
    - parameter view: View to highlight
    */
    @objc(setupForView:)
    public func setup(for view: UIView) {
        setup(for: view, offset: targetOffset, margin: targetMargin)
    }
    
    /**
    Setup showcase to highlight a UIBarButtonItem on the screen
     
     - parameter barButtonItem: UIBarButtonItem to highlight
     - parameter offset: The offset to apply to the highlight relative to the views location
     - parameter margin: Distance between the highlight border and the view
     */
    @objc(setupForBarButtonItem:offset:margin:)
    public func setup(for barButtonItem: UIBarButtonItem, offset: CGPoint, margin: CGFloat) {
        if let view = barButtonItem.value(forKey: "view") as? UIView {
            setup(for: view, offset: offset, margin: margin)
        }
    }
    
    /**
    Setup showcase to highlight a UIBarButtonItem with no offset and margin
     
    - parameter barButtonItem: UIBarButtonItem to highlight
    */
    @objc(setupForBarButtonItem:)
    public func setup(for barButtonItem: UIBarButtonItem) {
        setup(for: barButtonItem, offset: targetOffset, margin: targetMargin)
    }
    
    
    /// Displays the showcase. The showcase needs to be setup before calling this method using one of the setup methods
    public func show() {
        guard willShow == true else {return}
        
        containerView.addSubview(self)
        
        let views = ["self": self]
        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "|[self]|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|[self]|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: views)
        containerView.addConstraints(constraints)
        
        // Show the showcase with a fade-in animation
        alpha = 0
        UIView.animate(withDuration: CTGlobalConstants.DefaultAnimationDuration, animations: { () -> () in
            self.alpha = 1
        }) 
        
        // Mark the showcase as "displayed" if needed
        if let storageKey = key {
            UserDefaults.standard.set(true, forKey: storageKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    open func dismiss() {
        UIView.animate(withDuration: CTGlobalConstants.DefaultAnimationDuration, animations: { () -> Void in
            self.alpha = 0
        }, completion: { (finished) -> Void in
            self.removeFromSuperview()
            self.dismissHandler?()
        })
    }

    // MARK: Private methods
    
    private func updateEffectLayer() {
        // Remove the effect layer if exists
        effectLayer?.removeFromSuperlayer()
        
        // Add a new one if the new highlighter provides one
        if let layer = highlighter.layer(for: targetRect){
            self.layer.addSublayer(layer)
            effectLayer = layer
        }
    }
    
    private func textRegionsForHighlightedRect(_ rect: CGRect) -> (CGRect, CGRect) {
    
        let margin: CGFloat = 15.0
        let spacingBetweenTitleAndText: CGFloat = 10.0
        
        let titleSize = titleLabel.sizeThatFits(CGSize(width: containerView.frame.size.width - 2 * margin, height: CGFloat.greatestFiniteMagnitude))
        let messageSize = messageLabel.sizeThatFits(CGSize(width: containerView.frame.size.width - 2 * margin, height: CGFloat.greatestFiniteMagnitude))
        
        let textRegionWidth = containerView.frame.size.width - 2 * margin
        let textRegionHeight = titleSize.height + messageSize.height + spacingBetweenTitleAndText
    
        let spacingBelowHighlight = containerView.frame.size.height - targetRect.origin.y - targetRect.size.height
        var originY :CGFloat
        
        // If there is more space above the highlight than below, then display the text above the highlight, else display it below
        if (targetRect.origin.y > spacingBelowHighlight) {
            originY = targetRect.origin.y - textRegionHeight - margin * 2
        }
        else {
            originY = targetRect.origin.y + targetRect.size.height + margin * 2
        }
        
        let titleRegion = CGRect(x: margin, y: originY, width: textRegionWidth, height: titleSize.height)
        let messageRegion = CGRect(x: margin, y: originY + spacingBetweenTitleAndText + titleSize.height, width: textRegionWidth, height: messageSize.height)
   
        return (titleRegion, messageRegion)
    }
    
    // MARK: Overridden methods
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let ctx = UIGraphicsGetCurrentContext() else {return}

        // Draw the highlight using the given highlighter
        highlighter.draw(on: ctx, rect: targetRect)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        // Don't do anything unless the bounds have changed
        guard bounds.size.width != previousSize.width || bounds.size.height != previousSize.height else { return }
        
        if let targetView = targetView {
            setup(for: targetView)
            setNeedsDisplay()
        }
        previousSize = bounds.size
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismiss()
    }
    
    // MARK: Notification handler
    
    @objc public func enteredForeground() {
        updateEffectLayer()
    }
}


