//
//  HeartButton.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/18.
//

import UIKit

class HeartButton: UIButton {
    
    var isLiked = false
    
    private let unlikedImage = UIImage(systemName: "heart")
    private let likedImage = UIImage(systemName: "heart.fill")
    
    public func flipLikedState() {
        isLiked = !isLiked
        animate()
    }
    
    public func setState(_ isLiked: Bool) {
        self.isLiked = isLiked
        animate()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        setImage(unlikedImage, for: .normal)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func animate() {
        // Step 1
        UIView.animate(withDuration: 0.1, animations: {
            let newImage = self.isLiked ? self.likedImage : self.unlikedImage
            self.transform = self.transform.scaledBy(x: 0.75, y: 0.75)
            self.setImage(newImage, for: .normal)
        }, completion: { _ in
            // Step 2
            UIView.animate(withDuration: 0.1, animations: {
                self.transform = CGAffineTransform.identity
            })
        })
    }
}
