//
//  MusicNote.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/13.
//

import UIKit

struct Note: Equatable, Codable {
    var note: Scale
    var octave: Int
    
    var semitone: Int {
        return note.rawValue + octave * 12
    }
    
    var textValueSharp: String {
        return note.textValueForSharp + TextUtil.makeSubscriptOfNumber(octave)
    }
    
    static func getNote(semitone: Int) -> Note? {
        let octave = semitone / 12
        let noteNum = semitone % 12
        guard let note = Scale(rawValue: noteNum) else { return nil }
        return self.init(note: note, octave: octave)
    }
}

struct NoteWithHeight {
    var height: CGFloat
    var note: Note
}
