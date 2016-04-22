
import Foundation
import UIKit

/// Level where System view controller should appear. A view controller with the highest Level will be on top of all other view controllers.
public typealias SystemViewControllerLevel = Int
public let SystemViewControllerLevelTop = Int.max

/// Each System view controller should conform to this protocolc
public protocol SystemViewController {
  /// Level at which view controller should appear
  var viewControllerLevel: SystemViewControllerLevel { get }
}

/// Use to place a System view controller above everthing else in app, even status bar and notifications.
///
/// An example of such System view controller is `Update Required` screen.
public final class SystemWindowController {
  /// Private init so that we can only have one `SystemWindowController`. Use SystemWindowController constant
  private let windowLevel: UIWindowLevel
  public init(windowLevel: UIWindowLevel) {
    self.windowLevel = windowLevel
  }
  
  /// Window which fly above all other windows in app.
  private lazy var window: UIWindow! = {
    let window = UIWindow()
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
  weak var previousKeyWindow: UIWindow? = nil
}

public extension SystemWindowController {
  /**
   Present System view controller
   
   - parameter viewController: a view controller to present
   */
  public func showSystemViewController<T: UIViewController where T: SystemViewController>(viewController: T) {
    if !window.keyWindow { showSystemWindow() }
    
    self.viewController.showSystemViewController(viewController)
  }
  
  /**
   Dismiss System view controller
   
   - parameter viewController: a view controller to dismiss
   */
  public func dismissSystemViewController<T: UIViewController where T: SystemViewController>(viewController: T) {
    self.viewController.dismissSystemViewController(viewController)
    
    if !self.viewController.hasShownSystemViewControllers {
      hideSystemWindow()
    }
  }
}

private extension SystemWindowController {
  /// Make System window key and active
  private func showSystemWindow() {
    previousKeyWindow = UIApplication.sharedApplication().keyWindow
    previousKeyWindow?.endEditing(true)
    window.frame = UIScreen.mainScreen().bounds
    window.makeKeyAndVisible()
    window.hidden = false
  }
  
  /// Hide System window and show previously active window
  private func hideSystemWindow() {
    previousKeyWindow?.makeKeyAndVisible()
    window.hidden = true
    window = nil
    previousKeyWindow = nil
  }
}

/// Root container view controller for System view controllers
private final class SystemWindowViewController: UIViewController {
  typealias Hash = Int
  /// A map from viewController's view hash to it's level
  private var viewHashToLevelMap: [Hash: SystemViewControllerLevel] = [:]
  private var onEmptyViewControllers: (() -> ())!
  
  /// Present `viewController` taking into account it's level
  func showSystemViewController<T: UIViewController where T: SystemViewController>(viewController: T) {
    print(viewController.debugDescription)
    print(viewController.modalPresentationStyle.rawValue)
    if viewController.modalPresentationStyle == .FullScreen {
      addChildViewController(viewController)
      insertView(viewController.view, atLevel: viewController.viewControllerLevel)
      viewController.didMoveToParentViewController(self)
    }
    else {
      findViewControllerForPresentation().presentViewController(viewController, animated: true, completion: nil)
    }
  }
  
  /// Dismiss `viewController`
  func dismissSystemViewController<T: UIViewController where T: SystemViewController>(viewController: T) {
    if viewController.modalPresentationStyle == .FullScreen {
      viewController.willMoveToParentViewController(nil)
      removeView(viewController.view)
      viewController.removeFromParentViewController()
    }
    else {
      findViewControllerForPresentation().dismissViewControllerAnimated(true, completion: nil)
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
