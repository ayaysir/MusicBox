//
//  MIDIBridge.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/27.
//

import Foundation

class PaperInfoBridge {
    static var shared = PaperInfoBridge()
    
    var currentBPM: Int?
    
    // 못갖춘마디가 있다면 16분음표 기준으로 몇인지?
    var incompleteMeasureBeatCount: Int!
    
    var currentPaperName: String!
    
    init() {
        reset()
    }
    
    func reset() {
        currentBPM = 100
        incompleteMeasureBeatCount = 0
        currentPaperName = "paper"
    }
    
    
}
