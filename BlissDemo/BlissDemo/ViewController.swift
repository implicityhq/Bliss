//
//  ViewController.swift
//  BlissDemo
//
//  Created by Jason Silberman on 3/3/16.
//  Copyright © 2016 Implicity. All rights reserved.
//

import UIKit
import Bliss

let redColor = UIColor(red: 255/255, green: 39/255, blue: 58/255, alpha: 1)
let blueColor = UIColor(red: 39/255, green: 125/255, blue: 255/255, alpha: 1)

class ViewController: UIViewController {
	
	@IBOutlet weak var textLabel: UILabel!
	
	@IBAction func showBasicDemo() {
		var firstItem = Bliss.Item(displayName: "First Item") { () -> Void in
			self.textLabel.text = "Basic First"
		}
		
		firstItem.image = UIImage(named: "open")
		
		var secondItem = Bliss.Item(displayName: "Second Item") { () -> Void in
			self.textLabel.text = "Basic Second"
		}
		
		secondItem.image = UIImage(named: "closed")
		
		let theme = Bliss.Theme(placement: .top)
		
		let controller = Bliss.Controller(items: [firstItem, secondItem], theme: theme)
		controller.title = "Basic Bliss"
		controller.navigationBar.tintColor = .white
		
		controller.navigationBar.barTintColor = blueColor
		
		self.present(controller, animated: true, completion: nil)
	}
	
	@IBAction func showMediumDemo() {
		let firstItem = Bliss.Item(displayName: "First Item") { () -> Void in
			self.textLabel.text = "Medium First"
		}
		
		let secondItem = Bliss.Item(displayName: "Second Item") { () -> Void in
			self.textLabel.text = "Medium Second"
		}
		
		var theme = Bliss.Theme(placement: .bottom)
		theme.cellSelectedColor = redColor
		theme.cellBackgroundColor = blueColor
		theme.textColor = .white
		
		let controller = Bliss.Controller(items: [firstItem, secondItem], theme: theme)
		controller.title = "Medium Bliss"
		controller.navigationBar.tintColor = blueColor
		
		self.present(controller, animated: true, completion: nil)
	}

}
