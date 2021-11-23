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
    func didUpdatePermissionDenied(_ controller: UpdatePostViewController)
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
        
        guard getCurrentUserUID() == post.writerUID else {
            delegate?.didUpdatePermissionDenied(self)
            self.navigationController?.popViewController(animated: true)
            return
        }

        lblPaperMaker.text = post.paperMaker
        lblArtist.text = post.paperArtist
        lblTitle.text = post.paperTitle
    
        txfPostTitle.text = post.postTitle
        txvPostComment.text = post.postComment
        
        txfPostTitle.delegate = self
    }
    
    @IBAction func barBtnActUpdate(_ sender: Any) {
        
        if let delegate = delegate {
            
            guard validateFieldValues() else {
                return
            }
            
            post.postTitle = txfPostTitle.text ?? post.postTitle
            post.postComment = txvPostComment.text
            
            let ref = Database.database().reference()
            let targetPostRef = ref.child("community/" + post.postId.uuidString)
            targetPostRef.child("postTitle").setValue(post.postTitle)
            targetPostRef.child("postComment").setValue(post.postComment)
            
            simpleAlert(self, message: "The post update is complete.", title: "Update Completed") { _ in
                delegate.didUpdateBtnClicked(self, updatedPost: self.post)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

extension UpdatePostViewController {
    private func validateFieldValues() -> Bool {
        
        let alertTitle = "Unable to Create"
        
        // title
        guard txfPostTitle.text! != "" else {
            simpleAlert(self, message: "Please enter the title.", title: alertTitle) { action in
                self.txfPostTitle.becomeFirstResponder()
            }
            return false
        }

        guard txfPostTitle.text!.count <= 50 else {
            simpleAlert(self, message: "Please write the title within 50 characters.", title: alertTitle) { action in
                self.txfPostTitle.becomeFirstResponder()
            }
            return false
        }

        // comment
        guard txvPostComment.text!.count <= 5000 else {
            simpleAlert(self, message: "Please write the comment within 5000 characters.", title: alertTitle) { action in
                self.txvPostComment.becomeFirstResponder()
            }
            return false
        }
        
        return true
    }
}

extension UpdatePostViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case txfPostTitle:
            txvPostComment.becomeFirstResponder()
        default:
            break
        }
        
        return true
    }
}
