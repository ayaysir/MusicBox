//
//  ImageUtil.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/19.
//

import UIKit

enum ResizeImageError: Error {
    case imageDataIsNil
    case sizeIsTooSmall
    case convertFailed
}

func resizeImage(image: UIImage, maxSize: Int = 100) throws -> UIImage  {
    guard let imageData = image.jpegData(compressionQuality: 0.95) else {
        throw ResizeImageError.imageDataIsNil
    }
    
    guard image.size.width >= CGFloat(maxSize) && image.size.height >= CGFloat(maxSize) else {
        guard let newImage = UIImage(data: imageData) else {
            throw ResizeImageError.convertFailed
        }
        return newImage
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
    
    guard let thumbnail = thumbnail else {
        throw ResizeImageError.convertFailed
    }
    return thumbnail
}

func convertImageToBase64String (img: UIImage) -> String {
    return img.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
}

func convertBase64StringToImage (imageBase64String:String) -> UIImage? {
    let imageData = Data.init(base64Encoded: imageBase64String, options: .init(rawValue: 0))
    let image = UIImage(data: imageData!)
    return image
}
