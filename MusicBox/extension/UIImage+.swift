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
}
