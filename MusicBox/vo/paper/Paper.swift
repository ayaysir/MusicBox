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
    
    static let kAlbumart = "albumart"
    static let kThumbnail = "thumbnail"
    
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
    
    static let kFirebaseUID = "firebaseUID"
    static let kAllowOthersToEdit = "allowOthersEdit"
    static let kUploaded = "_uploaded"
}

class Paper: NSObject, NSCoding, NSSecureCoding, Codable {
    
    static var supportsSecureCoding: Bool = true
    
    var bpm: Double = 120
    var coords: [PaperCoord] = []
    var timeSignature: TimeSignature = TimeSignature()
    
    var colNum: Int = 80
    
    var incompleteMeasureBeat: Int = 0
    
    var albumartImageData: Data?
    var thumbnailImageData: Data?
    
    var paperMaker: String = ""
    var title: String = "My MusicBox Sheet"
    var originalArtist: String = "J. S. Bach"
    var comment: String = ""
    
    // firebaseUID가 있는 경우에만 isAllowOthersToEdit가 유효
    var firebaseUID: String?
    var isAllowOthersToEdit: Bool = true
    var isUploaded: Bool = false

    var fileId: UUID = UUID()
    
    enum CodingKeys: CodingKey {
        case bpm, coords, timeSignature, albumartImageData, thumbnailImageData, paperMaker, title, comment, fileId, incompleteMeasureBeat, colNum
    }
    
    override init() {
        super.init()
    }
    
    // Paper(bpm: bpm, coords: coords, timeSignature: timeSignature)
    init(bpm: Double, coords: [PaperCoord], timeSignature: TimeSignature) {
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
        
        coder.encode(albumartImageData, forKey: .kAlbumart)
        coder.encode(thumbnailImageData, forKey: .kThumbnail)
        
        coder.encode(paperMaker, forKey: .kPaperMaker)
        coder.encode(title, forKey: .kTitle)
        coder.encode(comment, forKey: .kComment)
        
        coder.encode(originalArtist, forKey: .kOriginalArtist)
        coder.encode(colNum, forKey: .kColNum)
        
        coder.encode(firebaseUID, forKey: .kFirebaseUID)
        coder.encode(isAllowOthersToEdit, forKey: .kAllowOthersToEdit)
        coder.encode(isUploaded, forKey: .kUploaded)
        
        coder.encode(fileId.uuidString, forKey: .kUUIDString)
    }
    
    required init?(coder: NSCoder) {
        super.init()
        
        // not nullable
        let bpm = coder.decodeDouble(forKey: .kBPM)
        let imBeat = coder.decodeInteger(forKey: .kIncompleteMeasureBeat)
        let tsLower = coder.decodeInteger(forKey: .kTimeSignatureLower)
        let tsUpper = coder.decodeInteger(forKey: .kTimeSignatureUpper)
        let colNum = coder.decodeInteger(forKey: .kColNum)
        
        let isAllowOthersToEdit = coder.decodeBool(forKey: .kAllowOthersToEdit)
        let isUploaded = coder.decodeBool(forKey: .kUploaded)
        
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
        let albumart = coder.decodeObject(forKey: .kAlbumart) as? Data
        let thumbnail = coder.decodeObject(forKey: .kThumbnail) as? Data
        
        let firebaseUID = coder.decodeObject(forKey: .kFirebaseUID) as? String
        
        guard let uuid = UUID(uuidString: uuidString) else { return }
        let timeSignature = TimeSignature(upper: tsUpper, lower: tsLower)
        
        self.bpm = bpm
        self.incompleteMeasureBeat = imBeat
        self.coords = coords
        self.timeSignature = timeSignature

        self.albumartImageData = albumart
        self.thumbnailImageData = thumbnail
        
        self.paperMaker = paperMaker
        self.title = title
        self.comment = comment
        self.fileId = uuid
        
        self.originalArtist = originalArtist
        self.colNum = colNum
        
        self.firebaseUID = firebaseUID
        self.isAllowOthersToEdit = isAllowOthersToEdit
        self.isUploaded = isUploaded
        
    }
    
}

