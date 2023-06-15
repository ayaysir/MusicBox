//
//  UIViewController+.swift
//  MusicBox
//
//  Created by yoonbumtae on 2022/09/22.
//

import UIKit

extension UIViewController {
    var topBarHeight: CGFloat {
        var top = self.navigationController?.navigationBar.frame.height ?? 0.0
        
        if #available(iOS 13.0, *) {
            top += UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            top += UIApplication.shared.statusBarFrame.height
        }
        
        return top
    }
}
