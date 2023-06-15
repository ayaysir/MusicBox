//
//  MusicBoxTests.swift
//  MusicBoxTests
//
//  Created by yoonbumtae on 2021/09/09.
//

import XCTest
@testable import MusicBox

class MusicBoxTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_reset_KEY_OnlyOnce_SpeechBubbleForNoticeUserInfoFeature() throws {
        let KEY_OnlyOnce_SpeechBubbleForNoticeUserInfoFeature = "OnlyOnce_SpeechBubbleForNoticeUserInfoFeature"
        UserDefaults.standard.set(false, forKey: KEY_OnlyOnce_SpeechBubbleForNoticeUserInfoFeature)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
