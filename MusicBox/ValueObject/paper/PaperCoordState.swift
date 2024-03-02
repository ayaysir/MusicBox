//
//  PaperCoordState.swift
//  MusicBox
//
//  Created by yoonbumtae on 2022/12/10.
//

import Foundation

struct PaperCoordState {
    
    enum State {
        case insert
        case remove
    }
    
    var state: State
    var coord: PaperCoord
}
