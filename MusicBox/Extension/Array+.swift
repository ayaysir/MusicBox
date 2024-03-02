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

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
