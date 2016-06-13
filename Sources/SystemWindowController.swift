
import Foundation
import UIKit

/// Level where System view controller should appear. A view controller with the highest Level will be on top of all other view controllers.
public typealias SystemViewControllerLevel = Int
public let SystemViewControllerLevelTop = Int.max

/// Use to place a System view controller above everthing else in app, even status bar and notifications.
///
/// An example of such System view controller is `Update Required` screen.
@objc
public final class SystemWindowController: NSObject {
  /// Private init so that we can only have one `SystemWindowController`. Use SystemWindowController constant
  private let windowLevel: UIWindowLevel
  
  public init(windowLevel: UIWindowLevel) {
    self.windowLevel = windowLevel
  }
  
  /// Window which fly above all other windows in app.
  private lazy var window: UIWindow! = {
    let window = UIWindow()
    window.accessibilityIdentifier = "System Window Controller"
    window.windowLevel = self.windowLevel
    window.backgroundColor = UIColor.clearColor()
    window.rootViewController = self.viewController
    return window
  }()
  
  /// Root view controller for `window`
  private lazy var viewController: SystemWindowViewController! = {
    let viewController = SystemWindowViewController()
    viewController.onEmptyViewControllers = { [weak self] in
      self?.hideSystemWindow()
    }
    return viewController
  }()
  
  /// A window which was a key before `window` became key
  weak var keyWindow: UIWindow? = nil
}

public extension SystemWindowController {
  /**
   Present System view controller
   
   - parameter viewController: a view controller to present
   */
  public func showSystemViewController(viewController: UIViewController,
                                       atLevel level: SystemViewControllerLevel,
                                               completion: (Void -> Void)? = nil) {
    if !window.keyWindow { showSystemWindow() }
    
    self.viewController.showSystemViewController(viewController,
                                                 atLevel: level, statusBarState: keyWindowStatusBarState,
                                                 completion: completion)
  }
  
  /**
   Dismiss System view controller
   
   - parameter viewController: a view controller to dismiss
   */
  public func dismissSystemViewController(viewController: UIViewController, completion: (Void -> Void)? = nil) {
    self.viewController.dismissSystemViewController(viewController, completion: {[weak self] in
      guard let this = self else {
        completion?()
        return
      }
      
      if !this.viewController.hasShownSystemViewControllers {
        this.hideSystemWindow()
      }
      completion?()
    })
  }
  
  private var keyWindowStatusBarState: StatusBarState {
    return keyWindow?.currentStatusBarState ?? StatusBarState.defaultStatusBar
  }
}

private extension SystemWindowController {
  /// Make System window key and active
  private func showSystemWindow() {
    keyWindow = UIApplication.sharedApplication().keyWindow
    UIApplication.sharedApplication().keyWindow?.endEditing(true)
    window.frame = keyWindow?.bounds ?? UIScreen.mainScreen().bounds
    window.hidden = false
  }
  
  /// Hide System window and show previously active window
  private func hideSystemWindow() {
    window.hidden = true
    keyWindow = nil
  }
}

/// Root container view controller for System view controllers
private final class SystemWindowViewController: UIViewController {
  typealias Hash = Int
  /// A map from viewController's view hash to it's level
  private var viewHashToLevelMap: [Hash: SystemViewControllerLevel] = [:]
  private var onEmptyViewControllers: (() -> ())!
  private var statusBarState: StatusBarState? {
    didSet {
      setNeedsStatusBarAppearanceUpdate()
    }
  }
  
  /// Present `viewController` taking into account it's level
  func showSystemViewController(viewController: UIViewController,
                                atLevel level: SystemViewControllerLevel,
                                        statusBarState: StatusBarState,
                                        completion: (Void -> Void)?) {
    self.statusBarState = statusBarState
    
    if viewController.modalPresentationStyle == .FullScreen {
      addChildViewController(viewController)
      insertView(viewController.view, atLevel: level)
      viewController.didMoveToParentViewController(self)
      completion?()
    }
    else {
      findViewControllerForPresentation().presentViewController(viewController, animated: true, completion: completion)
    }
  }
  
  /// Dismiss `viewController`
  func dismissSystemViewController(viewController: UIViewController, completion: (Void -> Void)?) {
    if viewController.modalPresentationStyle == .FullScreen {
      viewController.willMoveToParentViewController(nil)
      removeView(viewController.view)
      viewController.removeFromParentViewController()
      completion?()
    }
    else {
      findViewControllerForPresentation().dismissViewControllerAnimated(true, completion: completion)
    }
  }
  
  override private func dismissViewControllerAnimated(flag: Bool, completion: (() -> Void)?) {
    super.dismissViewControllerAnimated(flag, completion: { [weak self] in
      completion?()
      
      guard let this = self else { return }

      if !this.hasShownSystemViewControllers {
        this.onEmptyViewControllers()
      }
    })
  }
  
  /**
   Inserts `viewToInsert` into appropriate location, taking into account `level`
   
   The view with the highest `level` will be top in the view hierarchy
   
   - parameter viewToInsert: a view to insert into view hierarchy
   - parameter level:        a view's level
   */
  private func insertView(viewToInsert: UIView, atLevel level: SystemViewControllerLevel) {
    viewHashToLevelMap[viewToInsert.hashValue] = level
    
    //Find the last view hash which is at the same or less level
    let placeAboveTheViewWithHash = viewHashToLevelMap
      .sort { (level1, level2) -> Bool in
        return level1.1 < level2.1
      }
      .lastThat { $0.1 <= level }?.0
    
    if let placeAboveTheViewWithHash = placeAboveTheViewWithHash {
      let placeAboveTheView = view.subviews.firstThat { $0.hashValue == placeAboveTheViewWithHash}
      if let placeAboveTheView = placeAboveTheView {
        view.insertSubview(viewToInsert, aboveSubview: placeAboveTheView)
      }
      else {
        view.addSubview(viewToInsert)
      }
    }
    else {
      view.addSubview(viewToInsert)
    }
  }
  
  /// Remove `viewToRemove` from view hierarchy
  private func removeView(viewToRemove: UIView) {
    viewHashToLevelMap.removeValueForKey(viewToRemove.hashValue)
    viewToRemove.removeFromSuperview()
  }
  
  private func findViewControllerForPresentation() -> UIViewController {
    var viewControllerForPresentation: UIViewController = self
    while let c = viewControllerForPresentation.presentedViewController {
      viewControllerForPresentation = c
    }
    return viewControllerForPresentation
  }
  
  private var hasShownSystemViewControllers: Bool {
    return childViewControllers.count > 0 || presentedViewController != nil
  }

  
  private override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.clearColor()
  }
  
  private override func prefersStatusBarHidden() -> Bool {
    return statusBarState?.hidden ?? false
  }
  
  private override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return statusBarState?.style ?? .LightContent
  }
}

private extension SequenceType {
  private func lastThat(@noescape predicate: (Generator.Element) -> Bool) -> Generator.Element? {
    var last: Generator.Element? = nil
    for element in self {
      if predicate(element) {
        last = element
      }
    }
    
    return last
  }
  
  private func firstThat(@noescape predicate: (Generator.Element) -> Bool) -> Generator.Element? {
    for element in self {
      if predicate(element) {
        return element
      }
    }
    
    return nil
  }
}

private struct StatusBarState {
  let hidden: Bool
  let style: UIStatusBarStyle
  
  static var defaultStatusBar: StatusBarState {
    return StatusBarState(hidden: false, style: .LightContent)
  }
}

private extension UIWindow {
  var currentStatusBarState: StatusBarState {
    if let rootViewController = self.rootViewController {
      let topMostViewController = rootViewController.findTopMostController()
      let viewControllerForStatusBarHidden = topMostViewController.childViewControllerForStatusBarHidden() ?? topMostViewController
      let viewControllerForStatusBarStyle = topMostViewController.childViewControllerForStatusBarStyle() ?? topMostViewController
      return StatusBarState(hidden: viewControllerForStatusBarHidden.prefersStatusBarHidden(),
                            style: viewControllerForStatusBarStyle.preferredStatusBarStyle())
    }
    else {
      return StatusBarState.defaultStatusBar
    }
  }
}

private extension UIViewController {
  func findTopMostController() -> UIViewController {
    var topController: UIViewController = self
    while let presentedViewController = topController.presentedViewController {
      topController = presentedViewController
    }
    return topController
  }
}
