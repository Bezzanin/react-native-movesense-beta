//  Created by react-native-create-bridge

import { NativeModules } from 'react-native'

const { HelloWorld } = NativeModules

export default {
  exampleMethod () {
    return HelloWorld.exampleMethod()
  },

  EXAMPLE_CONSTANT: HelloWorld.EXAMPLE_CONSTANT
}
