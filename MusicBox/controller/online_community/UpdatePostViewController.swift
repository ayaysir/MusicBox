//
//  UpdatePostViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/18.
//

import UIKit
import Firebase

protocol UpdatePostVCDelegate: AnyObject {
    func didUpdateBtnClicked(_ controller: UpdatePostViewController, updatedPost: Post)
}

class UpdatePostViewController: UIViewController {
    
    var post: Post!
    weak var delegate: UpdatePostVCDelegate?
    
    @IBOutlet weak var lblPaperMaker: UILabel!
    @IBOutlet weak var lblArtist: UILabel!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgAlbumart: UIImageView!
    
    @IBOutlet weak var txfPostTitle: UITextField!
    @IBOutlet weak var txvPostComment: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        lblPaperMaker.text = post.paperMaker
        lblArtist.text = post.paperArtist
        lblTitle.text = post.paperTitle
    
        txfPostTitle.text = post.postTitle
        txvPostComment.text = post.postComment
    }
    
    @IBAction func btnActUpdate(_ sender: Any) {
        if let delegate = delegate {
            post.postTitle = txfPostTitle.text ?? post.postTitle
            post.postComment = txvPostComment.text
            
            let ref = Database.database().reference()
            let targetPostRef = ref.child("community/" + post.postId.uuidString)
            targetPostRef.child("postTitle").setValue(post.postTitle)
            targetPostRef.child("postComment").setValue(post.postComment)
            
            simpleAlert(self, message: "업데이트가 완료되었습니다.", title: "업데이트 완료") { _ in
                delegate.didUpdateBtnClicked(self, updatedPost: self.post)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    

}
