import Foundation
import UIKit
import PromiseKit
import SwiftyJSON
import Toast_Swift
import React

class SubscriptionDetailViewController : MovesenseViewController, UINavigationControllerDelegate
{
    private var accHandler: AccelerationHandler!
    private var magnHandler: MagneticFieldHandler!
    private var gyroHandler: GyroHandler!
    private var hrHandler: HrHandler!
    private var tempHandler: TemperatureHandler!
    private var myAccelX: String!
    private var myAccelY: String!
    private var myTempLabel: String!
    private var myHrLabel: String!
    
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!

    @IBOutlet weak var accelSwitch: UISwitch!
    @IBOutlet weak var accelTitle: UIButton!
    @IBOutlet weak var accelSamples: UILabel!
    @IBOutlet weak var accelX: UILabel!
    @IBOutlet weak var accelY: UILabel!
    @IBOutlet weak var accelZ: UILabel!
    @IBOutlet var myAccelZ: String!

    @IBOutlet weak var magnSwitch: UISwitch!
    @IBOutlet weak var magnTitle: UIButton!
    @IBOutlet weak var magnSamples: UILabel!
    @IBOutlet weak var magnX: UILabel!
    @IBOutlet weak var magnY: UILabel!
    @IBOutlet weak var magnZ: UILabel!

    @IBOutlet weak var gyroSwitch: UISwitch!
    @IBOutlet weak var gyroTitle: UIButton!
    @IBOutlet weak var gyroSamples: UILabel!
    @IBOutlet weak var gyroX: UILabel!
    @IBOutlet weak var gyroY: UILabel!
    @IBOutlet weak var gyroZ: UILabel!

    @IBOutlet weak var hrSwitch: UISwitch!
    @IBOutlet weak var hrTitle: UIButton!
    @IBOutlet weak var hrLabel: UILabel!

    @IBOutlet weak var tempSwitch: UISwitch!
    @IBOutlet weak var tempTitle: UIButton!
    @IBOutlet weak var tempLabel: UILabel!

    @IBOutlet weak var fileOutputSwitch: UISwitch!


    
    // MARK: Button actions

    @IBAction func accelTitlePress(_ sender: UIButton) {
        self.selectOperation(self.accHandler)
    }
    
    @IBAction func highScoreButton(_ sender: Any) {
    }
    
    @IBAction func magnTitlePress(_ sender: UIButton) {
        self.selectOperation(self.magnHandler)
    }

    @IBAction func gyroTitlePress(_ sender: UIButton) {
        self.selectOperation(self.gyroHandler)
    }
    
    @IBAction func highScoreButtonTapped(sender : UIButton) {
        let jsCodeLocation = URL(string: "http://172.20.10.3:8081/index.bundle?platform=ios")
        let mockData:NSDictionary = ["details":
            [
                "axisX":self.myAccelX, "axisY":self.myAccelY, "axisZ":self.myAccelZ, "temperature":self.myTempLabel, "hrate":self.myHrLabel
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

    @IBAction func hrTitlePress(_ sender: UIButton) {
        let menuItems: [MenuItem] =  [ (text: "Info", action:{ () in self.hrHandler.getInfo() }),
                                       self.hrHandler.isSubscribed()
                                        ? (text: "Unsubscribe", action:{ () in
                                                                          self.hrLabel.text = "--"
                                                                          self.hrHandler.unsubscribe()
                                                                       })
                                        : (text: "Subscribe", action:{ () in
                                                                         self.hrLabel.text = "--"
                                                                         self.hrHandler.subscribe()
                                                                     })
                                     ]
        self.menu(self.hrHandler.getTitle(), items: menuItems)
    }

    @IBAction func tempTitlePress(_ sender: UIButton) {
        let menuItems: [MenuItem] =  [ (text: "Info", action:{ () in self.tempHandler.getInfo() }),
                                       (text: "Get", action:{ () in
                                                                self.tempLabel.text = "--";
                                                                self.tempHandler.getTemp()
                                                            }),
                                       self.tempHandler.isSubscribed()
                                        ? (text: "Unubscribe", action:{ () in
                                                                         self.tempLabel.text = "--"
                                                                         self.tempHandler.unsubscribe()
                                                                      })
                                        : (text: "Subscribe", action:{ () in
                                                                         self.tempLabel.text = "--"
                                                                         self.tempHandler.subscribeWithInterval()
                                                                     })
                                    ]
        self.menu(self.tempHandler.getTitle(), items: menuItems)
    }

    private func selectOperation(_ handler: Vector3DSubscriptionHandler) {
        let menuItems: [MenuItem] =  [ (text: "Info", action:{ () in handler.getInfo() }),
                                       (text: "Config", action:{ () in handler.getConfig() }),
                                       handler.isSubscribed() ? (text: "Unubscribe", action:{ () in handler.unsubscribe() })
                                        : (text: "Subscribe", action:{ () in handler.subscribeWithSampleRate() })
                                     ]
        self.menu(handler.getTitle(), items: menuItems)
    }

    @IBAction func accelSwitch(_ sender: UISwitch) {
        if sender.isOn {
            self.accHandler.subscribe()
        } else {
            self.accHandler.unsubscribe()
        }
    }

    @IBAction func magnSwitch(_ sender: UISwitch) {
        if sender.isOn {
            self.magnHandler.subscribe()
        } else {
            self.magnHandler.unsubscribe()
        }
    }

    @IBAction func gyroSwitch(_ sender: UISwitch) {
        if sender.isOn {
            self.gyroHandler.subscribe()
        } else {
            self.gyroHandler.unsubscribe()
        }
    }

    @IBAction func hrSwitch(_ sender: UISwitch) {
        self.hrLabel.text = "--"
        if sender.isOn {
            self.hrHandler.subscribe()
        } else {
            self.hrHandler.unsubscribe()
        }
    }
    
    @IBAction func tempSwitch(_ sender: UISwitch) {
        self.tempLabel.text = "--"
        if sender.isOn {
            self.tempHandler.subscribe()
        } else {
            self.tempHandler.unsubscribe()
        }
    }

    @IBAction func fileOutputSwitch(_ sender: UISwitch) {
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

        self.accelSwitch.isEnabled = isConnected
        self.accelTitle.isEnabled = isConnected
        self.magnSwitch.isEnabled = isConnected
        self.magnTitle.isEnabled = isConnected
        self.gyroSwitch.isEnabled = isConnected
        self.gyroTitle.isEnabled = isConnected
        self.hrSwitch.isEnabled = isConnected
        self.hrTitle.isEnabled = isConnected
        self.tempSwitch.isEnabled = isConnected
        self.tempTitle.isEnabled = isConnected
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
                        self.subscribe()
                        self.configButtons(true)
                    }
                }
            },
            deviceDisconnected: { (serial) in
                self.parent?.view.makeToast("\(serial) Disconnected")
                if let device = self.movesense!.getDevice(serial) {
                    if (self.uuid == device.uuid) {
                        self.unsubscribeAll()
                        self.configButtons(false)
                    }
                }
            },
            bleOnOff: { _ in () })

        if isConnected {
            self.subscribe()
        }
    }


    // MARK: Subscriptions

    private func subscribe() {
        if self.movesense!.isDeviceConnected(self.serial!) {
            if self.accelSwitch.isOn {
                self.accHandler.subscribe()
            }

            if self.magnSwitch.isOn {
                self.magnHandler.subscribe()
            }

            if self.gyroSwitch.isOn {
                self.gyroHandler.subscribe()
            }

            if self.hrSwitch.isOn {
                self.hrLabel.text = "--"
                self.hrHandler.subscribe()
            }

            if self.tempSwitch.isOn {
                self.tempLabel.text = "--"
                self.tempHandler.subscribe()
            }
        }
    }

    private func unsubscribeAll() {
        self.accHandler.unsubscribe()
        self.magnHandler.unsubscribe()
        self.gyroHandler.unsubscribe()

        self.hrLabel.text = "--"
        self.hrHandler.unsubscribe()

        self.tempLabel.text = "--"
        self.tempHandler.unsubscribe()
    }


    // MARK: Setup subscription handlers

    private func setupHandlers() {
        self.accHandler = AccelerationHandler(viewController: self, toggle: self.accelSwitch, serial: self.serial!,
                                              newSamplesReceiver: { (samples) in
                                                                      self.accelSamples.text = String("\(self.accHandler.sampleCount())");
                                                                      self.myAccelX = String(format: "%.2f", samples.last!.x);
                                                                      self.accelX.text = String(format: "%.2f", samples.last!.x);
                                                                      self.accelY.text = String(format: "%.2f", samples.last!.y);
                                                                      self.myAccelY = String(format: "%.2f", samples.last!.y);
                                                                      self.myAccelZ = String(format: "%.2f", samples.last!.z);
                                                                      self.accelZ.text = String(format: "%.2f", samples.last!.z);
                                                                  })
        self.magnHandler = MagneticFieldHandler(viewController: self, toggle: self.magnSwitch, serial: self.serial!,
                                                newSamplesReceiver: { (samples) in
                                                                        self.magnSamples.text = String("\(self.magnHandler.sampleCount())");
                                                                        self.magnX.text = String(format: "%.2f", samples.last!.x);
                                                                        self.magnY.text = String(format: "%.2f", samples.last!.y);
                                                                        self.magnZ.text = String(format: "%.2f", samples.last!.z);
                                                                    })
        self.gyroHandler = GyroHandler(viewController: self, toggle: self.gyroSwitch, serial: self.serial!,
                                       newSamplesReceiver: { (samples) in
                                                               self.gyroSamples.text = String("\(self.gyroHandler.sampleCount())");
                                                               self.gyroX.text = String(format: "%.2f", samples.last!.x);
                                                               self.gyroY.text = String(format: "%.2f", samples.last!.y);
                                                               self.gyroZ.text = String(format: "%.2f", samples.last!.z);
                                                           })
        self.hrHandler = HrHandler(viewController: self, toggle: self.hrSwitch, serial: self.serial!,
                                   newValueReceiver: { (hr) in
                                                         self.hrLabel.text = String(format: "♥ %.0f BPM", hr)
                                                         self.myHrLabel = String(format: "%.0f", hr)
                                                     })
        self.tempHandler = TemperatureHandler(viewController: self, toggle: self.tempSwitch, serial: self.serial!,
                                              newValueReceiver: { (tempInCelsius) in
                                                                    self.tempLabel.text = String(format: "%.1f °C", tempInCelsius)
                                                                    self.myTempLabel = String(format: "%.1f °C", tempInCelsius)
                                                                })
    }

    // MARK: UIViewController overrides

    override func viewDidLoad() {
        setupHandlers()
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeAll()
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


// MARK: BaseSubscriptionHandler

class BaseSubscriptionHandler {
    internal var dataFile: SubDataFile?
    internal var serial: String
    internal var viewController: SubscriptionDetailViewController
    internal var toggle: UISwitch
    internal var title: String
    internal var filePrefix: String
    internal var path: String
    internal var infoPath: String

    init(viewController: SubscriptionDetailViewController, toggle: UISwitch,
         serial: String, title: String, filePrefix: String,
         path: String, infoPath: String) {
        self.serial = serial
        self.viewController = viewController
        self.toggle = toggle
        self.title = title
        self.filePrefix = filePrefix
        self.path = path
        self.infoPath = infoPath
    }

    public func getTitle() -> String {
        return self.title
    }

    public func isSubscribed() -> Bool {
        return self.viewController.movesense!.isSubscribed(self.serial, path: self.resourcePath())
    }

    public func unsubscribe() {
        if self.viewController.movesense!.isSubscribed(self.serial, path: self.resourcePath()) {
            self.viewController.movesense!.unsubscribe(self.serial, path: self.resourcePath())
            self.toggle.isOn = false
        }
    }

    public func getInfo() {
        self.get(self.infoPath)
    }

    internal func get(_ path: String) {
        self.active(true)

        firstly {
            self.viewController.movesense!.get(self.serial, path: path)
            }.then { response in
                self.popup(title: path, text:response.content)
            }.catch { error in
                self.showError("(path) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
        }
    }

    internal func resourcePath() -> String {
        return String("\(self.path)")
    }

    internal func makeToast(_ text: String) {
        self.viewController.parent?.view.makeToast(text)
    }

    internal func showError(_ text: String) {
        self.active(false)
        self.viewController.showError(text)
    }

    internal func popup(title: String, text: String) {
        self.active(false)
        self.viewController.popup(self.toggle, title: title, text: text)
    }

    internal func select(title: String, items: Array<String>, defaultItem: String, onOk: @escaping (String) -> ()) {
        self.viewController.select(self.toggle, title: title, items: items, defaultItem: defaultItem, onOk: onOk)
    }

    internal func active(_ state: Bool) {
        self.viewController.active(state)
    }
}

// MARK: Vector3DSubscriptionHandler

class Vector3DSubscriptionHandler : BaseSubscriptionHandler {
    private var values = Array<(time: UInt32, vector:Vector3D)>()
    private var sampleRate = Int32(13)
    private var dataArrayName: String
    private var configPath: String
    private var newSamples: (Array<Vector3D>) -> () = { (vectors) in }

    init(viewController: SubscriptionDetailViewController, toggle: UISwitch,
         serial: String, title: String, filePrefix: String,
         path: String, infoPath: String, configPath: String,
         dataArrayName: String,
         newSamplesReceiver: @escaping (Array<Vector3D>) -> ()) {
        self.dataArrayName = dataArrayName
        self.configPath = configPath
        self.newSamples = newSamplesReceiver
        super.init(viewController: viewController, toggle: toggle, serial: serial, title: title, filePrefix: filePrefix, path: path, infoPath: infoPath)
    }

    public func subscribe() {
        self.toggle.isOn = true
        self.makeToast("\(self.title) \(self.sampleRate )Hz")

        self.dataFile = SubDataFile(self.filePrefix, serial: self.serial)

        self.viewController.movesense?.subscribe(self.serial, path: self.resourcePath(),
                                  parameters: [:],
                                  onNotify: { response in
                                    self.handleData(response)
        },
                                  onError: { (_, path, message) in
                                    self.showError("\(path) \(message)")
                                    self.toggle.isOn = false
                                    self.dataFile?.write("Error \(message)")
        })
    }

    public func subscribeWithSampleRate() {
        self.active(true)

        firstly {
            self.viewController.movesense!.get(self.serial, path: self.infoPath)
            }.then { response in
                self.select(title: "Select Sample Rate (Hz)",
                            items: self.parseSampleRates(response), defaultItem: String(self.sampleRate),
                            onOk: { (rate) in
                                self.active(false)
                                if let rateValue = Int32(rate) {
                                    self.sampleRate = rateValue
                                } else {
                                    self.sampleRate = Int32(13)
                                }
                                self.subscribe()
                })
            }.catch { error in
                self.showError("(self.infoPath) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
        }
    }

    public func getConfig() {
        self.get(self.configPath)
    }

    public func sampleCount() -> Int {
        return self.values.count
    }

    private func handleData(_ response: MovesenseResponse) {
        let data = response.getVectors(self.dataArrayName)
        if data.time > 0 && !data.vectors.isEmpty {
            appendData(data)

            self.newSamples(data.vectors)

            if self.viewController.fileOutputSwitch.isOn {
                for item in data.vectors {
                    self.dataFile?.write(String(format: "%f,%f,%f", item.x, item.y, item.z))
                }
            }
        }
    }

    override func resourcePath() -> String {
        return String("\(self.path)/\(self.sampleRate)")
    }

    private func appendData(_ data: DataVectors) {
        var timeDiff = UInt32(0)
        let firstSampleTime = data.time // Timestamp of the first sample in this group
        for item in data.vectors {
            self.values.append((time: firstSampleTime + timeDiff, vector: item))
            timeDiff += UInt32(1000.0/Double(self.sampleRate)) // Difference between samples is about the sample rate
        }
    }

    private func parseSampleRates(_ response: MovesenseResponse) -> Array<String> {
        let json = JSON(parseJSON: response.content)
        var rateArray = Array<String>()
        if let rates = json["SampleRates"].array {
            for rate in rates {
                if let rateValue = rate.uInt16 {
                    let rateStr = String(UInt(rateValue))
                    rateArray.append(rateStr)
                }
            }
        }
        return rateArray
    }
}

// MARK: AccelerationHandler

class AccelerationHandler : Vector3DSubscriptionHandler {
    init(viewController: SubscriptionDetailViewController, toggle: UISwitch, serial: String, newSamplesReceiver: @escaping (Array<Vector3D>) -> ()) {
        super.init(viewController: viewController, toggle: toggle,
                   serial: serial, title: "Linear Acceleration", filePrefix: "accel",
                   path: Movesense.ACCEL_PATH, infoPath: Movesense.ACCEL_INFO_PATH, configPath: Movesense.ACCEL_CONFIG_PATH,
                   dataArrayName: "ArrayAcc",
                   newSamplesReceiver: newSamplesReceiver)
    }
}

// MARK: MagneticFieldHandler

class MagneticFieldHandler : Vector3DSubscriptionHandler {
    init(viewController: SubscriptionDetailViewController, toggle: UISwitch, serial: String, newSamplesReceiver: @escaping (Array<Vector3D>) -> ()) {
        super.init(viewController: viewController, toggle: toggle,
                   serial: serial, title: "Magnetic Field", filePrefix: "magn",
                   path: Movesense.MAGN_PATH, infoPath: Movesense.MAGN_INFO_PATH, configPath: Movesense.MAGN_CONFIG_PATH,
                   dataArrayName: "ArrayMagn",
                   newSamplesReceiver: newSamplesReceiver)
    }
}

// MARK: GyroHandler

class GyroHandler : Vector3DSubscriptionHandler {
    init(viewController: SubscriptionDetailViewController, toggle: UISwitch, serial: String, newSamplesReceiver: @escaping (Array<Vector3D>) -> ()) {
        super.init(viewController: viewController, toggle: toggle,
                   serial: serial, title: "Angular Velocity", filePrefix: "gyro",
                   path: Movesense.GYRO_PATH, infoPath: Movesense.GYRO_INFO_PATH, configPath: Movesense.GYRO_CONFIG_PATH,
                   dataArrayName: "ArrayGyro",
                   newSamplesReceiver: newSamplesReceiver)
    }
}

// MARK: HrHandler

class HrHandler : BaseSubscriptionHandler {
    private let testValues = [70.0, 71.0, 68.0, 65.0, 60.0, 58.0, 58.0, 61.0, 62.0]
    private var values = Array<Double>()
    private var newValue: (Double) -> () = { (value) in }

    init(viewController: SubscriptionDetailViewController, toggle: UISwitch,
         serial: String, newValueReceiver: @escaping (Double) -> ()) {
        super.init(viewController: viewController, toggle: toggle, serial: serial, title: "Heartrate", filePrefix: "rr", path: Movesense.HR_PATH, infoPath: Movesense.HR_INFO_PATH)
        self.newValue = newValueReceiver
    }

    public func subscribe() {
        self.toggle.isOn = true

        self.dataFile = SubDataFile(self.filePrefix, serial: self.serial)

        self.viewController.movesense?.subscribe(self.serial, path: self.path,
                                  parameters: [:],
                                  onNotify: { response in
                                    self.handleData(response)
        },
                                  onError: { (_, path, message) in
                                    self.showError("\(path) \(message)")
                                    self.toggle.isOn = false
                                    self.dataFile?.write("Error \(message)")
        })
    }

    private func handleData(_ response: MovesenseResponse) {
        let json = JSON(parseJSON: response.content)
        if json["rrData"][0].number != nil {
            let rr = json["rrData"][0].doubleValue
            let hr = 60000/rr
            if self.values.elementsEqual(testValues) {
                self.values.removeAll()
            }
            self.values.append(hr)
            self.newValue(hr)

            if self.viewController.fileOutputSwitch.isOn {
                self.dataFile?.write(String(format: "%.0f", rr))
            }
        }
    }
}

// MARK: TemperatureHandler

class TemperatureHandler : BaseSubscriptionHandler {
    private var values = Array<(time: UInt32, value:Double)>()
    private var interval = UInt8(0)
    private var newValue: (Double) -> () = { (value) in }

    init(viewController: SubscriptionDetailViewController, toggle: UISwitch,
         serial: String, newValueReceiver: @escaping (Double) -> ()) {
        super.init(viewController: viewController, toggle: toggle, serial: serial, title: "Temperature", filePrefix: "temp", path: Movesense.TEMPERATURE_PATH, infoPath: Movesense.TEMPERATURE_INFO_PATH)
        self.newValue = newValueReceiver
    }

    public func subscribe() {
        self.toggle.isOn = true

        self.makeToast(self.interval > 0 ? "Temperature measurement interval \(self.interval) s" : "Update on temperature change")

        self.dataFile = SubDataFile(self.filePrefix, serial: self.serial)

        self.viewController.movesense?.subscribe(self.serial, path: self.path,
                                  parameters: self.interval > 0 ? ["Interval": self.interval] : [:],
                                  onNotify: { response in
                                    self.handleData(response)
        },
                                  onError: { (_, path, message) in
                                    self.showError("\(path) \(message)")
                                    self.toggle.isOn = false
                                    self.dataFile?.write("Error \(message)")
        })
    }

    public func subscribeWithInterval() {
        let storyboard: UIStoryboard =  UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "intervalSlider") as! IntervalSliderController
        vc.modalPresentationStyle = UIModalPresentationStyle.popover
        vc.popoverPresentationController?.permittedArrowDirections = .down
        vc.popoverPresentationController?.delegate = self.viewController
        vc.popoverPresentationController?.sourceView = self.toggle as UIView
        vc.popoverPresentationController?.sourceRect = self.toggle.bounds

        vc.setValue(self.interval);
        vc.onOk({ (value) in
            self.interval = value
            self.subscribe()
        })

        self.viewController.present(vc, animated: true, completion: nil)
    }

    private func handleData(_ response: MovesenseResponse) {
        let json = JSON(parseJSON: response.content)
        if json["Measurement"].number != nil {
            let timestamp = json["Timestamp"].uInt32Value
            let value = json["Measurement"].doubleValue
            self.values.append((timestamp, value))
            self.newValue(value - 273.15)

            if self.viewController.fileOutputSwitch.isOn {
                self.dataFile?.write(String(format: "%.1f", value))
            }
        }
    }

    public func getTemp() {
        self.active(true)

        firstly {
            self.viewController.movesense!.get(self.serial, path: self.path)
            }.then { response in
                self.output(response)
            }.catch { error in
                self.showError("\(self.path) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
        }
    }

    private func output(_ response: MovesenseResponse) {
        self.active(false)
        self.handleData(response)
    }
}


// MARK: SliderController

class IntervalSliderController : UIViewController {
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var valueLabel: UILabel!

    private var value = UInt8(0)
    private var callOnOk: (UInt8) -> () = { (value) in }

    public func setValue(_ value: UInt8) {
        self.value = value;
    }

    public func onOk(_ onOk: @escaping (UInt8) -> ()) {
        callOnOk = onOk
    }

    @IBAction func okPress(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
        callOnOk(UInt8(self.slider.value))
    }

    @IBAction func cancelPress(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        self.updateValue(UInt8(sender.value))
    }

    private func updateValue(_ value: UInt8) {
        if value > 0 {
            self.valueLabel.text = "\(value) s"
        } else {
            self.valueLabel.text = "0 = on every change"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.slider.setValue(Float(self.value), animated: false)
        updateValue(self.value)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
