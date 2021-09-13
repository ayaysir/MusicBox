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
    var cgCoord: CGPoint
    var gridCoord: Any?
}
