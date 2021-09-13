//
//  MusicBoxUtil.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/13.
//

import Foundation

class MusicBoxUtil {
    
    func getNoteRange(highestNote: MusicNote) -> [MusicNote] {
        // E6 ~ E3
        var noteArray: [MusicNote] = []
        
        let highestSemitone = highestNote.semitone
        let startSemitone = highestSemitone - (12 * 3)
        
        for semitone in (startSemitone...highestSemitone).reversed() {
            guard let note = MusicNote.getNote(semitone: semitone) else { return [] }
            noteArray.append(note)
        }
        
        return noteArray
    }
}
