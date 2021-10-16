//
//  PostViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/16.
//

import UIKit
import Kingfisher

class PostViewController: UIViewController {
    
    var post: Post!
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblPostWriter: UILabel!
    @IBOutlet weak var lblOriginalArtist: UILabel!
    @IBOutlet weak var lblPaperMaker: UILabel!
    @IBOutlet weak var txvComment: UITextView!
    
    @IBOutlet weak var imgAlbumart: UIImageView!
    
    @IBOutlet weak var btnDownload: UIButton!
    @IBOutlet weak var btnUpdate: UIButton!
    @IBOutlet weak var btnDelete: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let post = post {
            lblTitle.text = post.paperTitle
            lblPostWriter.text = post.writerUID
            lblOriginalArtist.text = post.paperArtist
            lblPaperMaker.text = post.paperMaker
            txvComment.text = post.postComment
            
            getThumbnail(postIdStr: post.postId.uuidString)
        }
        
    }
    
    @IBAction func btnActDownload(_ sender: Any) {
    }
    @IBAction func btnActUpdate(_ sender: Any) {
    }
    @IBAction func btnActDelete(_ sender: Any) {
    }
    
    func getThumbnail(postIdStr: String) {
        let refPath = "PostAlbumart/\(postIdStr)/\(postIdStr).jpg"
        getFileURL(childRefStr: refPath) { url in
            self.imgAlbumart.kf.setImage(with: url)
        }
    }
}
