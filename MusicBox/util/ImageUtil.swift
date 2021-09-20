//
//  ImageUtil.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/19.
//

import UIKit

func makeImageThumbnail(image: UIImage, maxSize: Int = 100) -> UIImage? {
    guard let imageData = image.jpegData(compressionQuality: 0.95) else {
        return nil
    }

    let options = [
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceThumbnailMaxPixelSize: maxSize] as CFDictionary // Specify your desired size at kCGImageSourceThumbnailMaxPixelSize. I've specified 100 as per your question
    
    var thumbnail: UIImage?
    imageData.withUnsafeBytes { pointer in
       guard let bytes = pointer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
          return
       }
       if let cfData = CFDataCreate(kCFAllocatorDefault, bytes, imageData.count){
          let source = CGImageSourceCreateWithData(cfData, nil)!
          let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options)!
          thumbnail = UIImage(cgImage: imageReference) // You get your thumbail here
       }
    }
    return thumbnail
}
