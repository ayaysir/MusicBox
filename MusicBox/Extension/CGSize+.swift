//
//  CGSize+.swift
//  MusicBox
//
//  Created by yoonbumtae on 2022/09/21.
//

import CoreGraphics

extension CGSize {
    func scale(_ scale: CGFloat) -> CGSize {
        return CGSize(width: self.width * scale, height: self.height * scale)
    }
}
