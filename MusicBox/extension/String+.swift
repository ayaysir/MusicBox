//
//  String+.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/18.
//

import Foundation

extension String {
    subscript(_ i: Int) -> String {
        let idx1 = index(startIndex, offsetBy: i)
        let idx2 = index(idx1, offsetBy: 1)
        return String(self[idx1..<idx2])
    }
    
    subscript (r: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        return String(self[start ..< end])
    }
    
    subscript (r: CountableClosedRange<Int>) -> String {
        let startIndex =  self.index(self.startIndex, offsetBy: r.lowerBound)
        let endIndex = self.index(startIndex, offsetBy: r.upperBound - r.lowerBound)
        return String(self[startIndex...endIndex])
    }
    
    // 스트링이 비어있다면 unknown을 반환
    var unknown: String {
        if self == "" {
            return "unknown"
        } else {
            return self
        }
    }
}

extension String {
    
    var localized: String {
        return NSLocalizedString(self, tableName: "Localizable", value: self, comment: "")
    }
    
    func localizedFormat(_ arguments: CVarArg...) -> String {
        let localizedValue = self.localized
        return String(format: localizedValue, arguments: arguments)
    }
}
