//  Created by react-native-create-bridge

import Foundation

@objc(HelloWorld)
class HelloWorld : NSObject {
  // Export constants to use in your native module
  func constantsToExport() -> [String : Any]! {
    return ["EXAMPLE_CONSTANT": "example"]
  }

  // Implement methods that you want to export to the native module
  @objc func exampleMethod() {
    // write method here
  }
}
