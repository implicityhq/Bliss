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
		case top
		case bottom
	}
	
	public enum AnimationStyle {
		case slide
		case fade
	}
	
	public struct Theme {
		public var placement: Placement
		public var animationStyle: AnimationStyle = .slide
		public var presentationTransitionDuration: TimeInterval = 0.55
		public var dismissingTransitionDuration: TimeInterval = 0.35
		public var textColor: UIColor = .black()
		public var cellBackgroundColor: UIColor = .white()
		public var cellSelectedColor: UIColor = .lightGray()
		public var textAlignment: NSTextAlignment = .left
		public var barVisible: Bool = true
		public var tableViewRowHeight: CGFloat = Constants.tableViewRowHeight
		public var statusBarVisible: Bool = true
		public var barStyle: UIBarStyle = .black
		
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
		
		public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
			var rootController: Controller!
			var ownerViewController: UIViewController!
			
			if !self.reverse {
				rootController = transitionContext.viewController(forKey: UITransitionContextToViewControllerKey) as! Controller
				ownerViewController = transitionContext.viewController(forKey: UITransitionContextFromViewControllerKey)
			} else {
				rootController = transitionContext.viewController(forKey: UITransitionContextFromViewControllerKey) as! Controller
				ownerViewController = transitionContext.viewController(forKey: UITransitionContextToViewControllerKey)
			}
			
			let menuController = rootController.tableViewController
			
			let containerView = transitionContext.containerView()
			
			let overlayView = UIView(frame: containerView.frame)
			overlayView.backgroundColor = UIColor(white: 0, alpha: 0.8)
			overlayView.layer.opacity = 0.5
			
			if !self.reverse {
				let ownerViewSnapshot = ownerViewController.view.snapshotView(afterScreenUpdates: false)
				
				containerView.addSubview(ownerViewSnapshot!)
				
				containerView.addSubview(overlayView)
				
				containerView.addSubview(rootController.view)
			}
			
			let rowCount = menuController.items.count
			let neededTableViewHeight = CGFloat(rowCount) * self.theme.tableViewRowHeight
			
			if !self.reverse {
				menuController.view.clipsToBounds = true
				
				switch self.theme.animationStyle {
				case .fade:
					menuController.view.layer.opacity = 0
					break
				case .slide:
					switch menuController.theme.placement {
					case .bottom:
						rootController.navigationBar.frame = CGRect(x: 0, y: containerView.frame.size.height, width: rootController.navigationBar.frame.size.width, height: rootController.navigationBar.frame.size.height)
						menuController.view.frame = CGRect(x: 0, y: containerView.frame.size.height, width: containerView.frame.size.width, height: neededTableViewHeight)
						break
					case .top:
						rootController.navigationBar.frame = CGRect(x: 0, y: -rootController.navigationBar.frame.size.height, width: rootController.navigationBar.frame.size.width, height: rootController.navigationBar.frame.size.height)
						menuController.view.frame = CGRect(x: 0, y: -neededTableViewHeight, width: containerView.frame.size.width, height: neededTableViewHeight)
						break
					}
					break
				}
			}
			
			if !self.reverse {
				UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.25, options: [], animations: { () in
					overlayView.layer.opacity = 1

					switch self.theme.animationStyle {
					case .fade:
						menuController.view.layer.opacity = 1
						break
					case .slide:
						switch menuController.theme.placement {
						case .bottom:
							menuController.view.frame = CGRect(x: 0, y: containerView.frame.size.height - neededTableViewHeight, width: containerView.frame.size.height, height: neededTableViewHeight)
							rootController.navigationBar.frame = CGRect(x: 0, y: containerView.frame.size.height - Helpers.navigationBarHeight(self.theme) - neededTableViewHeight, width: rootController.navigationBar.frame.size.width, height: rootController.navigationBar.frame.size.height)
							break
						case .top:
							menuController.view.frame = CGRect(x: 0, y: Helpers.tableViewOffset(self.theme), width: containerView.frame.size.height, height: neededTableViewHeight)
							rootController.navigationBar.frame = CGRect(x: 0, y: 0, width: rootController.navigationBar.frame.size.width, height: rootController.navigationBar.frame.size.height)
							break
						}
						break
					}
					
				}, completion: { (ready) in
					transitionContext.completeTransition(ready)
				})
			} else {
				UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
					containerView.layer.opacity = 0
				}, completion: { (ready) in
					transitionContext.completeTransition(ready)
				})
			}
		}
		
		public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
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
					item.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(Controller.dismissController))
					
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
			self.modalPresentationStyle = .custom
			
			self.setupViews()
		}
		
		func setupViews() {
			self.addChildViewController(self.tableViewController)
			
			self.tableViewController.tableView.frame = self.tableViewController.view.frame
			
			self.view.addSubview(self.tableViewController.view)
			
			self.tableViewController.didMove(toParentViewController: self)
			
			self.navigationBar.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: Helpers.navigationBarHeight(self.theme))
			self.view.addSubview(self.navigationBar)
			
//			self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(Controller.dismissController)))
		}

		public required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		
		// MARK: Status Bar
		
		public override func prefersStatusBarHidden() -> Bool {
			return !self.theme.statusBarVisible
		}
		
		public override func preferredStatusBarStyle() -> UIStatusBarStyle {
			if self.theme.barStyle == .black {
				return .lightContent
			} else {
				return .default
			}
		}
		
		// MARK: Methods
		
		public func dismissController() {
			self.dismiss(animated: true) {
				if let cancelation = self.cancelationHandler {
					cancelation()
				}
			}
		}
		
		// MARK: Transitioning
		
		public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
			return TransitionAnimator(theme: self.theme)
		}
		
		public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
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
			
			self.tableView = UITableView(frame: CGRect.zero, style: .plain)
			
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
			
			self.tableView.register(Cell.self, forCellReuseIdentifier: "BlissCell")
			
			self.handleTheming()
			
			self.view.backgroundColor = .clear()
			
			self.tableView.isScrollEnabled = false
			
			let oldInsets = self.tableView.separatorInset
			self.tableView.separatorInset = UIEdgeInsetsMake(oldInsets.top, oldInsets.left * 1.5, oldInsets.bottom, oldInsets.left * 1.5)
		}
		
		func handleTheming() {
			self.navigationBar.isHidden = !self.theme.barVisible
			
			if self.theme.placement == .bottom {
				let tableViewHeight = self.tableView.frame.size.height
				let topMargin = self.view.frame.size.height - tableViewHeight - Helpers.navigationBarHeight(self.theme)
				
				let tableViewRect = self.tableView.frame
				self.tableView.frame = CGRect(x: tableViewRect.origin.x, y: topMargin, width: tableViewRect.size.width, height: tableViewRect.size.height)
			}
			
			self.tableView.rowHeight = self.theme.tableViewRowHeight
			
			self.navigationBar.barStyle = self.theme.barStyle
			
			if self.theme.barStyle == .black {
				self.navigationBar.isTranslucent = false
			}
		}
		
		override func prefersStatusBarHidden() -> Bool {
			return !self.theme.statusBarVisible
		}
		
		override func preferredStatusBarStyle() -> UIStatusBarStyle {
			if self.theme.barStyle == .black {
				return .lightContent
			} else {
				return .default
			}
		}
		
		// MARK: Table View
		
		func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
			return self.items.count
		}
		
		func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
			let cell = tableView.dequeueReusableCell(withIdentifier: "BlissCell", for: indexPath)
			let item = self.items[(indexPath as NSIndexPath).row]
			
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
				cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: size, height: size)
			}
			
			return cell
		}
		
		func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
			tableView.deselectRow(at: indexPath, animated: true)
			
			let item = self.items[(indexPath as NSIndexPath).row]
			
			self.dismiss(animated: true) { 
				item.action()
			}
		}
	}
}
