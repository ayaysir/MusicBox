//
//  UIButton+.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/10.
//

import UIKit

extension UIButton {
    @IBInspectable var circleButton: Bool {
        set(isCircle) {
            if isCircle {
                self.layer.cornerRadius = 0.5 * self.bounds.size.width
            } else {
                self.layer.cornerRadius = 0
            }
        } get {
            return self.circleButton
        }
    }
}
