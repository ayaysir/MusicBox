//
//  BPMConverter.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/23.
//

import Foundation

func convertTempoToBaseQuarterNoteBPM(tempo: Double, noteDivision: Double) -> Double {
    let block = tempo / noteDivision
    return 4 * block
}
