//
//  PaperCoord.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/13.
//

import UIKit

struct Paper {
    var bpm: Int
    var timeSignature: Any?
    var coords: [PaperCoord]
}

struct PaperCoord {
    var id: UUID = UUID()
    var musicNote: Note
    var cgPoint: CGPoint
    var snappedPoint: CGPoint
    var gridX: Double?
    
    mutating func setGridX(start: CGFloat, eachCellWidth: CGFloat) {
        let currentX = snappedPoint.x
        let xCGPosFromZero = currentX - start
        self.gridX = Double(xCGPosFromZero / eachCellWidth)
    }
}

