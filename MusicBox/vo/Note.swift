//
//  MusicNote.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/13.
//

import UIKit



class Note: NSObject, NSCoding, NSSecureCoding, Codable {
    
    static var supportsSecureCoding: Bool = true
    
    var note: Scale!
    var octave: Int!
    
    private enum CodingKeys: String, CodingKey {
        case note, octave
    }
    
    init(note: Scale, octave: Int) {
        self.note = note
        self.octave = octave
    }
    
    required init?(coder: NSCoder) {
        super.init()
        
        let decodedNoteRawValue = coder.decodeInteger(forKey: .kScaleRawValue)
        let decodedOctave = coder.decodeInteger(forKey: .kOctave)

        guard let note = Scale(rawValue: decodedNoteRawValue) else { return }
        
        self.note = note
        self.octave = decodedOctave
    }
    
    func encode(with coder: NSCoder) {
        
        guard let note = note, let octave = octave else { return }
        
        coder.encode(note.rawValue, forKey: .kScaleRawValue)
        coder.encode(octave, forKey: .kOctave)
    }
    
    var semitone: Int {
        return note.rawValue + octave * 12
    }
    
    var textValueSharp: String {
        return note.textValueForSharp + TextUtil.makeSubscriptOfNumber(octave)
    }
    
    func equalTo(rhs: Note) -> Bool {
        return self.note == rhs.note && self.octave == rhs.octave
    }
    
    static func ==(lhs: Note, rhs: Note) -> Bool {
        return lhs.note == rhs.note && lhs.octave == rhs.octave
    }
    
    static func getNote(semitone: Int) -> Note? {
        let octave = semitone / 12
        let noteNum = semitone % 12
        guard let note = Scale(rawValue: noteNum) else { return nil }
        return Note(note: note, octave: octave)
    }
    
    override var description: String {
        if let note = note, let octave = octave {
            return "(note: \(note), octave: \(octave))"
        } else {
            return "()"
        }
        
    }
}

struct NoteDisplayWithHeight {
    var height: CGFloat
    var note: Note
}
