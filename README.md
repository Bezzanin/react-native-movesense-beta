# Movesense iOS Library

## Example

To run the example project, clone the repo, and run `pod install` in the IOS/iOS-Example directory first. Make sure you have configured your ssh public key to bitbucket beforehand. This phase should not produce any errors:

```
$ cd IOS/iOS-Example/
$ pod install
Analyzing dependencies
Pre-downloading: `Movesense` from `ssh://git@altssh.bitbucket.org:443/suunto/movesense-mobile-lib.git`
Pre-downloading: `SwiftCharts` from `https://github.com/i-schuetz/SwiftCharts.git`, branch `master`
Downloading dependencies
Installing Movesense (1.0.0)
Installing PromiseKit (4.1.3)
Installing SwiftCharts (0.5.1)
Installing SwiftyJSON (3.1.4)
Installing Toast-Swift (2.0.0)
Generating Pods project
Integrating client project
Sending stats
Pod installation complete! There are 5 dependencies from the Podfile and 5 total pods installed.
```

Then open movesense-swiftapp.xcworkspace and build target 'movesense-swiftapp'. 

### Bundle identifier ###

You need to replace 'com.suunto.movesense' bundle identifier with your own bundle identifier.

### Signing ###

In order to sign the application, you need to setup your own developer provisioning profile in Xcode.

### Running the application ###

After the previous step, you are ready to go and can install the application on the device. 

However, you still need to enable the developer certificate in Settings -> General -> Device Management.

Finally, run the app!

## Installation

Movesense is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Movesense', :git => 'ssh://git@altssh.bitbucket.org:443/suunto/movesense-mobile-lib.git'
```
## Usage

### BLE connection

Before any requests can be made to any paths, device has to be in "Connected" state. This means awaiting for deviceFound event from the MovesenseService after the connectPeripheral has been issued. This is depicted in below SDL State Chart.

![BLE_States.png](https://bitbucket.org/repo/oGbGqA/images/434026262-4279305750-BLE_States.png)

Issuing disconnectPeripheral will be lead to a subsequent didDisconnectPeripheral event, but this may be preceded by some other events. 
When issuing disconnectPeripheral, make sure the check the return value, because disconnectPeripheral may not always be accepted (for example if device is already "Disconnected").

NOTE: Do not try to connect to peripherals via CBCentral on iOS, library does that for you. Only scanning of devices is done via CBCentral on the application side.

### Operations on a Movesense device

When a device is "Connected" all paths become available. One can do one-time GET/PUT/POST/DEL operations or choose to subscribe to the path in order to receive notifications. Receiving deviceLost event, means that all subscriptions are forgotten, so make sure to subscribe again when deviceFound is received.
