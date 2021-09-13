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
        // given
        let musicNote = Note(note: Scale.E, octave: 6)
        
        // when
        let range = sut.getNoteRange(highestNote: musicNote)
        
        // then
        let firstNote = range.first
        let secondNote = range[1]
        let beforeLastNote = range[range.count - 2]
        let lastNote = range.last
        
        XCTAssertEqual(firstNote, Note(note: Scale.E, octave: 6))
        XCTAssertEqual(secondNote, Note(note: Scale.D_sharp, octave: 6))
        XCTAssertEqual(beforeLastNote, Note(note: Scale.F, octave: 3))
        XCTAssertEqual(lastNote, Note(note: Scale.E, octave: 3))
    }
    
    func test_snapToGridX() throws {
        let originalX: CGFloat = 420
        
        let result = sut.snapToGridX(originalX: originalX)
        
        // round(420 / 58) * 58 - (58 / 2) = 7 * 58 - 29
        XCTAssertEqual(result, 377)
    }
    
    func test_snapToGridY() throws {
        let originalY: CGFloat = 387
        
        // round(387 / 22) * 22 = 18 * 22
        let result = sut.snapToGridY(originalY: originalY)
        
        XCTAssertEqual(result, 396)
    }
    
    func test_getNoteFromCGPointY() throws {
        let tolerance: CGFloat = 2
        let topMargin: CGFloat = 20
        
        let noteRange = sut.getNoteRange(highestNote: Note(note: Scale.E, octave: 6))
        
        var noteRangeWithHeight: [NoteWithHeight] = []
        for (index, note) in noteRange.enumerated() {
            let noteHeight = NoteWithHeight(height: tolerance + topMargin + sut.cellHeight * index.cgFloat, note: note)
            noteRangeWithHeight.append(noteHeight)
        }
        
        print(noteRangeWithHeight)
        
        let result1 = sut.getNoteFromCGPointY(range: noteRangeWithHeight, coord: CGPoint(x: 100, y: 227))
        let result2 = sut.getNoteFromCGPointY(range: noteRangeWithHeight, coord: CGPoint(x: 2, y: 671))
        
        XCTAssertEqual(result1, Note(note: .G, octave: 5))
        XCTAssertEqual(result2, Note(note: .A_sharp, octave: 3))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
