//
//  CTShowcaseHighlighter.swift
//  CTShowcase
//
//  Created by Cihan Tek on 21/12/15.
//  Copyright © 2015 Cihan Tek. All rights reserved.
//

import UIKit

@objc public enum CTHighlightType : Int {
    case rect, circle
}

/// Any class conforming to this protocol can be used as a highlighter by the ShowcaseView
@objc public protocol CTRegionHighlighter {
    
    /**
    This is the only method needed to draw static (non-animated) highlights.
    For static highlights, it should draw the highlight around the provided rect.
    For dynamic highlights, it usually should do nothing except clearing the region covering the
    view that's gonna be highlighted.
    rect is in the coordinate system of the ShowcaseView's layer.
     
     - parameter context: The drawing context of the entire ShowcaseView
     - parameter rect: The rectangular region within the context to highlight.
    */
    func draw(on context: CGContext, rect: CGRect)
    
    /**
    ShowcaseView adds the layer returned form this method to its layer as a sublayer.
    Needs to return a non-nil value for animated highlights
     
    - parameter rect: The rectangular region within ctx to highlight.
    - returns: A layer that contains the highlight effect with or without animation
    */
    func layer(for rect: CGRect) -> CALayer?
}

/// Provides a dynamic glow highlight with animation
@objcMembers
public class CTDynamicGlowHighlighter: NSObject, CTRegionHighlighter {
    
// MARK: Properties
    
    /// The highlight color
    public var highlightColor = UIColor.yellow
    
    /// Type of the highlight
    public var highlightType: CTHighlightType = .rect
    
    /// The size of the glow around the highlight border
    public var glowSize: CGFloat = 5.0
    
    /// Maximum spacing between the highlight and the view it highlights
    public var maxOffset: CGFloat = 10.0
    
    /// The duration of the animation in one direction (The full cycle will take 2x time)
    public var animDuration: CFTimeInterval = 0.5
    
    
// MARK: CTRegionHighlighter method implementations

    public func draw(on context: CGContext, rect: CGRect) {
        if (highlightType == .rect) {
            context.clear(rect)
        }
        else {
            let maxDim = max(rect.size.width, rect.size.height)
            let radius = maxDim/2 + 1;
            let center = CGPoint(x: rect.midX, y: rect.midY)
            context.setBlendMode(.clear)
            context.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            context.fillPath()
            context.setBlendMode(.normal)
        }
    }
    
    public func layer(for rect: CGRect) -> CALayer? {
        
        // Create a shape layer that's gonna be used as the highlight effect
        let layer = CAShapeLayer()
        
        layer.frame = rect
        layer.contentsScale = UIScreen.main.scale
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.strokeColor = highlightColor.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.shadowColor = highlightColor.cgColor
        layer.lineWidth = 3
        layer.shadowOpacity = 1
        
        // Create the shrinked and grown versions of the path
        var innerPath: UIBezierPath
        var outerPath: UIBezierPath
        
        if (highlightType == .rect) {
            innerPath = UIBezierPath(rect: layer.bounds)
            outerPath = UIBezierPath(rect: layer.bounds.insetBy(dx: -maxOffset, dy: -maxOffset))
        }
        else {
            let maxDim = max(layer.bounds.size.width, layer.bounds.size.height)
            
            let radius = maxDim/2 + 1;
            let center = CGPoint(x: layer.bounds.size.width / 2, y: layer.bounds.size.height / 2)
            
            innerPath = UIBezierPath()
            innerPath.addArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)

            outerPath = UIBezierPath()
            outerPath.addArc(withCenter: center, radius: radius + maxOffset, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }
        
        // Grow and shrink the path with animation
        let pathAnim = CABasicAnimation()
        pathAnim.keyPath = "path"
        pathAnim.fromValue = innerPath.cgPath
        pathAnim.toValue = outerPath.cgPath
        
        // Animate the size of the glow according to the distance between the highlight's inside border and the region that's being highlighted.
        // As the border grows, so will the glow, and vice-versa
        
        let glowAnim = CABasicAnimation()
        glowAnim.keyPath = "shadowRadius"
        glowAnim.fromValue = 0
        glowAnim.toValue = glowSize

        // Group the two animations created above and add the group to the layer
        let animGroup = CAAnimationGroup()
        animGroup.repeatCount = Float.infinity
        animGroup.duration = animDuration
        animGroup.autoreverses = true
        animGroup.animations = [pathAnim, glowAnim]
        
        layer.add(animGroup, forKey: nil)
    
        return layer
    }
}

/// Provides a static glow highlight with no animation
@objcMembers
public class CTStaticGlowHighlighter: NSObject, CTRegionHighlighter {
    
// MARK: Properties
    
    /// The highlight color
    public var highlightColor = UIColor.yellow
    
    /// Type of the highlight
    public var highlightType : CTHighlightType = .rect
    
// MARK: CTRegionHighlighter method implementations
    
    public func draw(on context: CGContext, rect: CGRect) {
        
        context.setLineWidth(2.0)
        context.setShadow(offset: CGSize.zero, blur: 30.0, color: highlightColor.cgColor)
        context.setStrokeColor(highlightColor.cgColor)
        
        if (highlightType == .rect) {
            
            // Draw the rect and its shadow
            context.addPath(UIBezierPath(rect: rect).cgPath)
            context.drawPath(using: .fillStroke)
            
            // Clear the inner region to prevent the highlighted region from being covered by the highlight
            context.setFillColor(UIColor.clear.cgColor)
            context.setBlendMode(.clear)
            context.addRect(rect)
            context.drawPath(using: .fill)
        }
        else {
            let radius = rect.size.width/2 + 1;
            let center = CGPoint(x: rect.origin.x + rect.size.width / 2, y: rect.origin.y + rect.size.height / 2.0)
            
            // Draw the circle and its shadow
            context.addArc(center: center, radius: radius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: false)
            context.drawPath(using: .fillStroke)

            // Clear the inner region to prevent the highlighted region from being covered by the highlight
            context.setFillColor(UIColor.clear.cgColor)
            context.setBlendMode(.clear)
            context.addArc(center: center, radius: radius - 0.5, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: false)
            context.drawPath(using: .fill)
        }
    }
    
    public func layer(for rect: CGRect) -> CALayer? {
        return nil
    }
}
