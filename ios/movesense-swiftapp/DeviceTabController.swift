import Foundation
import UIKit

class DeviceTabController: UITabBarController {
    var uuid: UUID?
    var serial: String?
    weak var movesense: MovesenseService?
    
    /// Set the properties for each tab
    private func configureTabs() {
        for vc in self.childViewControllers {
            let msViewCtrl = vc as! MovesenseViewController
            msViewCtrl.uuid = uuid
            msViewCtrl.serial = serial
            msViewCtrl.movesense = movesense
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureTabs()
    }
}
