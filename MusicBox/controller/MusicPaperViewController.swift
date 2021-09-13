//
//  MusicPaperViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/13.
//

import UIKit

class MusicPaperViewController: UIViewController {
    
    var previousScale: CGFloat = 1.0
    
    @IBOutlet weak var musicPaperView: MusicBoxPaperView!
    @IBOutlet weak var constraintMusicPaperWidth: NSLayoutConstraint!
    @IBOutlet weak var constraintMusicPaperHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(musicPaperView.noteRangeWithHeight)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        let gesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(sender:)))
        self.musicPaperView.addGestureRecognizer(tapGesture)
        self.musicPaperView.addGestureRecognizer(gesture)
        
    }
    
    @objc func tapAction(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: musicPaperView)
        print(point)
        musicPaperView.data.append(point)
    }
    
    @objc func pinchAction(sender:UIPinchGestureRecognizer) {
        let scale: CGFloat = previousScale * sender.scale
        self.musicPaperView.transform = CGAffineTransform(scaleX: scale, y: scale)
//        constraintMusicPaperWidth.constant = constraintMusicPaperWidth.constant * scale
//        constraintMusicPaperHeight.constant = constraintMusicPaperHeight.constant * scale
        
        previousScale = sender.scale
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
