import UIKit
import XCTest
import SystemWindowController

class Tests: XCTestCase {
  func testIsWindowHidden() {
    let windowController = SystemWindowController(windowLevel: UIWindowLevelStatusBar+1)
    XCTAssertTrue(windowController.isWindowHidden)
    let vc = UIViewController()
    windowController.show(vc, at: SystemViewControllerLevelTop)
    XCTAssertFalse(windowController.isWindowHidden)
  }
}
