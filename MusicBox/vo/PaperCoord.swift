//
//  PaperCoord.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/13.
//

import UIKit

struct PaperCoord {
    var id: UUID = UUID()
    var musicNote: Note
    var cgPoint: CGPoint
    var snappedPoint: CGPoint
    var gridCoord: Any?
}
