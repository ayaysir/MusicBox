//
//  PostViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/16.
//

import UIKit
import Kingfisher
import SwiftSpinner
import Firebase

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
    
    @IBOutlet weak var naviBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let post = post {
            lblTitle.text = post.paperTitle
            lblPostWriter.text = post.writerUID
            lblOriginalArtist.text = post.paperArtist
            lblPaperMaker.text = post.paperMaker
            txvComment.text = post.postComment
            
            naviBar.topItem?.title = post.postTitle
            
            getThumbnail(postIdStr: post.postId.uuidString)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UpdatePostSegue" {
            let updateVC = segue.destination as? UpdatePostViewController
            updateVC?.post = post
            updateVC?.delegate = self
            
        }
    }
    
    @IBAction func btnActDownload(_ sender: Any) {
        guard let post = post else { return }
        let fileSaveURL = FileUtil.getDocumentsDirectory().appendingPathComponent(post.originaFileNameWithoutExt).appendingPathExtension("musicbox")
        let childRefStr = "musicbox/\(post.postId)/\(post.originaFileNameWithoutExt).musicbox"
        
        SwiftSpinner.show("파일 다운로드중...")
        getFileAndSave(childRefSTr: childRefStr, fileSaveURL: fileSaveURL) { url in
            SwiftSpinner.hide(nil)
            simpleYesAndNo(self, message: "파일 다운로드가 완료되었습니다. 브라우저로 이동할까요?", title: "다운로드 완료") { action in
                self.tabBarController?.selectedIndex = 0
            }
        }
    }
    
    @IBAction func btnActUpdate(_ sender: Any) {
    }
    
    @IBAction func btnActDelete(_ sender: Any) {
        simpleDestructiveYesAndNo(self, message: "정말 이 글을 삭제할까요?", title: "삭제") { action in
            let ref = Database.database().reference()
            let targetPostRef = ref.child("community").child(self.post.postId.uuidString)
            targetPostRef.removeValue { error, ref in
                
                if let error = error {
                    print("not deleted:", error.localizedDescription)
                }
                print("deleted:", ref)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func getThumbnail(postIdStr: String) {
        let refPath = "PostAlbumart/\(postIdStr)/\(postIdStr).jpg"
        getFileURL(childRefStr: refPath) { url in
            self.imgAlbumart.kf.setImage(with: url)
        }
    }
}

extension PostViewController: UpdatePostVCDelegate {
    
    func didUpdateBtnClicked(_ controller: UpdatePostViewController, updatedPost: Post) {
        self.naviBar.topItem?.title = updatedPost.postTitle
        self.txvComment.text = updatedPost.postComment
        self.post = updatedPost
    }
}
