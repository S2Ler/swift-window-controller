
import UIKit
import SystemWindowController

private let sysWindowController1 = SystemWindowController(windowLevel: UIWindowLevelAlert + 1)
private let sysWindowController2 = SystemWindowController(windowLevel: UIWindowLevelAlert + 2)
private let sysWindowController3 = SystemWindowController(windowLevel: UIWindowLevelAlert + 3)

class ViewController: UIViewController {
  override func viewDidAppear(_ animated: Bool) {
    self.view.backgroundColor = UIColor.gray
    super.viewDidAppear(animated)
    
    sysWindowController1.show(makeAlertController(title: "Title1"), at: 0)
    let delayTime = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: delayTime) { [unowned self] in
      sysWindowController2.show(self.makeAlertController(title: "Title2"), at: 0)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            let vc = UIViewController()
            vc.view.backgroundColor = UIColor.red
            sysWindowController1.show(vc, at: 1)
        }
    }
    
  }
  
  private func makeAlertController(title: String) -> UIAlertController {
    let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    return alert;
  }
}
