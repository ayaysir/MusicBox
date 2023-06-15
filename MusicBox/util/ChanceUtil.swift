//
//  ChanceUtil.swift
//  MusicBox
//
//  Created by yoonbumtae on 2022/12/11.
//

import Foundation

struct ChanceUtil {
    static func probability(_ probability: Double) -> Bool {
        return Double.random(in: 0...1) < probability
    }
}
