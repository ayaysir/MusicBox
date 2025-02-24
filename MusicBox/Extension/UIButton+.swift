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
  
  func invertImage() {
    guard let image = image(for: .normal)?.cgImage else { return }
    let ciImage = CIImage(cgImage: image)
    
    let filter = CIFilter(name: "CIColorInvert")
    filter?.setValue(ciImage, forKey: kCIInputImageKey)
    
    if let outputImage = filter?.outputImage {
      let context = CIContext()
      if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
        let invertedImage = UIImage(cgImage: cgImage)
        setImage(invertedImage, for: .normal)
      }
    }
  }
}
