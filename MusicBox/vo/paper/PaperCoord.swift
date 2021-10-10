//
//  PaperCoord.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/10.
//

import UIKit

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
