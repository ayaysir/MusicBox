//
//  ColorUtil.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/17.
//

import UIKit

func UIColor255(red: Int, green: Int, blue: Int, alpha: Int = 255) -> UIColor {
    return UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: CGFloat(alpha) / 255)
}
