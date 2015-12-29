//
//  CTShowcaseHighlighter.swift
//  CTShowcase
//
//  Created by Cihan Tek on 21/12/15.
//  Copyright © 2015 Cihan Tek. All rights reserved.
//

import UIKit

public enum CTHighlightType {
    case Rect, Circle
}

/// Any class conforming to this protocol can be used as a highlighter by the ShowcaseView
@objc public protocol CTRegionHighlighter {
    
    /**
    This is the only method needed to draw static (non-animated) highlights.
    For static highlights, it should draw the highlight around the provided targetRect.
    For dynamic highlights, it usually should do nothing except clearing the region covering the
    view that's gonna be highlighted.
    targetRect is in the coordinate system of the ShowcaseView's layer.
     
     - parameter ctx: The drawing context of the entire ShowcaseView
     - parameter targetRect: The rectangular region within ctx to highlight.
    */
    func drawOnContext(ctx: CGContext?, targetRect: CGRect)
    
    /**
    ShowcaseView adds the layer returned form this method to its layer as a sublayer.
    Needs to return a non-nil value for animated highlights
     
    - parameter targetRect: The rectangular region within ctx to highlight.
    - returns: A layer that contains the highlight effect with or without animation
    */
    func layerForRect(targetRect: CGRect) -> CALayer?
}

/// Provides a dynamic glow highlight with animation
@objc public class CTDynamicGlowHighlighter: NSObject, CTRegionHighlighter {
    
// MARK: Properties
    
    /// The highlight color
    public var highlightColor = UIColor.yellowColor()
    
    /// Type of the highlight
    public var highlightType : CTHighlightType = .Rect
    
    /// The size of the glow around the highlight border
    public var glowSize: CGFloat = 5.0
    
    /// Maximum spacing between the highlight and the view it surrounds
    public var maxOffset: CGFloat = 10.0
    
    /// The duration of the animation in one direction (The full cycle will take 2x time)
    public var animDuration: CFTimeInterval = 0.5
    
    
// MARK: CTRegionHighlighter method implementations

    public func drawOnContext(ctx: CGContext?, targetRect: CGRect) {
        if (highlightType == .Rect) {
            
            CGContextClearRect(ctx, targetRect)
        }
        else {
            let maxDim = max(targetRect.size.width, targetRect.size.height)
            let radius = maxDim/2 + 1;
            
            CGContextSetBlendMode(ctx, .Clear)
            CGContextAddArc(ctx, CGRectGetMidX(targetRect), CGRectGetMidY(targetRect), radius, 0, 2 * CGFloat(M_PI), 1)//let maxDim = max(layer.bounds.size.width, layer.bounds.size.height)
            CGContextFillPath(ctx)
            CGContextSetBlendMode(ctx, .Normal)
        }
    }
    
    public func layerForRect(targetRect: CGRect) -> CALayer? {
        
        // Create a shape layer that's gonna be used as the highlight effect
        let layer = CAShapeLayer()
        layer.frame = targetRect
        layer.contentsScale = UIScreen.mainScreen().scale

        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.strokeColor = highlightColor.CGColor
        layer.fillColor = UIColor.clearColor().CGColor
        layer.shadowColor = highlightColor.CGColor
        layer.lineWidth = 3
        layer.shadowOpacity = 1
        
        // Create the shrinked and grown versions of the path
        var innerPath : UIBezierPath
        var outerPath : UIBezierPath
        
        if (highlightType == .Rect) {
            innerPath = UIBezierPath(rect: layer.bounds)
            outerPath = UIBezierPath(rect: CGRectInset(layer.bounds, -maxOffset, -maxOffset))
        }
        else {
            let maxDim = max(layer.bounds.size.width, layer.bounds.size.height)
            
            let radius = maxDim/2 + 1;
            let center = CGPoint(x: layer.bounds.size.width / 2, y: layer.bounds.size.height / 2)
            
            innerPath = UIBezierPath()
            innerPath.addArcWithCenter(center, radius: radius, startAngle: 0, endAngle: 2 * CGFloat(M_PI), clockwise: true)

            outerPath = UIBezierPath()
            outerPath.addArcWithCenter(center, radius: radius + maxOffset, startAngle: 0, endAngle: 2 * CGFloat(M_PI), clockwise: true)
        }
        
        
        // Grow and shrink the path with animation
        let pathAnim = CABasicAnimation()
        pathAnim.keyPath = "path"
        pathAnim.fromValue = innerPath.CGPath
        pathAnim.toValue = outerPath.CGPath
        
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
        
        layer.addAnimation(animGroup, forKey: nil)
    
        return layer
    }
}

/// Provides a static glow highlight with no animation
@objc public class CTStaticGlowHighlighter: NSObject, CTRegionHighlighter {
    
// MARK: Properties
    
    /// The highlight color
    public var highlightColor = UIColor.yellowColor()
    
    /// Type of the highlight
    public var highlightType : CTHighlightType = .Rect
    
// MARK: CTRegionHighlighter method implementations
    
    public func drawOnContext(ctx: CGContext?, targetRect: CGRect) {
        
        CGContextSetLineWidth(ctx, 2.0)
        CGContextSetShadowWithColor(ctx, CGSizeZero, 30.0, highlightColor.CGColor)
        CGContextSetStrokeColorWithColor(ctx, highlightColor.CGColor)
        
        if (highlightType == .Rect) {
            
            // Draw the rect and its shadow
            CGContextAddPath(ctx, UIBezierPath(rect: targetRect).CGPath)
            CGContextDrawPath(ctx, .FillStroke)
            
            // Clear the inner region to prevent the highlighted region from being covered by the highlight
            CGContextSetFillColorWithColor(ctx, UIColor.clearColor().CGColor)
            CGContextSetBlendMode(ctx, .Clear)
            CGContextAddRect(ctx, targetRect)
            CGContextDrawPath(ctx, .Fill)
        }
        else {
            let radius = targetRect.size.width/2 + 1;
            let center = CGPoint(x: targetRect.origin.x + targetRect.size.width / 2, y: targetRect.origin.y + targetRect.size.height / 2.0)
            
            // Draw the circle and its shadow
            CGContextAddArc(ctx, center.x, center.y, radius, 0, 2 * CGFloat(M_PI), 0)
            CGContextDrawPath(ctx, .FillStroke)

            // Clear the inner region to prevent the highlighted region from being covered by the highlight
            CGContextSetFillColorWithColor(ctx, UIColor.clearColor().CGColor)
            CGContextSetBlendMode(ctx, .Clear)
            CGContextAddArc(ctx, center.x, center.y, radius - 0.5, 0, 2 * CGFloat(M_PI), 0)
            CGContextDrawPath(ctx, .Fill)
        }
    }
    
    public func layerForRect(targetRect: CGRect) -> CALayer? {
        return nil
    }
}
