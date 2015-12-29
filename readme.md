# CTShowcase

[![CI Status](http://img.shields.io/travis/scihant/CTShowcase.svg?style=flat)](https://travis-ci.org/scihant/CTShowcase)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/CTShowcase.svg)](https://img.shields.io/cocoapods/v/CTShowcase.svg)
[![Issues](https://img.shields.io/github/issues/scihant/CTShowcase.svg?style=flat)](http://www.github.com/scihant/CTShowcase/issues?state=open)

CTShowcase is a showcase library for iOS that lets you to highlight individual views in your app using static or dynamic effects.

## Installation

#### Using CocoaPods

You can install CTShowcase using [CocoaPods](http://cocoapods.org). To install it,  add the following line to your Podfile:

    pod "iShowcase", "~> 1.0"

#### Manual Install

Just add the files `CTShowcaseView.swift` and `CTRegionHighlighter.swift` to your project

#### Running the Example project

Navigate to the Example directory and type: 
	
	pod install

Then you can use the .workspace file to open and run the example. 

## Usage

The usage of CTShowcase is very simple.

Create an instance of `CTShowcaseView`

```swift
let showcase = CTShowcaseView(withTitle: "New Feature", message: "Here's a brand new button you can tap!", key: @"displayed") { () -> Void in
                print("This closure will be executed after the user dismisses the showcase")
            }
```

Setup the showcase for a view available in your layout

```swift
showcase.setupShowcaseForView(newButton)
```

and finally, show the showcase

```swift
showcase.show()
```

That's it! `CTShowcaseView` will automatically determine the best location to display the title and message.

You can dismiss the showcase by tapping anywhere on it. 

`CTShowcaseView` will use the `key` parameter to determine whether the showcase was displayed before, and won't display it again if it was. If you want the showcase to be displayed more than once, pass `nil` as the key. Similarly, if you don't need to do anything within the closure, pass it as `nil` as well.

Or you can simply use the provided convenience initializer:

```swift
let showcase = CTShowcaseView(withTitle: "New Feature", message: "Here's a brand new button you can tap!")
```

You can optionally give an offset and margin value when setting up a showcase by using the following method instead of `setupShowcaseForView(_:)`

```swift
showcase.setupShowcaseForView(self.button, offset: CGPointZero, margin: 5)
```

Offset will determine how much the highlight will be shifted relative to the location of the target view.
Margin determines the spacing between the borders of the target view and the inside border of the highlight.

## Configuration

`CTShowcaseView` exposes the labels it uses to display the title and message as properties.
Therefore you can set their properties such as the font or color by accessing them directly.

```swift
showcase.titleLabel.font = boldSystemFontOfSize(15)
showcase.messageLabel.textColor = UIColor.yellowColor()
```

`CTShowcaseView` uses an instance of a class conforming to the `CTRegionHighlighter` protocol to draw its highlight.

CTShowcase comes with two classes that already conform to his protocol so that you don't have to create one your own to start using it. These classes are: `CTStaticGlowHighlighter` and `CTDynamicGlowHighlighter`. Each one can draw a rectangular or circular highlight and has other properties that allows you to customize their appearance.

###CTStaticGlowHighlighter

This is the default highlighter used by the `CTShowcaseView`. It draws non-animated highlights.
You can customize its properties before setting up the showcase if you don't like their defaults.

```swift
let showcase = CTShowcaseView(withTitle: "New Feature", message: "Here's a brand new button you can tap!")

let highlighter = showcase.highlighter as! CTStaticGlowHighlighter

highlighter.highlightColor = UIColor.yellowColor()

showcase.setupShowcaseForView(self.button, offset: CGPointZero, margin: 5)
showcase.show()
```
The result will look like this:ön

![Static Highlight](https://s3.amazonaws.com/tek-files/static.png)

###CTDynamicGlowHighlighter

This is the animated version of the static highlighter. In order to use it, create an instance and set it as the highlighter of your `CTShowcaseView` instance 

```swift
let showcase = CTShowcaseView(withTitle: "New Feature", message: "Here's a brand new button you can tap!")

let highlighter = CTDynamicGlowHighlighter()

// Configure its parameters if you don't like the defaults
highlighter.highlightColor = UIColor.yellowColor()
highlighter.animDuration = 0.5
highlighter.glowSize = 5
highlighter.maxOffset = 10

// Set it as the highlighter
showcase.highlighter = highlighter

showcase.setupShowcaseForView(self.button)
showcase.show()
```

The resulting effect will look like this:

![Dynamic Rectangular Highlight](https://s3.amazonaws.com/tek-files/dynamic_rect.gif)

If you set its type to circular 

```swift
highlighter.highlightType = .Circle
```

You'll end up with a circular highlight as shown below

![Dynamic Circular Highlight](https://s3.amazonaws.com/tek-files/dynamic_circle.gif)

## Extending CTShowcase

The classes provided with CTShowcase should be sufficient for most applications, but in case you want to add different highlight effects, that's easy to do as well.

Just create a new class conforming to the `CTRegionHighlighter` protocol and use it as the highlighter of the `CTShowcaseView` instance. Check the comments in the code to find out what the `drawOnContext(_:targetRect)` and  `layerForRect(_:)` methods in the protocol should do.
