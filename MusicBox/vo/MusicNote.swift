//
//  MusicNote.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/13.
//

import Foundation

struct MusicNote: Equatable {
    var note: Scale
    var octave: Int
    
    var semitone: Int {
        return note.rawValue + octave * 12
    }
    
    var textValueSharp: String {
        return note.textValueForSharp + TextUtil.makeSubscriptOfNumber(octave)
    }
    
    static func getNote(semitone: Int) -> MusicNote? {
        let octave = semitone / 12
        let noteNum = semitone % 12
        guard let note = Scale(rawValue: noteNum) else { return nil }
        return self.init(note: note, octave: octave)
    }
}
