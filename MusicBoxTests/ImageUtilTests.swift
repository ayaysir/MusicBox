//
//  ImageUtilTests.swift
//  MusicBoxTests
//
//  Created by yoonbumtae on 2021/09/19.
//

import XCTest
@testable import MusicBox

class ImageUtilTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_makeImageThumbnail() throws {
        let image = #imageLiteral(resourceName: "sample")
        let thumbnail = makeImageThumbnail(image: image)
        let thumbnail250 = makeImageThumbnail(image: image, maxSize: 250)
        
        XCTAssertNotNil(thumbnail)
        XCTAssertNotNil(thumbnail250)
        
        let maxSize = max(thumbnail!.size.width, thumbnail!.size.height)
        let maxSizeOf250 = max(thumbnail250!.size.width, thumbnail250!.size.height)
        
        XCTAssertEqual(maxSize, 100)
        XCTAssertEqual(maxSizeOf250, 250)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}