//
//  Bliss.swift
//  Bliss
//
//  Created by Jason Silberman on 3/3/16.
//  Copyright © 2016 Implicity. All rights reserved.
//

import UIKit

public class Bliss {
	// MARK: - Components
	
	public struct Item {
		public let displayName: String
		
		public var image: UIImage?
		
		public let action: () -> Void
		
		public init(displayName: String, action: () -> Void) {
			self.displayName = displayName
			self.action = action
		}
	}
	
	public enum Placement {
		case Top
		case Bottom
	}
	
	public enum AnimationStyle {
		case Slide
		case Fade
	}
	
	public struct Theme {
		public var placement: Placement
		public var animationStyle: AnimationStyle = .Slide
		public var presentationTransitionDuration: NSTimeInterval = 0.55
		public var dismissingTransitionDuration: NSTimeInterval = 0.35
		public var textColor: UIColor = .blackColor()
		public var cellBackgroundColor: UIColor = .whiteColor()
		public var cellSelectedColor: UIColor = .lightGrayColor()
		public var textAlignment: NSTextAlignment = .Left
		public var barVisible: Bool = true
		public var tableViewRowHeight: CGFloat = Constants.tableViewRowHeight
		public var statusBarVisible: Bool = true
		public var barStyle: UIBarStyle = .Black
		
		public init(placement: Placement) {
			self.placement = placement
		}
	}
	
	public class TransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
		public let reverse: Bool
		public let theme: Theme
		
		public init(theme: Theme, reverse: Bool = false) {
			self.theme = theme
			self.reverse = reverse
			
			super.init()
		}
		
		public func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
			var rootController: Controller!
			var ownerViewController: UIViewController!
			
			if !self.reverse {
				rootController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as! Controller
				ownerViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
			} else {
				rootController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as! Controller
				ownerViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
			}
			
			let menuController = rootController.tableViewController
			
			let containerView = transitionContext.containerView()!
			
			let overlayView = UIView(frame: containerView.frame)
			overlayView.backgroundColor = UIColor(white: 0, alpha: 0.8)
			overlayView.layer.opacity = 0.5
			
			if !self.reverse {
				let ownerViewSnapshot = ownerViewController.view.snapshotViewAfterScreenUpdates(false)
				
				containerView.addSubview(ownerViewSnapshot)
				
				containerView.addSubview(overlayView)
				
				containerView.addSubview(rootController.view)
			}
			
			let rowCount = menuController.items.count
			let neededTableViewHeight = CGFloat(rowCount) * self.theme.tableViewRowHeight
			
			if !self.reverse {
				menuController.view.clipsToBounds = true
				
				switch self.theme.animationStyle {
				case .Fade:
					menuController.view.layer.opacity = 0
					break
				case .Slide:
					switch menuController.theme.placement {
					case .Bottom:
						rootController.navigationBar.frame = CGRectMake(0, containerView.frame.size.height, rootController.navigationBar.frame.size.width, rootController.navigationBar.frame.size.height)
						menuController.view.frame = CGRectMake(0, containerView.frame.size.height, containerView.frame.size.width, neededTableViewHeight)
						break
					case .Top:
						rootController.navigationBar.frame = CGRectMake(0, -rootController.navigationBar.frame.size.height, rootController.navigationBar.frame.size.width, rootController.navigationBar.frame.size.height)
						menuController.view.frame = CGRectMake(0, -neededTableViewHeight, containerView.frame.size.width, neededTableViewHeight)
						break
					}
					break
				}
			}
			
			if !self.reverse {
				UIView.animateWithDuration(self.transitionDuration(transitionContext), delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.25, options: [], animations: { () in
					overlayView.layer.opacity = 1

					switch self.theme.animationStyle {
					case .Fade:
						menuController.view.layer.opacity = 1
						break
					case .Slide:
						switch menuController.theme.placement {
						case .Bottom:
							menuController.view.frame = CGRectMake(0, containerView.frame.size.height - neededTableViewHeight, containerView.frame.size.height, neededTableViewHeight)
							rootController.navigationBar.frame = CGRectMake(0, containerView.frame.size.height - Helpers.navigationBarHeight(self.theme) - neededTableViewHeight, rootController.navigationBar.frame.size.width, rootController.navigationBar.frame.size.height)
							break
						case .Top:
							menuController.view.frame = CGRectMake(0, Helpers.tableViewOffset(self.theme), containerView.frame.size.height, neededTableViewHeight)
							rootController.navigationBar.frame = CGRectMake(0, 0, rootController.navigationBar.frame.size.width, rootController.navigationBar.frame.size.height)
							break
						}
						break
					}
					
				}, completion: { (ready) in
					transitionContext.completeTransition(ready)
				})
			} else {
				UIView.animateWithDuration(self.transitionDuration(transitionContext), animations: {
					containerView.layer.opacity = 0
				}, completion: { (ready) in
					transitionContext.completeTransition(ready)
				})
			}
		}
		
		public func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
			return self.reverse ? self.theme.dismissingTransitionDuration : self.theme.presentationTransitionDuration
		}
	}
	
	public class Controller: UIViewController, UIViewControllerTransitioningDelegate {
		
		// MARK: Instance Variables
		
		var theme: Theme
		
		let items: [Item]
		
		let tableViewController: TableViewController
		
		public let navigationBar: UINavigationBar
		
		public let tableView: UITableView
		
		public override var title: String? {
			didSet {
				if let title = self.title {
					let item = UINavigationItem(title: title)
					item.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(Controller.dismiss))
					
					self.navigationBar.setItems([item], animated: true)
				}
			}
		}
		
		public var cancelationHandler: (() -> Void)?
		
		// MARK: Initializers
		
		public init(items: [Item], theme: Theme) {
			self.theme = theme
			self.items = items
			
			self.navigationBar = UINavigationBar(frame: CGRect.zero)
			self.tableViewController = TableViewController(items: self.items, theme: self.theme, navigationBar: self.navigationBar)
			
			self.tableView = self.tableViewController.tableView
			
			super.init(nibName: nil, bundle: nil)
			
			self.transitioningDelegate = self
			self.modalPresentationStyle = .Custom
			
			self.setupViews()
		}
		
		func setupViews() {
			self.addChildViewController(self.tableViewController)
			
			self.tableViewController.tableView.frame = self.tableViewController.view.frame
			
			self.view.addSubview(self.tableViewController.view)
			
			self.tableViewController.didMoveToParentViewController(self)
			
			self.navigationBar.frame = CGRectMake(0, 0, self.view.frame.size.width, Helpers.navigationBarHeight(self.theme))
			self.view.addSubview(self.navigationBar)
			
			self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(Controller.dismiss)))
		}

		public required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		
		// MARK: Status Bar
		
		public override func prefersStatusBarHidden() -> Bool {
			return !self.theme.statusBarVisible
		}
		
		public override func preferredStatusBarStyle() -> UIStatusBarStyle {
			if self.theme.barStyle == .Black {
				return .LightContent
			} else {
				return .Default
			}
		}
		
		// MARK: Methods
		
		public func dismiss() {
			self.dismissViewControllerAnimated(true) {
				if let cancelation = self.cancelationHandler {
					cancelation()
				}
			}
		}
		
		// MARK: Transitioning
		
		public func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
			return TransitionAnimator(theme: self.theme)
		}
		
		public func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
			return TransitionAnimator(theme: self.theme, reverse: true)
		}
	}
	
	class Cell: UITableViewCell {
		
	}
	
	class TableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
		
		// MARK: Instance Variables
		
		let items: [Item]
		
		let theme: Theme
		
		let navigationBar: UINavigationBar
		
		let tableView: UITableView
		
		// MARK: Initializers
		
		init(items: [Item], theme: Theme, navigationBar: UINavigationBar) {
			self.items = items
			self.theme = theme
			self.navigationBar = navigationBar
			
			self.tableView = UITableView(frame: CGRect.zero, style: .Plain)
			
			super.init(nibName: nil, bundle: nil)
			
			self.tableView.dataSource = self
			self.tableView.delegate = self
			
			self.view.addSubview(self.tableView)
		}
		
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		
		// MARK: Methods
		
		override func viewDidLoad() {
			super.viewDidLoad()
			
			self.tableView.tableFooterView = UIView()
			
			self.tableView.registerClass(Cell.self, forCellReuseIdentifier: "BlissCell")
			
			self.handleTheming()
			
			self.view.backgroundColor = .clearColor()
			
			self.tableView.scrollEnabled = false
			
			let oldInsets = self.tableView.separatorInset
			self.tableView.separatorInset = UIEdgeInsetsMake(oldInsets.top, oldInsets.left * 1.5, oldInsets.bottom, oldInsets.left * 1.5)
		}
		
		func handleTheming() {
			self.navigationBar.hidden = !self.theme.barVisible
			
			if self.theme.placement == .Bottom {
				let tableViewHeight = self.tableView.frame.size.height
				let topMargin = self.view.frame.size.height - tableViewHeight - Helpers.navigationBarHeight(self.theme)
				
				let tableViewRect = self.tableView.frame
				self.tableView.frame = CGRectMake(tableViewRect.origin.x, topMargin, tableViewRect.size.width, tableViewRect.size.height)
			}
			
			self.tableView.rowHeight = self.theme.tableViewRowHeight
			
			self.navigationBar.barStyle = self.theme.barStyle
			
			if self.theme.barStyle == .Black {
				self.navigationBar.translucent = false
			}
		}
		
		override func prefersStatusBarHidden() -> Bool {
			return !self.theme.statusBarVisible
		}
		
		override func preferredStatusBarStyle() -> UIStatusBarStyle {
			if self.theme.barStyle == .Black {
				return .LightContent
			} else {
				return .Default
			}
		}
		
		// MARK: Table View
		
		func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
			return self.items.count
		}
		
		func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
			let cell = tableView.dequeueReusableCellWithIdentifier("BlissCell", forIndexPath: indexPath)
			let item = self.items[indexPath.row]
			
			cell.textLabel!.text = item.displayName
			
			cell.textLabel!.textAlignment = self.theme.textAlignment
			cell.textLabel!.textColor = self.theme.textColor
			
			cell.backgroundColor = self.theme.cellBackgroundColor
			
			cell.selectedBackgroundView = {
				let view = UIView()
				view.backgroundColor = self.theme.cellSelectedColor
				return view
			}()
			
			if let image = item.image {
				cell.accessoryView = UIImageView(image: image)
				let size = tableView.rowHeight - tableView.contentInset.top - tableView.contentInset.bottom
				cell.accessoryView?.frame = CGRectMake(0, 0, size, size)
			}
			
			return cell
		}
		
		func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
			tableView.deselectRowAtIndexPath(indexPath, animated: true)
			
			let item = self.items[indexPath.row]
			
			self.dismissViewControllerAnimated(true) { 
				item.action()
			}
		}
	}
}