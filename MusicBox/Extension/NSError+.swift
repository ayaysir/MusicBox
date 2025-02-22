//
//  NSError+.swift
//  MusicBox
//
//  Created by 윤범태 on 2/21/25.
//

import Foundation

extension NSError {
  static func app(_ message: String) -> NSError {
    return NSError(domain: "com.bgsmm.MusicBox.error", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
  }
}
