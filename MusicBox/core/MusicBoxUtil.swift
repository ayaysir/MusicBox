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
    var topMargin: CGFloat
    var leftMargin: CGFloat
    var noteRange: [Note]!
    
    convenience init() {
        let highestNote = Note(note: .E, octave: 6)
        self.init(highestNote: highestNote, cellWidth: 58, cellHeight: 22, topMargin: 120, leftMargin: 80)
    }
    
    init(highestNote: Note, cellWidth: CGFloat, cellHeight: CGFloat, topMargin: CGFloat, leftMargin: CGFloat) {
        
        self.highestNote = highestNote
        self.cellWidth = cellWidth
        self.cellHeight = cellHeight
        self.topMargin = topMargin
        self.leftMargin = leftMargin
        
        noteRange = getNoteRange()
    }
    
    func getNoteRange() -> [Note] {
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
    
    func getGridXFromGridBox(touchedPoint: CGPoint, snapToGridMode: Bool = false) -> Double {
        
        let relativeX = touchedPoint.x - leftMargin
        let gridX = relativeX / cellWidth
        return snapToGridMode ? round(gridX) : gridX
    }
    
    func getGridYFromGridBox(touchedPoint: CGPoint) -> Int {
        
        let rangeCount: CGFloat = noteRange.count.cgFloat
        let boxHeight = cellHeight * (rangeCount - 1)
        let relativeY = (touchedPoint.y - topMargin) / boxHeight * (rangeCount - 1)
        return Int(round(relativeY))
    }
    
    func getNoteFromGridBox(touchedPoint: CGPoint) -> Note? {
        
        let index: Int = getGridYFromGridBox(touchedPoint: touchedPoint)
        guard index >= 0 && index < noteRange.count else {
            return nil
        }
        return noteRange[Int(index)]
    }
    

    

}
