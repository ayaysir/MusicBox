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
        let musicNote = MusicNote(note: Scale.E, octave: 6)
        
        // when
        let range = sut.getNoteRange(highestNote: musicNote)
        
        // then
        let firstNote = range.first
        let secondNote = range[1]
        let beforeLastNote = range[range.count - 2]
        let lastNote = range.last
        
        XCTAssertEqual(firstNote, MusicNote(note: Scale.E, octave: 6))
        XCTAssertEqual(secondNote, MusicNote(note: Scale.D_sharp, octave: 6))
        XCTAssertEqual(beforeLastNote, MusicNote(note: Scale.F, octave: 3))
        XCTAssertEqual(lastNote, MusicNote(note: Scale.E, octave: 3))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
