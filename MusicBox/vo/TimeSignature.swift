//
//  TimeSignature.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/27.
//

import Foundation

struct TimeSignature: Codable {
    // The lower numeral indicates the note value that represents one beat (the beat unit).
    // The upper numeral indicates how many such beats constitute a bar.
    private var lowerNumber = [2, 4, 8, 16, 32]
    private var upperNumber = [2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 16, 24, 32]
    
    private var _lower: Int = 4
    private var _upper: Int = 4
    
    var lower: Int {
        set {
            if lowerNumber.contains(newValue) {
                _lower = newValue
            }
        }
        get { return _lower }
    }
    var upper: Int {
        set {
            if upperNumber.contains(newValue) {
                _upper = newValue
            }
        }
        get { return _upper }
    }
}
