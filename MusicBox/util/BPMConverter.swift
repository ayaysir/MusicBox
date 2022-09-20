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

/**
 BPM과 박자를 입력받으면 1블록(cell)당 몇 초인지 반환
 - parameter bpm: BPM
 - parameter timeSignature: 박자 정보
 - Returns: 1블록(cell)의 초(second)
 */
func durationOfOneCell(bpm: Double, timeSignature: TimeSignature) -> Double {
    let lengthOfOneBeat = 1 / (bpm / 60)
    let divNum = 16.0 / Double(timeSignature.lower)
    return lengthOfOneBeat / divNum
    
    /*
     4분의 x박자인 경우 1비트가 4분음표, 8분의 x박자인 경우 1비트가 8분음표
     1 -> / 16
     2 -> / 8
     4 -> / 4
     8 -> / 2
     16 -> / 1
     */
}
