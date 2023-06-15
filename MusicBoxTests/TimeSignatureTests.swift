//
//  TimeSignatureTests.swift
//  MusicBoxTests
//
//  Created by yoonbumtae on 2021/10/06.
//

import XCTest
@testable import MusicBox

class TimeSignatureTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_TimgSignatureToGridInfo() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let upperOf4 = [4, 3, 5, 7, 12, 2]
        let resultOf4 = [
            GridInfo(boldLineInterval: 4, bolderLineInterval: 16, toggleBackgroundInterval: 8),
            GridInfo(boldLineInterval: 4, bolderLineInterval: 12, toggleBackgroundInterval: 12),
            GridInfo(boldLineInterval: 4, bolderLineInterval: 20, toggleBackgroundInterval: 4),
            GridInfo(boldLineInterval: 4, bolderLineInterval: 28, toggleBackgroundInterval: 4),
            GridInfo(boldLineInterval: 4, bolderLineInterval: 48, toggleBackgroundInterval: 12),
            GridInfo(boldLineInterval: 4, bolderLineInterval: 8, toggleBackgroundInterval: 4)
        ]
        
        let upperOf2 = [4, 3, 5, 7, 12, 2]
        let resultOf2 = [
            GridInfo(boldLineInterval: 8, bolderLineInterval: 32, toggleBackgroundInterval: 16),
            GridInfo(boldLineInterval: 8, bolderLineInterval: 24, toggleBackgroundInterval: 24),
            GridInfo(boldLineInterval: 8, bolderLineInterval: 40, toggleBackgroundInterval: 8),
            GridInfo(boldLineInterval: 8, bolderLineInterval: 56, toggleBackgroundInterval: 8),
            GridInfo(boldLineInterval: 8, bolderLineInterval: 96, toggleBackgroundInterval: 12),
            GridInfo(boldLineInterval: 8, bolderLineInterval: 16, toggleBackgroundInterval: 8)
        ]
        
        let upperOf8 = [3, 4, 5, 6, 7, 9, 12, 15]
        let resultOf8 = [
            GridInfo(boldLineInterval: 2, bolderLineInterval: 6, toggleBackgroundInterval: 6),
            GridInfo(boldLineInterval: 2, bolderLineInterval: 8, toggleBackgroundInterval: 4),
            GridInfo(boldLineInterval: 2, bolderLineInterval: 10, toggleBackgroundInterval: 2),
            GridInfo(boldLineInterval: 2, bolderLineInterval: 12, toggleBackgroundInterval: 6),
            GridInfo(boldLineInterval: 2, bolderLineInterval: 14, toggleBackgroundInterval: 2),
            GridInfo(boldLineInterval: 2, bolderLineInterval: 18, toggleBackgroundInterval: 6),
            GridInfo(boldLineInterval: 2, bolderLineInterval: 24, toggleBackgroundInterval: 12),
            GridInfo(boldLineInterval: 2, bolderLineInterval: 30, toggleBackgroundInterval: 15),
        ]
        
        let others = [
            TimeSignature(upper: 7, lower: 1),
            TimeSignature(upper: 4, lower: 3),
            TimeSignature(upper: 153, lower: 177)
        ]
        
        for (index, upper) in upperOf4.enumerated() {
            XCTAssertEqual(TimeSignature(upper: upper, lower: 4).gridInfo, resultOf4[index])
        }
        
        for (index, upper) in upperOf2.enumerated() {
            XCTAssertEqual(TimeSignature(upper: upper, lower: 2).gridInfo, resultOf2[index])
        }
        
        for (index, upper) in upperOf8.enumerated() {
            XCTAssertEqual(TimeSignature(upper: upper, lower: 8).gridInfo, resultOf8[index])
        }
        
        for other in others {
            XCTAssertEqual(other.gridInfo, GridInfo(boldLineInterval: 4, bolderLineInterval: 16, toggleBackgroundInterval: 8))
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
