//
//  Double+.swift
//  MusicBox
//
//  Created by yoonbumtae on 2022/12/11.
//

import Foundation

extension Double {
    var decimalCount: Int {
        if self == Double(Int(self)) {
            return 0
        }
        
        let integerString = String(Int(self))
        let doubleString = String(Double(self))
        let decimalCount = doubleString.count - integerString.count - 1
        
        return decimalCount
    }
}
