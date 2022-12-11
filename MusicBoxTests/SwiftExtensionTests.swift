//
//  SwiftExtensionTests.swift
//  MusicBoxTests
//
//  Created by yoonbumtae on 2021/09/30.
//

import XCTest
@testable import MusicBox

class SwiftExtensionTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_CGPointToDoubleArrayAndReverse() throws {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let point1 = CGPoint(x: 42.3, y: 16.6)
        let point1Arr = point1.doubleArray
        let arr1 = [155.34, 992.2]
        
        XCTAssertEqual(point1, point1Arr.cgPoint)
        XCTAssertEqual(point1Arr, [42.3, 16.6])
        XCTAssertEqual(arr1.cgPoint, CGPoint(x: 155.34, y: 992.2))
    }
    
    func test_makeBool() throws {
        let totalCount = 10000
        let probability: Double = 0.277
        
        var trueCount = 0
        var trueCountProb0 = 0
        var trueCountProb1 = 0
        
        for _ in 1...totalCount {
            trueCountProb0 += ChanceUtil.probability(_ probability: 0.0) ? 1 : 0
            trueCountProb1 += ChanceUtil.probability(_ probability: 1.0) ? 1 : 0
            trueCount += ChanceUtil.probability(_ probability: probability) ? 1 : 0
        }
        
        print(trueCount, totalCount, Double(trueCount) / Double(totalCount))
        XCTAssertEqual(trueCountProb0, 0)
        XCTAssertEqual(trueCountProb1, totalCount)
    }
}
