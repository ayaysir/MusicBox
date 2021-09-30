//
//  PaperCoordTests.swift
//  MusicBoxTests
//
//  Created by yoonbumtae on 2021/09/25.
//

import XCTest
@testable import MusicBox

class PaperCoordTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_getGridX() throws {
        let start: CGFloat = 30
        let eachCellWidth: CGFloat = 58
        let currentX: CGFloat = 325.5
        
        let coord1 = PaperCoord(musicNote: Note(note: .C, octave: 0), cgPoint: CGPoint(x: 0, y: 0), snappedPoint: CGPoint(x: currentX, y: 0))
        
        // 325.5 - 30 = 295.5
        // 295.5 / 58 = 5.094827586206897
        
        let start2: CGFloat = 52
        let eachCellWidth2: CGFloat = 61.1
        let currentX2: CGFloat = 613.3
        
        // 613.3 - 52 = 561.3
        // 561.3 / 61.1 = 9.186579378068739
        
        let coord2 = PaperCoord(musicNote: Note(note: .C, octave: 0), cgPoint: CGPoint(x: 0, y: 0), snappedPoint: CGPoint(x: currentX2, y: 0))
        
        coord1.setGridX(start: start, eachCellWidth: eachCellWidth)
        coord2.setGridX(start: start2, eachCellWidth: eachCellWidth2)
        
        XCTAssertEqual(coord1.gridX, 5.094827586206897)
        XCTAssertEqual(coord2.gridX, 9.186579378068739)
        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
