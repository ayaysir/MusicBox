//
//  Array+.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/30.
//

import UIKit

extension Array where Element == Double {
    var cgPoint: CGPoint {
        return CGPoint(x: self[0], y: self[1])
    }
}
