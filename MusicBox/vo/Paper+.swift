//
//  PaperCoord.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/13.
//

import UIKit
import AudioKit
import AVFoundation

extension String {
    static let kBPM = "bpm"
    static let kCoords = "coords"
    static let kTimeSignatureUpper = "timeSignature_upper"
    static let kTimeSignatureLower = "timeSignature_lower"
    
    static let kAlbumartBase64 = "albumart"
    static let kThumbnailBase64 = "albumartThumbnail"
    static let kPaperMaker = "paperMaker"
    static let kTitle = "title"
    static let kComment = "comment"
    
    static let kUUIDString = "uuidString"
    static let kNote = "note"
    static let kCGPoint = "cgPoint"
    static let kSnappedPoint = "snappedPoint"
    static let kGridX = "gridX"
    static let kGridY = "gridY"
    
    static let kScaleRawValue = "scale-rawvalue"
    static let kOctave = "octave"
    
    static let kIncompleteMeasureBeat = "imBeat"
    
    static let kOriginalArtist = "artist"
    static let kColNum = "colNum"
}

class Paper: NSObject, NSCoding, NSSecureCoding, Codable {
    
    static var supportsSecureCoding: Bool = true
    
    var bpm: Int = 120
    var coords: [PaperCoord] = []
    var timeSignature: TimeSignature = TimeSignature()
    
    var colNum: Int = 80
    
    var incompleteMeasureBeat: Int = 0

//    var albumartURL: URL?
    var albumartBase64: String?
    var thumbnailBase64: String?
    
    var paperMaker: String = ""
    var title: String = "My MusicBox Sheet"
    var originalArtist: String = "J. S. Bach"
    var comment: String = ""
    
    // firebaseUID가 있는 경우에만 isAllowOthersToEdit가 유효
    var firebaseUID: String?
    var isAllowOthersToEdit: Bool? = true

    var fileId: UUID = UUID()
    
    enum CodingKeys: CodingKey {
        case bpm, coords, timeSignature, albumartBase64, thumbnailBase64, paperMaker, title, comment, fileId, incompleteMeasureBeat, colNum
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
        
        coder.encode(albumartBase64, forKey: .kAlbumartBase64)
        coder.encode(thumbnailBase64, forKey: .kThumbnailBase64)
        
        coder.encode(paperMaker, forKey: .kPaperMaker)
        coder.encode(title, forKey: .kTitle)
        coder.encode(comment, forKey: .kComment)
        
        coder.encode(originalArtist, forKey: .kOriginalArtist)
        coder.encode(colNum, forKey: .kColNum)
        
        coder.encode(fileId.uuidString, forKey: .kUUIDString)
    }
    
    required init?(coder: NSCoder) {
        super.init()
        
        // not nullable
        let bpm = coder.decodeInteger(forKey: .kBPM)
        let imBeat = coder.decodeInteger(forKey: .kIncompleteMeasureBeat)
        let tsLower = coder.decodeInteger(forKey: .kTimeSignatureLower)
        let tsUpper = coder.decodeInteger(forKey: .kTimeSignatureUpper)
        let colNum = coder.decodeInteger(forKey: .kColNum)
        
        // not allow null
        guard
            let coords = coder.decodeObject(forKey: .kCoords) as? [PaperCoord],
            let paperMaker = coder.decodeObject(forKey: .kPaperMaker) as? String,
            let title = coder.decodeObject(forKey: .kTitle) as? String,
            let comment = coder.decodeObject(forKey: .kComment) as? String,
            let uuidString = coder.decodeObject(forKey: .kUUIDString) as? String,
            let originalArtist = coder.decodeObject(forKey: .kOriginalArtist) as? String
        else {
            print("error")
            return
        }
        
        // allow null
        let albumartBase64 = coder.decodeObject(forKey: .kAlbumartBase64) as? String
        let thumbnailBase64 = coder.decodeObject(forKey: .kThumbnailBase64) as? String
        
        guard let uuid = UUID(uuidString: uuidString) else { return }
        let timeSignature = TimeSignature(upper: tsUpper, lower: tsLower)
        
        self.bpm = bpm
        self.incompleteMeasureBeat = imBeat
        self.coords = coords
        self.timeSignature = timeSignature
        
        self.albumartBase64 = albumartBase64
        self.thumbnailBase64 = thumbnailBase64
        
        self.paperMaker = paperMaker
        self.title = title
        self.comment = comment
        self.fileId = uuid
        
        self.originalArtist = originalArtist
        self.colNum = colNum
        
    }
    
}

class PaperCoord: NSObject, NSCoding, NSSecureCoding, Codable {
    
    static var supportsSecureCoding: Bool = true

    var paperId: UUID = UUID()
    var musicNote: Note!
    var absoluteTouchedPoint: CGPoint!
    var gridX: Double!
    var gridY: Int!
    
    enum CodingKeys: CodingKey {
        case paperId, musicNote, absoluteTouchedPoint, gridX
    }
    
    init(musicNote: Note, absoluteTouchedPoint: CGPoint, gridX: Double, gridY: Int) {
        self.musicNote = musicNote
        self.absoluteTouchedPoint = absoluteTouchedPoint
        self.gridX = gridX
        self.gridY = gridY
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(paperId.uuidString, forKey: .kUUIDString)
        coder.encode(musicNote, forKey: .kNote)
        coder.encode(absoluteTouchedPoint.doubleArray, forKey: .kCGPoint)

        
        if let gridX = gridX, let gridY = gridY {
            coder.encode(gridX, forKey: .kGridX)
            coder.encode(gridY, forKey: .kGridY)
        }
    }
    
    required init?(coder: NSCoder) {
        super.init()
        
        guard
            let uuidString = coder.decodeObject(forKey: .kUUIDString) as? String,
            let musicNote = coder.decodeObject(forKey: .kNote) as? Note,
            let absoluteTouchedPointArr = coder.decodeObject(forKey: .kCGPoint) as? [Double]
        else {
            return
        }
        
        // allow null
        let gridX = coder.decodeDouble(forKey: .kGridX)
        let gridY = coder.decodeInteger(forKey: .kGridY)
        
        guard let paperId = UUID(uuidString: uuidString) else {
            return
        }
        
        self.paperId = paperId
        self.musicNote = musicNote
        self.absoluteTouchedPoint = absoluteTouchedPointArr.cgPoint
        self.gridX = gridX
        self.gridY = gridY
    }
    
    override var description: String {
        if let musicNote = musicNote, let gridX = gridX, let gridY = gridY {
            return "[musicNote: \(musicNote), gridX: \(gridX), gridY: \(gridY)]"
        } else {
            return "[]"
        }
        
    }
}
