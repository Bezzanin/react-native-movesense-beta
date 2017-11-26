//
//  movesense_swiftappTests.swift
//  movesense-swiftappTests
//
//  Created by Lindqvist, Markus on 07/11/2016.
//  Copyright © 2016 Suunto. All rights reserved.
//

import XCTest
import SwiftyJSON
@testable import movesense_swiftapp

class MovesenseTests: XCTestCase {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
}
