# Bliss

Bliss is an easy way to present customizable menus in your iOS app.

![](https://github.com/implicityhq/bliss/blob/master/Screenshots/combined.png)

## Installation
Use Carthage to install Bliss.
```
github "ImplicityHQ/Bliss" "master"
```

Right now Bliss is still in active development, so beware of breaking changes

## Usage
Using Bliss is very easy.

```swift
var firstItem = Bliss.Item(displayName: "First Item") { () -> Void in
  self.textLabel.text = "Basic First"
}
firstItem.image = UIImage(named: "open")

var secondItem = Bliss.Item(displayName: "Second Item") { () -> Void in
	self.textLabel.text = "Basic Second"
}
secondItem.image = UIImage(named: "closed")

let theme = Bliss.Theme(placement: .Top)

let controller = Bliss.Controller(items: [firstItem, secondItem], theme: theme)
controller.title = "Basic Bliss"

self.presentViewController(controller, animated: true, completion: nil)
```
