import Foundation
import UIKit
import PromiseKit
import SwiftyJSON
import Movesense


// MARK: Base class for our UIViewControllers

class MovesenseViewController : UIViewController, UIPopoverPresentationControllerDelegate {
    weak var movesense: MovesenseService?
    var uuid: UUID?
    var serial: String?
    internal var activeOperations: Int = 0

    func popup(_ sender: AnyObject, title: String, text: String) {
        let storyboard: UIStoryboard =  UIStoryboard(name: "Main", bundle: nil)
        let popVC = storyboard.instantiateViewController(withIdentifier: "popId") as! PopController
        popVC.modalPresentationStyle = UIModalPresentationStyle.popover
        popVC.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.any
        popVC.popoverPresentationController?.delegate = self
        popVC.popoverPresentationController?.sourceView = sender as? UIView
        popVC.popoverPresentationController?.sourceRect = sender.bounds

        self.present(popVC, animated: true, completion: nil)

        popVC.titleLabel.text = title
        popVC.content.text = text
    }

    typealias MenuItem = (text: String, action: () -> ())
    func menu(_ title: String, items: Array<MenuItem>) {
        let ac = UIAlertController(title: title, message: "", preferredStyle: .alert)

        for item in items {
            let action = UIAlertAction(title: item.text, style: .default, handler: { (action: UIAlertAction) -> Void in item.action() })
            ac.addAction(action)
        }

        let action = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction) -> Void in () })
        ac.addAction(action)

        self.present(ac, animated: true, completion: nil)
    }

    func select(_ sender: AnyObject, title: String, items: Array<String>, defaultItem: String, onOk: @escaping (String) -> ()) {
        let storyboard: UIStoryboard =  UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "selector") as! SelectController
        vc.modalPresentationStyle = UIModalPresentationStyle.popover
        vc.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        vc.popoverPresentationController?.delegate = self
        vc.popoverPresentationController?.sourceView = sender as? UIView
        vc.popoverPresentationController?.sourceRect = sender.bounds

        vc.setItems(items, defaultItem: defaultItem);
        vc.onOk(onOk)

        self.present(vc, animated: true, completion: nil)

        vc.titleLabel.text = title
    }

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }

    func showError(_ msg: String) {
        print(msg)
        self.parent?.view.makeToast(msg)
    }
}


// MARK: Device view

class DetailViewController : MovesenseViewController, UINavigationControllerDelegate {
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!

    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!

    @IBOutlet weak var deviceTimeTitle: UIButton!
    @IBOutlet weak var deviceTime: UILabel!
    @IBOutlet weak var deviceTimeSwitch: UISwitch!

    @IBOutlet weak var energyTitle: UIButton!
    @IBOutlet weak var energyLabel: UILabel!
    @IBOutlet weak var energySwitch: UISwitch!

    @IBOutlet weak var systemModeTitle: UIButton!
    @IBOutlet weak var systemModeLabel: UILabel!

    @IBOutlet weak var bleTitle: UIButton!
    @IBOutlet weak var bleAddressLabel: UILabel!
    @IBOutlet weak var bleAdvertisingLabel: UILabel!

    @IBOutlet weak var uartTitle: UIButton!
    @IBOutlet weak var uartStateLabel: UILabel!

    @IBOutlet weak var gearIdTitle: UIButton!
    @IBOutlet weak var gearIdLabel: UILabel!
    @IBOutlet weak var gearIdSwitch: UISwitch!

    @IBOutlet weak var ledTitle: UIButton!

    @IBOutlet weak var updateButton: UIButton!


    // MARK: Buttons actions

    @IBAction func connectDevice(_ sender: UIButton) {
        self.active(true);
        self.movesense!.connectDevice(self.serial!)
    }

    @IBAction func disconnectDevice(_ sender: UIButton) {
        self.movesense!.disconnectDevice(self.serial!)
    }

    @IBAction func updateFirmware(sender: UIButton) {
        let params = ["NewState": 12]
        firstly {
            self.movesense!.put(self.serial!, path: Movesense.SYSTEM_MODE_PATH, parameters: params)
            }.then { response in
                self.handleFwUpdateMode()
            }.catch { e in
                let err = e as NSError
                if err.code == 404 {
                    // resource not found -> fallback to older path
                    firstly {
                        self.movesense!.put(self.serial!, path: Movesense.OLD_SYSTEM_MODE_PATH, parameters: params)
                        }.then { response in
                            self.handleFwUpdateMode()
                        }.catch { e in
                            self.parent?.view.makeToast("Setting dfu mode failed: " + e.localizedDescription)
                    }
                } else {
                    self.parent?.view.makeToast("Setting dfu mode failed: " + e.localizedDescription)
                }
            }
    }

    func tapDeviceLabel(sender: UITapGestureRecognizer) {
        let menuItems: [MenuItem] =  [ (text: "Info", action:{ () in self.getInfo() }),
                                       (text: "Product Data", action:{ () in self.getManufProductData() }),
                                       (text: "Calibration Data", action:{ () in self.getManufCalibrationData() }),
                                       (text: "Power Off After Reset", action:{ () in self.putPowerOffAfterReset() })]
        self.menu(self.serial!, items: menuItems)
    }

    @IBAction func deviceTimeTitlePress(_ sender: UIButton) {
        let subscribed = self.movesense!.isSubscribed(self.serial!, path: Movesense.TIME_PATH)

        let menuItems: [MenuItem] =  [ (text: "Get", action:{ () in self.getTime() }),
                                       (text: "Put current time", action:{ () in self.putTime() }),
                                       subscribed ? (text: "unsubscribe", action:{ () in self.unsubscribeTime() }) : (text: "Subscribe", action:{ () in self.subscribeTime() })]
        self.menu(Movesense.TIME_PATH, items: menuItems)
    }

    @IBAction func energyTitlePress(_ sender: UIButton) {
        let subscribed = self.movesense!.isSubscribed(self.serial!, path: Movesense.ENERGY_PATH)

        let menuItems: [MenuItem] =  [ (text: "Get", action:{ () in self.getEnergyLevel() }),
                                       subscribed ? (text: "Unsubscribe", action:{ () in self.unsubscribeEnergy() }) : (text: "Subscribe", action:{ () in self.subscribeEnergy() })]
        self.menu(Movesense.ENERGY_PATH, items: menuItems)
    }

    @IBAction func systemModeTitlePress(_ sender: UIButton) {
        let menuItems: [MenuItem] =  [ (text: "Get", action:{ () in self.getSystemMode() }),
                                       (text: "Put", action:{ () in self.selectSystemMode() })]
        self.menu(Movesense.SYSTEM_MODE_PATH, items: menuItems)
    }

    @IBAction func bleTitlePress(_ sender: UIButton) {
        let menuItems: [MenuItem] =  [ (text: "Get Address", action:{ () in self.getBleAddress() }),
                                       (text: "Get Advertising State", action:{ () in self.getBleAdvState() }),
                                       (text: "Get Advertising Settings", action:{ () in self.getBleAdvSettings() })]
        self.menu(Movesense.BLE_PATH, items: menuItems)
    }

    @IBAction func uartTitlePress(_ sender: UIButton) {
        let menuItems: [MenuItem] =  [ (text: "Get State", action:{ () in self.getUartState() }),
                                       (text: "UART ON After Reset", action:{ () in self.putUart(true) }),
                                       (text: "UART OFF After Reset", action:{ () in self.putUart(false) })]
        self.menu(Movesense.UART_PATH, items: menuItems)
    }

    @IBAction func gearIdTitlePress(_ sender: UIButton) {
        let subscribed = self.movesense!.isSubscribed(self.serial!, path: Movesense.GEAR_ID_PATH)
        
        let menuItems: [MenuItem] =  [ (text: "Get", action:{ () in self.getGearId() }),
                                       subscribed ? (text: "Unsubscribe", action:{ () in self.unsubscribeGearId() }) : (text: "Subscribe", action:{ () in self.subscribeGearId() })]
        self.menu(Movesense.GEAR_ID_PATH, items: menuItems)
    }

    @IBAction func ledTitlePress(_ sender: UIButton) {
        let menuItems: [MenuItem] =  [ (text: "Put On", action:{ () in self.putLed(true) }),
                                       (text: "Put Off", action:{ () in self.putLed(false) })]
        self.menu(Movesense.LED_PATH, items: menuItems)
    }

    @IBAction func deviceTimeSwitch(_ sender: UISwitch) {
        if sender.isOn {
            self.subscribeTime()
        } else {
            self.unsubscribeTime()
        }
    }

    @IBAction func energySwitch(_ sender: UISwitch) {
        if sender.isOn {
            self.subscribeEnergy()
        } else {
            self.unsubscribeEnergy()
        }
    }

    @IBAction func gearIdSwitch(_ sender: UISwitch) {
        if sender.isOn {
            self.subscribeGearId()
        } else {
            self.unsubscribeGearId()
        }
    }

    // MARK: View configurations

    private func configButtons(_ isConnected: Bool) {
        self.deviceLabel.isUserInteractionEnabled = isConnected
        let device = self.movesense!.getDevice(self.uuid!)
        if (isConnected) {
            self.serial = device?.serial
            let info = device?.deviceInfo
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

        self.connectButton.isHidden = isConnected
        self.disconnectButton.isHidden = !isConnected

        self.deviceTimeTitle.isEnabled = isConnected
        self.deviceTimeSwitch.isEnabled = isConnected
        self.energyTitle.isEnabled = isConnected
        self.energySwitch.isEnabled = isConnected
        self.systemModeTitle.isEnabled = isConnected
        self.bleTitle.isEnabled = isConnected
        self.uartTitle.isEnabled = isConnected
        self.gearIdTitle.isEnabled = isConnected
        self.gearIdSwitch.isEnabled = isConnected
        self.ledTitle.isEnabled = isConnected

        self.updateButton.isEnabled = isConnected

        self.deviceTime.text = "--"
        self.energyLabel.text = "--"
        self.systemModeLabel.text = "--"
        self.bleAddressLabel.text = "--"
        self.bleAdvertisingLabel.text = "--"
        self.uartStateLabel.text = "--"
        self.gearIdLabel.text = "--"
    }

    private func configureView() {
        self.activitySpinner.hidesWhenStopped = true

        let isConnected = self.movesense!.isDeviceConnected(self.serial!)

        self.configButtons(isConnected)

        let tap = UITapGestureRecognizer(target: self, action: #selector(DetailViewController.tapDeviceLabel))
        self.deviceLabel.addGestureRecognizer(tap)

        self.movesense!.setHandlers(
            deviceConnected: { (serial) in
                self.parent?.view.makeToast("\(serial) Connected")
                if let device = self.movesense!.getDevice(serial) {
                    if (self.uuid == device.uuid) {
                        self.configButtons(true)
                        self.subscribe()
                        self.getSystemMode()
                        self.getUartState()
                        self.getEnergyLevel()
                        self.getTime()
                        self.active(false)
                    }
                }
            },
            deviceDisconnected: { (serial) in
                self.active(false)
                self.parent?.view.makeToast("\(serial) Disconnected")
                if let device = self.movesense!.getDevice(serial) {
                    if (self.uuid == device.uuid) {
                        self.configButtons(false)
                        self.unsubscribeAll()
                    }
                }
            },
            bleOnOff: { _ in () })

        if isConnected {
            self.subscribe()
            self.getSystemMode()
            self.getUartState()
        }
    }

 
    // MARK: General subsriptions

    private func subscribe() {
        if !self.movesense!.isDeviceConnected(self.serial!) {
            return
        }

        if self.deviceTimeSwitch.isOn {
            self.subscribeTime()
        }

        if self.energySwitch.isOn {
            self.subscribeEnergy()
        }

        if self.gearIdSwitch.isOn {
            self.subscribeGearId()
        }
    }

    private func unsubscribeAll() {
        self.unsubscribeTime()
        self.unsubscribeEnergy()
        self.unsubscribeGearId()
    }


    // MARK: Info

    private func getInfo() {
        self.active(true)

        firstly {
            self.movesense!.get(self.serial!, path: Movesense.INFO_PATH)
            }.then { response in
                self.popup(self.deviceLabel, title: Movesense.INFO_PATH, text:response.content)
            }.catch { error in
                self.showError("\(Movesense.INFO_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
            }
    }


    // MARK: Time

    private func subscribeTime() {
        self.deviceTimeSwitch.isOn = true
        self.movesense?.subscribe(self.serial!, path: Movesense.TIME_PATH,
                                  parameters: [:],
                                  onNotify: { response in
                                      self.handleTime(response)
                                  },
                                  onError: { (_, path, message) in
                                      self.showError("\(path) \(message)")
                                      self.deviceTimeSwitch.isOn = false
                                      self.deviceTime.text = "--"
                                  })
    }

    private func unsubscribeTime() {
        if self.movesense!.isSubscribed(self.serial!, path: Movesense.TIME_PATH) {
            self.movesense!.unsubscribe(self.serial!, path: Movesense.TIME_PATH)
            self.deviceTime.text = "--"
        }
    }

    private func handleTime(_ response: MovesenseResponse, stopSpinner: Bool = false) {
        if stopSpinner {
            self.active(false);
        }

        let json = JSON(parseJSON: response.content)
        if json.number != nil {
            let date = Date(timeIntervalSince1970: Double(json.int64Value)/1000000.0)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .medium
            self.deviceTime.text = dateFormatter.string(from: date)
        } else {
            self.deviceTime.text = "--"
        }
    }

    private func getTime() {
        self.deviceTime.text = "--"
        self.active(true)

        firstly {
            self.movesense!.get(self.serial!, path: Movesense.TIME_PATH)
            }.then { response in
                self.handleTime(response, stopSpinner: true)
            }.catch { error in
                self.showError("\(Movesense.TIME_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
            }
    }

    private func putTime() {
        self.deviceTime.text = "--"
        let time = Int64(Date().timeIntervalSince1970 * 1000000)

        firstly {
            self.movesense!.put(self.serial!, path: Movesense.TIME_PATH, parameters: ["value": time])
            }.then { _ in
                self.getTime()
            }.catch { error in
                self.showError("\(Movesense.TIME_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
        }
    }


    // MARK: Energy

    private func subscribeEnergy() {
        self.energySwitch.isOn = true
        self.movesense?.subscribe(self.serial!, path: Movesense.ENERGY_PATH,
                                  parameters: [:],
                                  onNotify: { response in
                                      self.handleEnergyLevel(response)
                                  },
                                  onError: { (_, path, message) in
                                      self.showError("\(path) \(message)")
                                      self.energySwitch.isOn = false
                                      self.energyLabel.text = "--"
                                  })
    }

    private func unsubscribeEnergy() {
        if self.movesense!.isSubscribed(self.serial!, path: Movesense.ENERGY_PATH) {
            self.movesense!.unsubscribe(self.serial!, path: Movesense.ENERGY_PATH)
            self.energyLabel.text = "--"
        }
    }

    private func handleEnergyLevel(_ response: MovesenseResponse, stopSpinner: Bool = false) {
        if stopSpinner {
            self.active(false);
        }

        let json = JSON(parseJSON: response.content)
        if json.number != nil {
            self.energyLabel.text = String("\(json.uInt8Value) %")
        } else {
            self.energyLabel.text = "--"
        }
    }

    private func getEnergyLevel() {
        self.energyLabel.text = "--"
        self.active(true)

        firstly {
            self.movesense!.get(self.serial!, path: Movesense.ENERGY_PATH)
            }.then { response in
                self.handleEnergyLevel(response, stopSpinner: true)
            }.catch { error in
                self.showError("\(Movesense.ENERGY_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
            }
    }


    // MARK: System mode

    var systemMode = UInt8(0)
    let systemModes: Dictionary<UInt8, String> = [0: "Unknown",
                                                   1: "FullPowerOff",
                                                   2: "SystemFailure",
                                                   3: "Power Off",
                                                   4: "WaitForCharge",
                                                   5: "Application",
                                                   10: "FactoryCalibration",
                                                   11: "BleTestMode",
                                                   12: "dfu"]

    private func handleSystemModeResponse(_ response: MovesenseResponse) {
        self.active(false);

        let json = JSON(parseJSON: response.content)
        if !json.isEmpty {
            self.systemMode = json["current"].uInt8Value
            var mode = self.systemModes[self.systemMode]
            if (mode == nil) {
                mode = "Unknown"
            }
            self.systemModeLabel.text = String(mode! + " (\(self.systemMode))")
        } else {
            self.systemModeLabel.text = "--"
            self.systemMode = 0
        }
    }

    private func getSystemMode() {
        self.systemModeLabel.text = "--"
        self.active(true)

        firstly {
            self.movesense!.get(self.serial!, path: Movesense.SYSTEM_MODE_PATH)
            }.then { response in
                self.handleSystemModeResponse(response)
            }.catch { error in
                self.showError("\(Movesense.SYSTEM_MODE_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
            }
    }

    private func handleFwUpdateMode() {
        self.systemModeLabel.text = "dfu (12)"
        self.parent?.view.makeToast("Device now in dfu mode, ready for NRF Connect")
    }

    private func handleSystemModePut(_ newMode: UInt8) {
        self.active(false);
        self.systemModeLabel.text = "\(self.systemModes[newMode]!) (\(newMode))"
        self.parent?.view.makeToast("Put to \(self.systemModes[newMode]!) mode")
    }

    private func putSystemMode(_ mode: UInt8) {
        self.active(true)

        firstly {
            self.movesense!.put(self.serial!, path: Movesense.SYSTEM_MODE_PATH, parameters: ["NewState": mode])
            }.then { _ in
                self.handleSystemModePut(mode)
            }.catch { error in
                self.showError("\(Movesense.SYSTEM_MODE_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
                self.systemModeLabel.text = "--"
        }
    }

    private func selectSystemMode() {
        self.select(self.systemModeTitle, title: "Set System Mode",
                    items: Array(self.systemModes.values), defaultItem: self.systemModes[self.systemMode]!,
                    onOk: { (mode) in
                        self.parent?.view.makeToast("Putting into \(mode) mode")

                        if let modeKey = self.systemModes.getKey(forValue: mode) {
                            self.putSystemMode(modeKey)
                        }
                    })
    }


    // MARK: BLE

    private func handleBleAddressResponse(_ response: MovesenseResponse) {
        self.active(false);
        self.bleAddressLabel.text = response.content
    }

    private func getBleAddress() {
        self.bleAddressLabel.text = "--"
        self.active(true)

        firstly {
            self.movesense!.get(self.serial!, path: Movesense.BLE_ADDR_PATH)
            }.then { response in
                self.handleBleAddressResponse(response)
            }.catch { error in
                self.showError("\(Movesense.BLE_ADDR_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
            }
    }

    private func handleBleAdvStateResponse(_ response: MovesenseResponse) {
        self.active(false);

        let json = JSON(parseJSON: response.content)
        if !json.isEmpty {
            let advertising = json["isAdvertising"].boolValue
            let peerAddr = json["PeerAddr"].exists() && json["PeerAddr"].null == nil
            self.bleAdvertisingLabel.text = peerAddr && advertising ? json["PeerAddr"].stringValue : (advertising ? "yes" : "no")
        } else {
            self.bleAdvertisingLabel.text = "--"
        }
    }

    private func getBleAdvState() {
        self.bleAdvertisingLabel.text = "--"
        self.active(true)

        firstly {
            self.movesense!.get(self.serial!, path: Movesense.BLE_ADV_PATH)
            }.then { response in
                self.handleBleAdvStateResponse(response)
            }.catch { error in
                self.showError("\(Movesense.BLE_ADV_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
            }
    }

    private func getBleAdvSettings() {
        self.active(true)

        firstly {
            self.movesense!.get(self.serial!, path: Movesense.BLE_ADV_SETTINGS_PATH)
            }.then { response in
                self.popup(self.bleTitle, title: Movesense.BLE_ADV_SETTINGS_PATH, text:response.content)
            }.catch { error in
                self.showError("\(Movesense.BLE_ADV_SETTINGS_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
            }
    }


    // MARK: UART

    private func handleUartStateResponse(_ response: MovesenseResponse) {
        self.active(false);

        let json = JSON(parseJSON: response.content)
        self.uartStateLabel.text = json.boolValue ? "on" : "off"
    }

    private func getUartState() {
        self.uartStateLabel.text = "--"
        self.active(true)

        firstly {
            self.movesense!.get(self.serial!, path: Movesense.UART_PATH)
            }.then { response in
                self.handleUartStateResponse(response)
            }.catch { error in
                self.showError("\(Movesense.UART_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
            }
    }

    private func putUart(_ state: Bool) {
        self.active(true)

        firstly {
                self.movesense!.put(self.serial!, path: Movesense.UART_PATH, parameters: ["State": state])
            }.then { response in
                self.handlePutUartStateResponse(state)
            }.catch { error in
                self.showError("\(Movesense.UART_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
            }
    }

    private func handlePutUartStateResponse(_ state: Bool) {
        self.active(false);
        self.parent?.view.makeToast(state ? "UART will be set ON after the next reset" : "UART will be set OFF after the next reset")
    }


    // MARK: Power off after reset

    private func putPowerOffAfterReset() {
        self.active(true)

        firstly {
            self.movesense!.put(self.serial!, path: Movesense.POWER_OFF_PATH + "?State=True", parameters: [:])
            }.then { response in
                self.handlePutPowerOffResponse()
            }.catch { error in
                self.showError("\(Movesense.POWER_OFF_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
            }
    }

    private func handlePutPowerOffResponse() {
        self.active(false);
        self.parent?.view.makeToast("Power off after the next reset")
    }


    // MARK: Manucfaturing data

    private func getManufProductData() {
        self.active(true)

        firstly {
            self.movesense!.get(self.serial!, path: Movesense.MANUF_PRODUCT_DATA_PATH)
            }.then { response in
                self.popup(self.deviceLabel, title: Movesense.MANUF_PRODUCT_DATA_PATH, text:response.content)
            }.catch { error in
                self.showError("\(Movesense.MANUF_PRODUCT_DATA_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
            }
    }


    // MARK: Calibration data

    private func getManufCalibrationData() {
        self.active(true)

        firstly {
            self.movesense!.get(self.serial!, path: Movesense.MANUF_CALIBRATION_DATA_PATH)
            }.then { response in
                self.popup(self.deviceLabel, title: Movesense.MANUF_CALIBRATION_DATA_PATH, text:response.content)
            }.catch { error in
                self.showError("\(Movesense.MANUF_CALIBRATION_DATA_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
            }
    }


    // MARK: Gear id

    private func subscribeGearId() {
        self.gearIdSwitch.isOn = true
        self.movesense?.subscribe(self.serial!, path: Movesense.GEAR_ID_PATH,
                                  parameters: [:],
                                  onNotify: { response in
                                      self.handleGearId(response)
                                  },
                                  onError: { (_, path, message) in
                                      self.showError("\(path) \(message)")
                                      self.gearIdSwitch.isOn = false
                                      self.gearIdLabel.text = "--"
                                  })
    }

    private func unsubscribeGearId() {
        if self.movesense!.isSubscribed(self.serial!, path: Movesense.GEAR_ID_PATH) {
            self.movesense!.unsubscribe(self.serial!, path: Movesense.GEAR_ID_PATH)
            self.gearIdLabel.text = "--"
        }
    }

    private func handleGearId(_ response: MovesenseResponse, stopSpinner: Bool = false) {
        if stopSpinner {
            self.active(false)
        }

        let json = JSON(parseJSON: response.content)
        if json.number != nil {
            self.gearIdLabel.text = String("\(json.uInt64Value)")
        } else {
            self.gearIdLabel.text = "--"
        }
    }

    private func getGearId() {
        self.gearIdLabel.text = "--"
        self.active(true)

        firstly {
            self.movesense!.get(self.serial!, path: Movesense.GEAR_ID_PATH)
            }.then { response in
                self.handleGearId(response, stopSpinner: true)
            }.catch { error in
                self.showError("\(Movesense.GEAR_ID_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
            }
    }


    // MARK: LED

    private func putLed(_ state: Bool) {
        self.active(true)

        firstly {
            self.movesense!.put(self.serial!, path: Movesense.LED_PATH, parameters: ["isOn": state])
            }.then { response in
                self.active(false)
            }.catch { error in
                self.showError("\(Movesense.LED_PATH) \((error as NSError).code) \(HTTPURLResponse.localizedString(forStatusCode: (error as NSError).code))")
            }
    }


    // MARK: UIViewController overrides

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.unsubscribeAll()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    // MARK: MovesenseViewController overrides

    override func popup(_ sender: AnyObject, title: String, text: String) {
        self.active(false)
        super.popup(sender, title: title, text: text)
    }

    override func showError(_ msg: String) {
        self.active(false)
        super.showError(msg)
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


// MARK: PopController

class PopController : UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var content: UITextView!
}


// MARK: SelectController

class SelectController : UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var picker: UIPickerView!

    private var pickerData: [String] = [String]()
    private var defaultRow = 0
    private var callOnOk: (String) -> () = { (item) in }

    public func setItems(_ items: Array<String>, defaultItem: String) {
        self.pickerData = items
        if !items.isEmpty {
            self.defaultRow = items.index(of: defaultItem)!
        }
    }

    public func onOk(_ onOk: @escaping (String) -> ()) {
        callOnOk = onOk
    }

    @IBAction func okPress(_ sender: UIButton) {
        let row = self.picker.selectedRow(inComponent: 0)
        dismiss(animated: true, completion: nil)
        callOnOk(self.pickerData[row])
    }

    @IBAction func cancelPress(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }

    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.picker.dataSource = self;
        self.picker.delegate = self;

        self.picker.selectRow(self.defaultRow, inComponent: 0, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}


// MARK: Get key for value Dictionary extension

extension Dictionary where Value: Equatable {
    func getKey(forValue val: Value) -> Key? {
        return first(where: { $1 == val })?.0
    }
}
