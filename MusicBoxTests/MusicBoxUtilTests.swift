//
//  MusicBoxUtilTests.swift
//  MusicBoxTests
//
//  Created by yoonbumtae on 2021/09/13.
//

import XCTest
@testable import MusicBox

class MusicBoxUtilTests: XCTestCase {
    
    var sut: MusicBoxUtil!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = MusicBoxUtil()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func test_getNoteRange() throws {
        
        sut.highestNote = Note(note: Scale.E, octave: 6)
        let range = sut.getNoteRange()
        
        // then
        let firstNote = range.first
        let secondNote = range[1]
        let beforeLastNote = range[range.count - 2]
        let lastNote = range.last
        
        XCTAssert(firstNote!.equalTo(rhs: Note(note: Scale.E, octave: 6)))
        XCTAssert(secondNote.equalTo(rhs: Note(note: Scale.D_sharp, octave: 6)))
        XCTAssert(beforeLastNote.equalTo(rhs: Note(note: Scale.C_sharp, octave: 3)))
        XCTAssert(lastNote!.equalTo(rhs: Note(note: Scale.C, octave: 3)))
    }
    
    func test_getGridXFromGridBox() throws {
        
        sut.cellWidth = 58
        sut.leftMargin = 100
        let touchedPoint = CGPoint(x: 433, y: 0)
        
        let result = sut.getGridXFromGridBox(touchedPoint: touchedPoint)
        
        // 433 - 100 = 333
        // 333 / 58 = 5.7413793103
        // round : round(5.74138 * 100) / 100
        let roundedResult = round(result * 100) / 100
        XCTAssertEqual(roundedResult, 5.74)
        
        sut.cellWidth = 193
        sut.leftMargin = 5
        let touchedPoint2 = CGPoint(x: 29964, y: 0)
        
        // 29964 - 5 = 29,959
        // 29959 / 193 = 155.23
        let result2 = sut.getGridXFromGridBox(touchedPoint: touchedPoint2, snapToGridMode: true)
        XCTAssertEqual(round(result2), 155)
    }
    
    func test_getGridYFromGridBox() throws {
        
        sut.cellHeight = 25
        sut.topMargin = 107
        sut.highestNote = Note(note: Scale.E, octave: 6)
        
        let touchedPoint = CGPoint(x: 0, y: 178)

        // 900 = 25 * 36
        // 2.84 = (178 - 107) / 900 * 36
        let result = sut.getGridYFromGridBox(touchedPoint: touchedPoint)

        XCTAssertEqual(result, 3)
    }

    func test_getNoteFromGridBox() throws {
        /*
         let index: Int = getGridYFromGridBox(touchedPoint: touchedPoint)
         guard index >= 0 && index < noteRange.count else {
             return nil
         }
         return noteRange[Int(index)]
         */
        
        sut.cellHeight = 25
        sut.topMargin = 107
        sut.highestNote = Note(note: Scale.E, octave: 6)
        
        let touchedPoint = CGPoint(x: 0, y: 178) // 3
        let touchedPoint2 = CGPoint(x: 0, y: 287) // 7

        guard let result1 = sut.getNoteFromGridBox(touchedPoint: touchedPoint),
              let result2 = sut.getNoteFromGridBox(touchedPoint: touchedPoint2)
        else {
            XCTFail()
            return
        }

        XCTAssert(result1 == Note(note: Scale.C_sharp, octave: 6))
        XCTAssert(result2 == Note(note: .A, octave: 5))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
