//
//  TextUtil.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/13.
//

import Foundation

class TextUtil {
    static func makeSuperscriptOfNumber(_ num: Int) -> String {
        if num < 0 || num > 9 {
            return ""
        }
        
        // ⁰ ¹ ² ³ ⁴ ⁵ ⁶ ⁷ ⁸ ⁹
        let array = "⁰ ¹ ² ³ ⁴ ⁵ ⁶ ⁷ ⁸ ⁹".split(separator: " ")
        return String(array[num])
    }

    static func makeSubscriptOfNumber(_ num: Int) -> String {
        if num < 0 || num > 9 {
            return ""
        }
        // ₀ ₁ ₂ ₃ ₄ ₅ ₆ ₇ ₈ ₉
        let array = "₀ ₁ ₂ ₃ ₄ ₅ ₆ ₇ ₈ ₉".split(separator: " ")
        return String(array[num])
    }
}
