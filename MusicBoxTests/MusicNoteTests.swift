//
//  MusicNoteTests.swift
//  MusicBoxTests
//
//  Created by yoonbumtae on 2021/09/13.
//

import XCTest

import XCTest
@testable import MusicBox

class MusicNoteTest: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func test_semitone() throws {
        // given
        let musicNoteF4 = MusicNote(note: Scale.F, octave: 4)
        let musicNoteC5 = MusicNote(note: Scale.C, octave: 5)
        
        // when
        let semitoneF4 = musicNoteF4.semitone
        let semitoneC5 = musicNoteC5.semitone
        
        // then
        XCTAssertEqual(semitoneF4, (12 * 4) + Scale.F.rawValue)
        XCTAssertEqual(semitoneC5, (12 * 5) + Scale.C.rawValue)
    }
    
    func test_getNoteFromSemitone() throws {
        // given
        let semitoneC5 = 60
        let semitoneA4 = (12 * 4) + Scale.A.rawValue
        let semitoneGSharp7 = (12 * 7) + Scale.G_sharp.rawValue
        
        // when
        let musicNoteC5 = MusicNote.getNote(semitone: semitoneC5)
        let musicNoteA4 = MusicNote.getNote(semitone: semitoneA4)
        let musicNoteGSharp7 = MusicNote.getNote(semitone: semitoneGSharp7)
        
        // then
        XCTAssertEqual(musicNoteC5, MusicNote(note: Scale.C, octave: 5))
        XCTAssertEqual(musicNoteA4, MusicNote(note: Scale.A, octave: 4))
        XCTAssertEqual(musicNoteGSharp7, MusicNote(note: Scale.G_sharp, octave: 7))
    }
    
    func test_textValueSharp() throws {
        let noteASharp3 = MusicNote(note: Scale.A_sharp, octave: 3)
        let noteG5 = MusicNote(note: Scale.G, octave: 5)
        
        let textValueASharp3 = noteASharp3.textValueSharp
        let textValueG5 = noteG5.textValueSharp
        
        XCTAssertEqual(textValueASharp3, "A♯₃")
        XCTAssertEqual(textValueG5, "G₅")
        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
