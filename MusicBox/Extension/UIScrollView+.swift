//
//  UIScrollView+.swift
//  MusicBox
//
//  Created by 윤범태 on 2/20/25.
//

import UIKit

extension UIScrollView {
  func captureContentAsPDF() -> Data {
    let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: contentSize))
    let pdfData = pdfRenderer.pdfData { context in
      context.beginPage()
      let savedContentOffset = contentOffset
      let savedFrame = frame

      setContentOffset(.zero, animated: false)
      frame = CGRect(origin: frame.origin, size: contentSize)
      
      layer.render(in: context.cgContext)

      setContentOffset(savedContentOffset, animated: false)
      frame = savedFrame
    }
    return pdfData
  }
  
  func captureContentAsImage() -> UIImage? {
    nil
  }
}
