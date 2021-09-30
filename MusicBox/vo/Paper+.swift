//
//  PaperCoord.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/13.
//

import UIKit
import AudioKit

extension String {
    static let kBPM = "bpm"
    static let kCoords = "coords"
    static let kTimeSignatureUpper = "timeSignature_upper"
    static let kTimeSignatureLower = "timeSignature_lower"
    
    static let kAlbumartURL = "albumart"
    static let kPaperMaker = "paperMaker"
    static let kTitle = "title"
    static let kComment = "comment"
    
    static let kUUIDString = "uuidString"
    static let kNote = "note"
    static let kCGPoint = "cgPoint"
    static let kSnappedPoint = "snappedPoint"
    static let kGridX = "gridX"
    
    static let kScaleRawValue = "scale-rawvalue"
    static let kOctave = "octave"
    
    static let kIncompleteMeasureBeat = "imBeat"
}

struct TimeSignature: Codable {
    
    var upper: Int
    var lower: Int
    
    init() {
        self.init(upper: 4, lower: 4)
    }
    
    init(upper: Int, lower: Int) {
        self.upper = upper
        self.lower = lower
    }
    
}

class Paper: NSObject, NSCoding, NSSecureCoding, Codable {
    
    static var supportsSecureCoding: Bool = true
    
    var bpm: Int = 120
    var coords: [PaperCoord] = []
    var timeSignature: TimeSignature = TimeSignature()
    
    var incompleteMeasureBeat: Int = 0

    var albumartURL: URL?
    var paperMaker: String = ""
    var title: String = "My MusicBox Sheet"
    var comment: String = ""

    var fileId: UUID = UUID()
    
    enum CodingKeys: CodingKey {
        case bpm, coords, timeSignature, albumartURL, paperMaker, title, comment, fileId, incompleteMeasureBeat
    }
    
    override init() {
        super.init()
    }
    
    // Paper(bpm: bpm, coords: coords, timeSignature: timeSignature)
    init(bpm: Int, coords: [PaperCoord], timeSignature: TimeSignature) {
        self.bpm = bpm
        self.coords = coords
        self.timeSignature = timeSignature
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(bpm, forKey: .kBPM)
        coder.encode(coords, forKey: .kCoords)
        coder.encode(incompleteMeasureBeat, forKey: .kIncompleteMeasureBeat)
        
        coder.encode(timeSignature.upper, forKey: .kTimeSignatureUpper)
        coder.encode(timeSignature.lower, forKey: .kTimeSignatureLower)
        
        coder.encode(albumartURL, forKey: .kAlbumartURL)
        coder.encode(paperMaker, forKey: .kPaperMaker)
        coder.encode(title, forKey: .kTitle)
        coder.encode(comment, forKey: .kComment)
        
        coder.encode(fileId.uuidString, forKey: .kUUIDString)
    }
    
    required init?(coder: NSCoder) {
        super.init()
        
        // not nullable
        let bpm = coder.decodeInteger(forKey: .kBPM)
        let imBeat = coder.decodeInteger(forKey: .kIncompleteMeasureBeat)
        let tsLower = coder.decodeInteger(forKey: .kTimeSignatureLower)
        let tsUpper = coder.decodeInteger(forKey: .kTimeSignatureUpper)
        
        // not allow null
        guard
            let coords = coder.decodeObject(forKey: .kCoords) as? [PaperCoord],
            let paperMaker = coder.decodeObject(forKey: .kPaperMaker) as? String,
            let title = coder.decodeObject(forKey: .kTitle) as? String,
            let comment = coder.decodeObject(forKey: .kComment) as? String,
            let uuidString = coder.decodeObject(forKey: .kUUIDString) as? String
        else {
            print("error")
            return
        }
        
        // allow null
        let albumartURL = coder.decodeObject(forKey: .kAlbumartURL) as? URL
        
        guard let uuid = UUID(uuidString: uuidString) else { return }
        let timeSignature = TimeSignature(upper: tsUpper, lower: tsLower)
        
        self.bpm = bpm
        self.incompleteMeasureBeat = imBeat
        self.coords = coords
        self.timeSignature = timeSignature
        self.albumartURL = albumartURL
        self.paperMaker = paperMaker
        self.title = title
        self.comment = comment
        self.fileId = uuid
        
    }
    
}

class PaperCoord: NSObject, NSCoding, NSSecureCoding, Codable {
    
    static var supportsSecureCoding: Bool = true

    var paperId: UUID = UUID()
    var musicNote: Note!
    var cgPoint: CGPoint!
    var snappedPoint: CGPoint!
    var gridX: Double?
    
    enum CodingKeys: CodingKey {
        case paperId, musicNote, cgPoint, snappedPoint, gridX
    }
    
    init(musicNote: Note, cgPoint: CGPoint, snappedPoint: CGPoint) {
        self.musicNote = musicNote
        self.cgPoint = cgPoint
        self.snappedPoint = snappedPoint
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(paperId.uuidString, forKey: .kUUIDString)
        coder.encode(musicNote, forKey: .kNote)
        coder.encode(cgPoint.doubleArray, forKey: .kCGPoint)
        coder.encode(snappedPoint.doubleArray, forKey: .kSnappedPoint)
        
        if let gridX = gridX {
            coder.encode(gridX, forKey: .kGridX)
        }
    }
    
    required init?(coder: NSCoder) {
        super.init()
        
        guard
            let uuidString = coder.decodeObject(forKey: .kUUIDString) as? String,
            let musicNote = coder.decodeObject(forKey: .kNote) as? Note,
            let cgPointArr = coder.decodeObject(forKey: .kCGPoint) as? [Double],
            let snappedPointArr = coder.decodeObject(forKey: .kSnappedPoint) as? [Double]
        else {
            return
        }
        
        // allow null
        let gridX = coder.decodeDouble(forKey: .kGridX)
        
        guard let paperId = UUID(uuidString: uuidString) else {
            return
        }
        
        self.paperId = paperId
        self.musicNote = musicNote
        self.cgPoint = cgPointArr.cgPoint
        self.snappedPoint = snappedPointArr.cgPoint
        self.gridX = gridX
    }

    func setGridX(start: CGFloat, eachCellWidth: CGFloat) {
        let currentX = snappedPoint.x
        let xCGPosFromZero = currentX - start
        self.gridX = Double(xCGPosFromZero / eachCellWidth)
    }
    
    override var description: String {
        if let musicNote = musicNote, let gridX = gridX {
            return "[musicNote: \(musicNote), gridX: \(gridX)]"
        } else {
            return "[]"
        }
        
    }
}
