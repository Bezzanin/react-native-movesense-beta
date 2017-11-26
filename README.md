# React-Native Movesense iOS Library

## This is the demo only, full library is coming soon

## Usage

To run the example project, clone the repo, and run `pod install` in the IOS/iOS-Example directory first. Make sure you have configured your ssh public key to bitbucket beforehand. This phase should not produce any errors:

```
$ cd IOS/
$ pod install
```

Install React Native using [this](https://facebook.github.io/react-native/docs/getting-started.html) guide. After installation run

```
react-native start
```


Then open movesense-swiftapp.xcworkspace and edit the localhost IP address in 'movesense-swiftapp' => 'movesense-swiftapp' => SubscriptionDetailViewController.swift 

```
let jsCodeLocation = URL(string: "YOUR_IP_ADDRESS:PORT")
```

### Bundle identifier ###

You need to replace 'com.suunto.movesense' bundle identifier with your own bundle identifier.

### Signing ###

In order to sign the application, you need to setup your own developer provisioning profile in Xcode.

### Running the application ###

After the previous step, you are ready to go and can install the application on the device. 

However, you still need to enable the developer certificate in Settings -> General -> Device Management.