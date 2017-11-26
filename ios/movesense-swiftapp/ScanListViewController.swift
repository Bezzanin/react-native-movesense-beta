import UIKit
import SwiftyJSON
import PromiseKit
import Movesense
import React

final class ScanListViewController: UITableViewController {
    internal let movesense = (UIApplication.shared.delegate as! AppDelegate).movesenseInstance()
    private var bleOnOff = false

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func getLabel(text: String) -> UILabel {
        let emptyViewLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        emptyViewLabel.text = text
        emptyViewLabel.textColor = UIColor.black
        emptyViewLabel.backgroundColor = UIColor.white
        emptyViewLabel.numberOfLines = 0
        emptyViewLabel.textAlignment = .center
        emptyViewLabel.sizeToFit()
        return emptyViewLabel
    }
    
    private func updateBleStatus(bleOnOff: Bool) {
        self.bleOnOff = bleOnOff

        self.tableView.backgroundView = self.getLabel(text: bleOnOff ? "Pull down to start scanning" : "Enable BLE")
        self.tableView.separatorStyle = .none

        if !bleOnOff {
            self.refreshControl!.endRefreshing()
        }

        self.tableView.reloadData()
    }
    
    private func scanEnded() {
        self.refreshControl!.endRefreshing()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.movesense.stopScan()
        self.refreshControl!.endRefreshing()

        var indexPath = self.tableView.indexPathForSelectedRow!
        let device = self.movesense.nthDevice(indexPath.row)!
        let tabs = segue.destination as! DeviceTabController
        tabs.uuid = device.uuid
        tabs.serial = device.serial
        tabs.movesense = self.movesense
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if !self.bleOnOff || self.movesense.getDeviceCount() == 0 {
            return 0
        } else {
            self.tableView.backgroundView = nil
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.bleOnOff ? self.movesense.getDeviceCount() : 0;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovesenseDeviceCell", for: indexPath)
        let device = self.movesense.nthDevice(indexPath.row)!
        cell.textLabel!.text = device.localName
        return cell
    }
    
    func startScan() {
        if self.bleOnOff {
            self.tableView.backgroundView = self.getLabel(text: "")

            _ = firstly {
                self.movesense.startScan({ _ in self.tableView.reloadData() })
            }.then { _ -> Void in
                self.tableView.reloadData()
                self.refreshControl!.endRefreshing()
            }
        } else {
            self.refreshControl!.endRefreshing()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.refreshControl = UIRefreshControl()
        self.refreshControl!.backgroundColor = Movesense.MOVESENSE_COLOR
        self.refreshControl!.tintColor = UIColor.white
        self.refreshControl!.addTarget(self, action: #selector(self.startScan), for: .valueChanged)

        self.movesense.setHandlers(deviceConnected: { _ in
                                       self.tableView.reloadData()
                                   },
                                   deviceDisconnected: { _ in
                                       self.tableView.reloadData()
                                   },
                                   bleOnOff: { (state) in
                                        self.updateBleStatus(bleOnOff: state)
                                   })

      }
    
    @IBAction func highScoreButtonTapped(sender : UIButton) {
        NSLog("Hello")
        let jsCodeLocation = URL(string: "http://130.233.87.58:8081/index.bundle?platform=ios")
        let mockData:NSDictionary = ["axises":
            [
                ["name":"X axis", "value":"42"],
                ["name":"Z axis", "value":"10"]
            ]
        ]
        
        let rootView = RCTRootView(
            bundleURL: jsCodeLocation,
            moduleName: "RNHighScores",
            initialProperties: mockData as [NSObject : AnyObject],
            launchOptions: nil
        )
        let vc = UIViewController()
        vc.view = rootView
        self.present(vc, animated: true, completion: nil)
    }
}
