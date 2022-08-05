import Foundation
#if canImport(UIKit)
import UIKit
#else
#error("UIKit only framework")
#endif

/// Use to place a view controller above everthing else in app, even status bar and notifications.
///
/// An example of such view controller is `Update Required` screen.
@MainActor
public final class WindowController {
  /// Level where window view controller should appear. A view controller with the highest Level will be on top of all other view controllers.
  public struct Level: Comparable, Hashable {
    public static func < (lhs: WindowController.Level, rhs: WindowController.Level) -> Bool {
      lhs.raw < rhs.raw
    }

    public static let top: Self = .init(raw: .max)

    public let raw: Int

    public init(raw: Int) {
      self.raw = raw
    }
  }

  public typealias ApplicationProvider = () -> UIApplication?

  /// Private init so that we can only have one `WindowController`. Use WindowController constant
  private let windowLevel: UIWindow.Level
  private let applicationProvider: ApplicationProvider
  private let windowName: String

  public init(
    windowLevel: UIWindow.Level,
    windowName: String = "Window Controller",
    application: @escaping ApplicationProvider
  ) {
    self.applicationProvider = application
    self.windowName = windowName
    self.windowLevel = windowLevel
  }

  /// Window which fly above all other windows in app.
  fileprivate var window: UIWindow!

  public var isWindowHidden: Bool { return window.isHidden }

  /// Root view controller for `window`
  fileprivate lazy var viewController: WindowViewController! = {
    let viewController = WindowViewController()
    viewController.onEmptyViewControllers = { [weak self] in
      self?.hideWindow()
    }
    return viewController
  }()

  /// A window which was a key before `window` became key
  weak var keyWindow: UIWindow? = nil
}

extension WindowController {
  //  Present window view controller
  //
  //  - parameter viewController: a view controller to present
  public func show(
    _ viewController: UIViewController,
    at level: WindowController.Level,
    completion: (() -> Void)? = nil
  ) {
    if window?.isKeyWindow == false || window == nil {
      showWindow()
    }
    guard window != nil else {
      assertionFailure("Window isn't created")
      return
    }

    self.viewController.show(
      viewController,
      at: level,
      statusBarState: keyWindowStatusBarState,
      completion: completion
    )
  }

  //  Dismiss window view controller
  //
  //  - parameter viewController: a view controller to dismiss
  public func dismiss(_ viewController: UIViewController, completion: (() -> Void)? = nil) {
    self.viewController.dismissWindowViewController(
      viewController,
      completion: { [weak self] in
        guard let this = self else {
          completion?()
          return
        }

        if !this.viewController.hasShownWindowViewControllers {
          this.hideWindow()
        }
        completion?()
      }
    )
  }

  private var keyWindowStatusBarState: StatusBarState {
    return keyWindow?.currentStatusBarState ?? StatusBarState.defaultStatusBar
  }
}

extension WindowController {
  /// Make window key and active
  fileprivate func showWindow() {
    guard let application = applicationProvider() else { return }
    let windowScene = application
      .connectedScenes
      .filter { $0.activationState == .foregroundActive }
      .first
    guard let windowScene = windowScene as? UIWindowScene else { return }
    window = UIWindow(windowScene: windowScene)
    window.accessibilityIdentifier = windowName
    window.windowLevel = windowLevel
    window.backgroundColor = .clear
    window.rootViewController = viewController

    keyWindow = windowScene.windows.first(where: { $0.isKeyWindow == true })
    _ = keyWindow?.endEditing(true)

    window.frame = keyWindow?.bounds ?? UIScreen.main.bounds
    window.isHidden = false
    window.makeKeyAndVisible()
  }

  /// Hide window and show previously active window
  fileprivate func hideWindow() {
    window.isHidden = true
    window = nil
    keyWindow = nil
  }
}

/// Root container view controller for window view controllers
private final class WindowViewController: UIViewController {
  typealias Hash = Int
  /// A map from viewController's view hash to it's level
  private var viewHashToLevelMap: [Hash: WindowController.Level] = [:]
  fileprivate var onEmptyViewControllers: (() -> Void)!
  private var statusBarState: StatusBarState? {
    didSet {
      setNeedsStatusBarAppearanceUpdate()
    }
  }

  /// Present `viewController` taking into account it's level
  func show(
    _ viewController: UIViewController,
    at level: WindowController.Level,
    statusBarState: StatusBarState,
    completion: (() -> Void)?
  ) {
    self.statusBarState = statusBarState

    if viewController.modalPresentationStyle == .fullScreen {
      addChild(viewController)
      insertView(viewController.view, atLevel: level)
      viewController.didMove(toParent: self)
      completion?()
    }
    else {
      findViewControllerForPresentation().present(viewController, animated: true, completion: completion)
    }
  }

  /// Dismiss `viewController`
  func dismissWindowViewController(_ viewController: UIViewController, completion: (() -> Void)?) {
    if viewController.modalPresentationStyle == .fullScreen {
      viewController.willMove(toParent: nil)
      removeView(viewController.view)
      viewController.removeFromParent()
      completion?()
    }
    else {
      findViewControllerForPresentation().dismiss(animated: true, completion: completion)
    }
  }

  override fileprivate func dismiss(animated flag: Bool, completion: (() -> Void)?) {
    super
      .dismiss(
        animated: flag,
        completion: { [weak self] in
          completion?()

          guard let this = self else { return }

          if !this.hasShownWindowViewControllers {
            this.onEmptyViewControllers()
          }
        }
      )
  }

  //  Inserts `viewToInsert` into appropriate location, taking into account `level`
  //
  //  The view with the highest `level` will be top in the view hierarchy
  //
  //  - parameter viewToInsert: a view to insert into view hierarchy
  //  - parameter level:        a view's level
  private func insertView(_ viewToInsert: UIView, atLevel level: WindowController.Level) {
    viewHashToLevelMap[viewToInsert.hashValue] = level

    //Find the last view hash which is at the same or less level
    let placeAboveTheViewWithHash =
    viewHashToLevelMap
      .sorted { (level1, level2) -> Bool in
        return level1.1 < level2.1
      }
      .lastThat { $0.1 <= level }?
      .0

    if let placeAboveTheViewWithHash = placeAboveTheViewWithHash {
      let placeAboveTheView = view.subviews.firstThat { $0.hashValue == placeAboveTheViewWithHash }
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

  fileprivate override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    for subview in view.subviews {
      subview.frame = view.bounds
    }
  }

  /// Remove `viewToRemove` from view hierarchy
  private func removeView(_ viewToRemove: UIView) {
    viewHashToLevelMap.removeValue(forKey: viewToRemove.hashValue)
    viewToRemove.removeFromSuperview()
  }

  private func findViewControllerForPresentation() -> UIViewController {
    var viewControllerForPresentation: UIViewController = self
    while let c = viewControllerForPresentation.presentedViewController {
      viewControllerForPresentation = c
    }
    return viewControllerForPresentation
  }

  fileprivate var hasShownWindowViewControllers: Bool {
    return children.count > 0 || presentedViewController != nil
  }

  fileprivate override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.clear
  }

  fileprivate override var prefersStatusBarHidden: Bool {
    return statusBarState?.hidden ?? false
  }

  fileprivate override var preferredStatusBarStyle: UIStatusBarStyle {
    return statusBarState?.style ?? .lightContent
  }
}

extension Sequence {
  fileprivate func lastThat(_ predicate: (Iterator.Element) -> Bool) -> Iterator.Element? {
    var last: Iterator.Element? = nil
    for element in self {
      if predicate(element) {
        last = element
      }
    }

    return last
  }

  fileprivate func firstThat(_ predicate: (Iterator.Element) -> Bool) -> Iterator.Element? {
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
    return StatusBarState(hidden: false, style: .lightContent)
  }
}

extension UIWindow {
  fileprivate var currentStatusBarState: StatusBarState {
    if let rootViewController = self.rootViewController {
      let topMostViewController = rootViewController.findTopMostController()
      let viewControllerForStatusBarHidden =
      topMostViewController.childForStatusBarHidden ?? topMostViewController
      let viewControllerForStatusBarStyle = topMostViewController.childForStatusBarStyle ?? topMostViewController
      return StatusBarState(
        hidden: viewControllerForStatusBarHidden.prefersStatusBarHidden,
        style: viewControllerForStatusBarStyle.preferredStatusBarStyle
      )
    }
    else {
      return StatusBarState.defaultStatusBar
    }
  }
}

extension UIViewController {
  fileprivate func findTopMostController() -> UIViewController {
    var topController: UIViewController = self
    while let presentedViewController = topController.presentedViewController {
      topController = presentedViewController
    }
    return topController
  }
}
