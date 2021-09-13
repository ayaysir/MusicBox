//
//  MusicBoxUtil.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/13.
//

import UIKit

class MusicBoxUtil {
    
    var highestNote: Note
    var cellWidth: CGFloat
    var cellHeight: CGFloat
    
    init() {
        self.highestNote = Note(note: .E, octave: 6)
        self.cellWidth = 58
        self.cellHeight = 22
    }
    
    init(highestNote: Note, cellWidth: CGFloat, cellHeight: CGFloat) {
        self.highestNote = highestNote
        self.cellWidth = cellWidth
        self.cellHeight = cellHeight
    }
    
    func getNoteRange() -> [Note] {
        getNoteRange(highestNote: self.highestNote)
    }
    
    func getNoteRange(highestNote: Note) -> [Note] {
        // E6 ~ E3
        var noteArray: [Note] = []
        
        let highestSemitone = highestNote.semitone
        let startSemitone = highestSemitone - (12 * 3)
        
        for semitone in (startSemitone...highestSemitone).reversed() {
            guard let note = Note.getNote(semitone: semitone) else { return [] }
            noteArray.append(note)
        }
        
        return noteArray
    }
    
    func snapToGridX(originalX: CGFloat) -> CGFloat {
        return round(originalX / cellWidth) * cellWidth - (cellWidth / 2)
    }
    
    func snapToGridY(originalY: CGFloat) -> CGFloat {
        return round(originalY / cellHeight) * cellHeight
    }
    
    func getNoteFromCGPointY(range: [NoteWithHeight], coord: CGPoint) -> Note? {
        guard range.count >= 2 else { return nil }
        let snappedY = snapToGridY(originalY: coord.y)
        
        print("snapped:", snappedY)
        if let targetNoteWithHeight = range.first(where: { $0.height == snappedY } ) {
            return targetNoteWithHeight.note
        }
        return nil
    }
}
