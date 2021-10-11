//
//  UIButton+.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/10.
//

import UIKit

extension UIButton {
    var circleButton: Bool {
        set {
            if newValue {
                self.layer.cornerRadius = 0.5 * self.bounds.size.width
            } else {
                self.layer.cornerRadius = 0
            }
        } get {
            return self.layer.cornerRadius != 0
        }
    }
}
