//
//  Decimal+.swift
//  MusicBox
//
//  Created by yoonbumtae on 2022/12/11.
//

import Foundation

extension Decimal {
    
    // https://stackoverflow.com/questions/41744278
    
    var significantFractionalDecimalDigits: Int {
        return max(-exponent, 0)
    }
}
