//
//  UIApplication+.swift
//  MusicBox
//
//  Created by yoonbumtae on 2022/12/11.
//

import UIKit

extension UIApplication {
    
    // https://stackoverflow.com/questions/31367387/detect-if-app-is-running-in-slide-over-or-split-view-mode-in-ios-9
    
    public var isSplitOrSlideOver: Bool {
        guard let window = self.windows.filter({ $0.isKeyWindow }).first else { return false }
        return !(window.frame.width == window.screen.bounds.width)
    }
}
