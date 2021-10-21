//
//  UIImage+.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/19.
//

import UIKit

extension UIImageView {
    @IBInspectable var roundImage: CGFloat {
        set {
            self.layer.cornerRadius = newValue
        }
        get {
            return self.roundImage
        }
    }
    
    @IBInspectable var circleImage: Bool {
        set {
            if newValue {
                self.layer.cornerRadius = self.bounds.size.width * 0.5
            } else {
                self.layer.cornerRadius = 0
            }
        }
        get {
            return self.circleImage
        }
    }
}
