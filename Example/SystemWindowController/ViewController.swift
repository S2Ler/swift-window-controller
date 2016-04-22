
import UIKit
import SystemWindowController

private let sysWindowController1 = SystemWindowController(windowLevel: UIWindowLevelAlert + 1)
private let sysWindowController2 = SystemWindowController(windowLevel: UIWindowLevelAlert + 2)
private let sysWindowController3 = SystemWindowController(windowLevel: UIWindowLevelAlert + 3)

class ViewController: UIViewController {
  override func viewDidAppear(animated: Bool) {
    self.view.backgroundColor = UIColor.grayColor()
    super.viewDidAppear(animated)
    
    sysWindowController1.showSystemViewController(makeAlertController(title: "Title1"))
    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
    dispatch_after(delayTime, dispatch_get_main_queue()) { [unowned self] in
      sysWindowController2.showSystemViewController(self.makeAlertController(title: "Title2"))
      dispatch_after(delayTime, dispatch_get_main_queue()) { 
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor.redColor()
        sysWindowController1.showSystemViewController(vc)
      }
    }
    
  }
  
  private func makeAlertController(title title: String) -> UIAlertController {
    let alert = UIAlertController(title: title, message: nil, preferredStyle: .Alert)
    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
    return alert;
  }
}

extension UIViewController: SystemViewController {
  public var viewControllerLevel: SystemViewControllerLevel { return 1 }
}
