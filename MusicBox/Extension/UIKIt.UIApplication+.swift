//
//  UIKIt.UIApplication+.swift
//  MusicBox
//
//  Created by 윤범태 on 2/20/25.
//

import UIKit

extension UIApplication {
  var keyWindow: UIWindow? {
    connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }
}
