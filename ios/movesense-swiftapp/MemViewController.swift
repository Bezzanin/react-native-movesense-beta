import Foundation
import UIKit
import PromiseKit
import SwiftyJSON
import Toast_Swift

class MemViewController : MovesenseViewController, UINavigationControllerDelegate
{
    private var entriesHandler: LogbookEntriesHandler!
    private var loggingHandler: LogbookResourceHandler!
    private var isOpenHandler: LogbookResourceHandler!
    private var isFullHandler: LogbookResourceHandler!
    private var unsyncLogsHandler: LogbookResourceHandler!
    private var dataloggerHandler: DataloggerResourceHandler!

    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!

    @IBOutlet weak var loggingSwitch: UISwitch!
    @IBOutlet weak var loggingTitle: UIButton!
    @IBOutlet weak var loggingValue: UILabel!

    @IBOutlet weak var isOpenSwitch: UISwitch!
    @IBOutlet weak var isOpenTitle: UIButton!
    @IBOutlet weak var isOpenValue: UILabel!

    @IBOutlet weak var isFullSwitch: UISwitch!
    @IBOutlet weak var isFullTitle: UIButton!
    @IBOutlet weak var isFullValue: UILabel!

    @IBOutlet weak var unsyncLogsSwitch: UISwitch!
    @IBOutlet weak var unsyncLogsTitle: UIButton!
    @IBOutlet weak var unsyncLogsValue: UILabel!

    @IBOutlet weak var logbookButton: UIButton!
    @IBOutlet weak var dataloggerButton: UIButton!


    // MARK: Button actions

    @IBAction func loggingSwitch(_ sender: UISwitch) {
        if sender.isOn {
            self.loggingHandler.subscribe()
        } else {
            self.loggingHandler.unsubscribe()
        }
    }

    @IBAction func loggingTitlePress(_ sender: UIButton) {
        self.loggingHandler.get()
    }

    @IBAction func isOpenSwitch(_ sender: UISwitch) {
        if sender.isOn {
            self.isOpenHandler.subscribe()
        } else {
            self.isOpenHandler.unsubscribe()
        }
    }

    @IBAction func isOpenTitlePress(_ sender: UIButton) {
        self.isOpenHandler.get()
    }

    @IBAction func isFullSwitch(_ sender: UISwitch) {
        if sender.isOn {
            self.isFullHandler.subscribe()
        } else {
            self.isFullHandler.unsubscribe()
        }
    }

    @IBAction func isFullTitlePress(_ sender: UIButton) {
        self.isFullHandler.get()
    }

    @IBAction func unsyncLogsSwitch(_ sender: UISwitch) {
        if sender.isOn {
            self.unsyncLogsHandler.subscribe()
        } else {
            self.unsyncLogsHandler.unsubscribe()
        }
    }

    @IBAction func unsyncLogsTitlePress(_ sender: UIButton) {
        self.unsyncLogsHandler.get()
    }

    @IBAction func LogbookPress(_ sender: UIButton) {
        let menuItems: [MenuItem] =  [ (text: "Entries", action:{ () in self.entriesHandler.get() }),
                                       (text: "Load entry as JSON", action:{ () in self.entriesHandler.getAsJSON() }),
                                       (text: "Delete entry", action:{ () in self.entriesHandler.del() }),
                                       (text: "Delete all entries", action:{ () in self.entriesHandler.delAll() })
        ]
        self.menu("Logbook", items: menuItems)
    }
    
    @IBAction func dataloggerPress(_ sender: UIButton) {
        let menuItems: [MenuItem] =  [ (text: "Get config", action:{ () in self.dataloggerHandler.getConfig() }),
                                       (text: "Get state", action:{ () in self.dataloggerHandler.getState() }),
                                       (text: "Put state", action:{ () in self.dataloggerHandler.putState() })
        ]
        self.menu("Datalogger", items: menuItems)
    }


    // MARK: View configurations

    private func configButtons(_ isConnected: Bool) {
        let device = self.movesense!.getDevice(self.uuid!)
        if (isConnected) {
            self.serial = device?.serial
            let info = device?.deviceInfo;
            if info != nil {
                let str = String(format: "%@ %@\nVersion %@",
                                 (info?.manufacturerName)!, (info?.productName)!,
                                 (info?.sw)!)
                self.deviceLabel.text = str
            } else {
                self.deviceLabel.text = device?.localName
            }
        } else {
            self.deviceLabel.text = device?.localName
        }

        self.loggingTitle.isEnabled = isConnected
        self.loggingSwitch.isEnabled = isConnected
        self.isOpenTitle.isEnabled = isConnected
        self.isOpenSwitch.isEnabled = isConnected
        self.isFullTitle.isEnabled = isConnected
        self.isFullSwitch.isEnabled = isConnected
        self.unsyncLogsTitle.isEnabled = isConnected
        self.unsyncLogsSwitch.isEnabled = isConnected

        self.loggingValue.text = "--"
        self.isOpenValue.text = "--"
        self.isFullValue.text = "--"
        self.unsyncLogsValue.text = "--"

        self.logbookButton.isEnabled = isConnected
        self.dataloggerButton.isEnabled = isConnected
    }

    private func configureView() {
        self.activitySpinner.hidesWhenStopped = true

        let isConnected = self.movesense!.isDeviceConnected(self.serial!)

        self.configButtons(isConnected)

        self.movesense!.setHandlers(
            deviceConnected: { (serial) in
                self.parent?.view.makeToast("\(serial) Connected")
                if let device = self.movesense!.getDevice(serial) {
                    if (self.uuid == device.uuid) {
                        self.configButtons(true)
                    }
                }
            },
            deviceDisconnected: { (serial) in
                self.parent?.view.makeToast("\(serial) Disconnected")
                if let device = self.movesense!.getDevice(serial) {
                    if (self.uuid == device.uuid) {
                        self.configButtons(false)
                    }
                }
            },
            bleOnOff: { _ in () })

        if isConnected {
            self.loggingHandler.get()
            self.isOpenHandler.get()
            self.isFullHandler.get()
        }
    }


    // MARK: Setup handlers

    private func setupHandlers() {
        self.entriesHandler = LogbookEntriesHandler(viewController: self, button: self.logbookButton, serial: self.serial!)
        self.loggingHandler = LogbookResourceHandler(viewController: self, toggle: self.loggingSwitch, button: self.loggingTitle, value: self.loggingValue,
                                                     serial: self.serial!, path: Movesense.LOGBOOK_LOGGING_PATH)
        self.isOpenHandler = LogbookResourceHandler(viewController: self, toggle: self.isOpenSwitch, button: self.isOpenTitle, value: self.isOpenValue,
                                                    serial: self.serial!, path: Movesense.LOGBOOK_ISOPEN_PATH)
        self.isFullHandler = LogbookResourceHandler(viewController: self, toggle: self.isFullSwitch, button: self.isFullTitle, value: self.isFullValue,
                                                    serial: self.serial!, path: Movesense.LOGBOOK_ISFULL_PATH)
        self.unsyncLogsHandler = LogbookResourceHandler(viewController: self, toggle: self.unsyncLogsSwitch, button: self.unsyncLogsTitle, value: self.unsyncLogsValue,
                                                        serial: self.serial!, path: Movesense.LOGBOOK_UNSYNCRONISED_LOGS_PATH)
        self.dataloggerHandler = DataloggerResourceHandler(viewController: self, button: self.dataloggerButton, serial: self.serial!)
    }


    // MARK: UIViewController overrides

    override func viewDidLoad() {
        self.setupHandlers()
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    public func active(_ state: Bool) {
        if state {
            self.activeOperations += 1
        } else {
            self.activeOperations -= 1
        }

        if state {
            if !self.activitySpinner.isAnimating {
                self.activitySpinner.startAnimating()
            }
        } else if self.activeOperations <= 0 {
            self.activitySpinner.stopAnimating()
        }
    }
}


// MARK: BaseMemResourceHandler

class BaseMemResourceHandler {
    internal var viewController: MemViewController
    internal var button: UIButton
    internal var serial: String

    init(viewController: MemViewController, button: UIButton, serial: String) {
        self.viewController = viewController
        self.button = button
        self.serial = serial
    }

    internal func get(_ path: String) {
        self.active(true)

        firstly {
            self.viewController.movesense!.get(self.serial, path: path)
            }.then { response in
                self.popup(title: path, text: response.content)
            }.catch { error in
                self.showError("\(path) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
        }
    }

    internal func active(_ state: Bool) {
        self.viewController.active(state)
    }

    internal func showError(_ text: String) {
        self.active(false)
        self.viewController.showError(text)
    }

    internal func popup(title: String, text: String) {
        self.active(false)
        self.viewController.popup(self.button, title: title, text: text)
    }
}


// MARK: LogbookEntriesHandler

class LogbookEntriesHandler : BaseMemResourceHandler {
    private struct Entry {
        public let id: UInt32
        public let modificationTimestamp: UInt32
        public let size: UInt64!
    }
    private var entryArray = Array<Entry>()

    public func get() {
        self.getAllEntries(readyAction: { (entries) in
            var text: String = ""
            if entries.isEmpty {
                text = "No Entries"
            } else {
                for entry in entries {
                    text.append("Id:\(entry.id)\nModificationTimestamp:\(entry.modificationTimestamp)\nSize:\(entry.size!)\n\n")
                }
            }
            self.popup(title: "Logbook Entries", text: text)
        })
    }

    private func getAllEntries(readyAction: @escaping (Array<Entry>) -> ()) {
        self.active(true)
        self.entryArray.removeAll()
        self.getEntries(afterId: 0, readyAction: readyAction)
    }

    private func getEntries(afterId: UInt32, readyAction: @escaping (Array<Entry>) -> ()) {
        let parameters = afterId > 0 ? ["StartAfterId": afterId] : [:]
        firstly {
            self.viewController.movesense!.get(self.serial, path: Movesense.LOGBOOK_ENTRIES_PATH, parameters: parameters)
            }.then { response in
                self.handleEntriesResponse(response, readyAction: readyAction)
            }.catch { error in
                self.showError("\(Movesense.LOGBOOK_ENTRIES_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
        }
    }

    private func handleEntriesResponse(_ response: MovesenseResponse, readyAction: @escaping (Array<Entry>) -> ()) {
        let json = JSON(parseJSON: response.content)
        let entries = json["elements"].array
        for entry in entries! {
            self.entryArray.append(Entry(id: entry["Id"].uInt32!,
                                         modificationTimestamp: entry["ModificationTimestamp"].uInt32!,
                                         size: entry["Size"].exists() ? entry["Size"].uInt64 : nil))
        }

        if !entries!.isEmpty && response.status == 100 {
            // continue
            self.getEntries(afterId: self.entryArray.last!.id, readyAction: readyAction)
            return
        }

        readyAction(self.entryArray)
    }

    public func getAsJSON() {
        self.getAllEntries(readyAction: { (entries) in
            self.selectEntry(entries, action: { (_, id) in
                self.loadEntry(id)
            })
        })
    }

    private func selectEntry(_ entries: Array<Entry>, action: @escaping (Int, Int) -> ()) {
        var entryArray = Array<String>()
        for entry in entries {
            let date = Date(timeIntervalSince1970: Double(entry.modificationTimestamp))
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .medium
            entryArray.append(dateFormatter.string(from: date))
        }

        if entryArray.isEmpty {
            self.active(false)
            self.viewController.parent?.view.makeToast("No entries in the logbook")
        } else {
            self.viewController.select(self.viewController.logbookButton, title: "Select entry",
                                       items: entryArray, defaultItem: entryArray[0],
                                       onOk: { (entry) in
                                                if let index = entryArray.index(of: entry) {
                                                    action(index, Int(entries[index].id))
                                                }
                                             })
        }
    }


    public func loadEntry(_ id: Int) {
        self.loadSummary(id)
    }

    private func loadSummary(_ id: Int) {
        let mdsSummaryPath = "/Logbook/" + self.serial + "/ById/\(id)/Summary"
        firstly {
            self.viewController.movesense!.get("MDS", path: mdsSummaryPath)
            }.then { response in
                self.loadData(id, json: "Summary:\n" + response.content + "\n")
            }.catch { error in
                self.showError("\(mdsSummaryPath) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
        }
    }

    private func loadData(_ id: Int, json: String) {
        let mdsDataPath = "/Logbook/" + self.serial + "/ById/\(id)/Data"
        firstly {
            self.viewController.movesense!.get("MDS", path: mdsDataPath)
            }.then { response in
                self.popup(title: "Entry \(id)", text: json + "\nData:\n" + response.content)
            }.catch { error in
                self.showError("\(mdsDataPath) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
        }
    }

    public func del() {
        self.getAllEntries(readyAction: { (entries) in
            self.selectEntry(entries, action: { (index, _) in
                self.del(index)
            })
        })
    }

    private func del(_ index: Int) {
        let path = Movesense.LOGBOOK_LOG_PATH + "/" + "\(index)" + "/Remove"
        firstly {
            self.viewController.movesense!.put(self.serial, path: path, parameters: [:])
            }.then { response in
                self.popup(title: path, text: response.content)
            }.catch { error in
                self.showError("\(path) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
        }
    }

    public func delAll() {
        self.active(true)
        self.entryArray.removeAll()

        firstly {
            self.viewController.movesense!.del(self.serial, path: Movesense.LOGBOOK_ENTRIES_PATH)
            }.then { response in
                self.popup(title: Movesense.LOGBOOK_ENTRIES_PATH, text: response.content)
            }.catch { error in
                self.showError("\(Movesense.LOGBOOK_ENTRIES_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
        }
    }
}


// MARK: LogbookResourceHandler

class LogbookResourceHandler : BaseMemResourceHandler {
    private var toggle: UISwitch
    private var value: UILabel
    private var path: String

    init(viewController: MemViewController, toggle: UISwitch, button: UIButton, value: UILabel, serial: String, path: String) {
        self.toggle = toggle
        self.value = value
        self.path = path
        super.init(viewController: viewController, button: button, serial: serial)
    }

    public func get() {
        self.value.text = "--"
        self.active(true)

        firstly {
            self.viewController.movesense!.get(self.serial, path: self.path)
            }.then { response in
                self.output(response.content)
            }.catch { error in
                self.showError("\(self.path) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
        }
    }

    public func subscribe() {
        self.value.text = "--"
        self.toggle.isOn = true

        self.viewController.parent?.view.makeToast("Subscribe \(self.path)")

        self.viewController.movesense!.subscribe(self.serial, path: self.path,
                                                  parameters: [:],
                                                  onNotify: { response in
                                                    self.value.text = response.content
        },
                                                  onError: { (_, path, message) in
                                                    self.showError("\(path) \(message)")
                                                    self.toggle.isOn = false
                                                    self.value.text = "--"
        })
    }

    public func unsubscribe() {
        if self.viewController.movesense!.isSubscribed(self.serial, path: self.path) {
            self.viewController.parent?.view.makeToast("Unsubscribe \(self.path)")
            self.self.viewController.movesense!.unsubscribe(self.serial, path: self.path)
            self.value.text = "--"
            self.toggle.isOn = false
        }
    }

    private func output(_ text: String) {
        self.active(false)
        self.value.text = text
    }
}


// MARK: DataloggerResourceHandler

class DataloggerResourceHandler : BaseMemResourceHandler {
    private let states: Dictionary<UInt8, String> = [1: "Invalid",
                                                      2: "Ready",
                                                      3: "Logging"]

    public func getConfig() {
        self.get(Movesense.DATALOGGER_CONFIG_PATH)
    }

    public func getState() {
        self.get(Movesense.DATALOGGER_STATE_PATH)
    }

    public func putState() {
        self.viewController.select(self.button, title: "Set Datalogger State",
                                   items: Array(self.states.values), defaultItem: self.states[1]!,
                                   onOk: { (state) in
                                    self.viewController.parent?.view.makeToast("Putting into \(state) state")

                                    if let stateKey = self.states.getKey(forValue: state) {
                                        self.putState(stateKey)
                                    }
        })
    }

    private func putState(_ state: UInt8) {
        self.active(true)

        firstly {
            self.viewController.movesense!.put(self.serial, path: Movesense.DATALOGGER_STATE_PATH, parameters: ["newState": state])
            }.then { _ in
                self.active(false)
            }.catch { error in
                self.showError("\(Movesense.DATALOGGER_STATE_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
        }
    }
}
