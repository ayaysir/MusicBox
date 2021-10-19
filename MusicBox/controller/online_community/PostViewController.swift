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
    @IBOutlet weak var lblUploadedDate: UILabel!
    
    @IBOutlet weak var imgAlbumart: UIImageView!
    
    @IBOutlet weak var naviBar: UINavigationBar!
    
    @IBOutlet weak var btnDownload: UIButton!
    @IBOutlet weak var btnUpdate: UIButton!
    @IBOutlet weak var btnDelete: UIButton!
    
    @IBOutlet weak var btnHeart: HeartButton!
    @IBOutlet weak var lblLikeCount: UILabel!
    
    @IBOutlet weak var btnPreplay: UIButton!
    
    let midiManager = MIDIManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnPreplay.setTitle("", for: .normal)
        
        if let post = post {
            lblTitle.text = post.paperTitle
            lblPostWriter.text = post.writerUID
            lblOriginalArtist.text = post.paperArtist
            lblPaperMaker.text = post.paperMaker
            txvComment.text = post.postComment
            lblUploadedDate.text = "\(post.uploadDate)"
            
            naviBar.topItem?.title = post.postTitle
            
            getThumbnail(postIdStr: post.postId.uuidString)
            
            lblLikeCount.text = "\(post.likes.count)"
            
            if let currentUID = getCurrentUserUID() {
                 btnHeart.setState(post.likes[currentUID] != nil)
            }
            
            // 시퀀스 준비
            midiManager.musicSequence = midiManager.convertPaperToMIDI(paperCoords: post.preplayArr)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // 좋아요 수 실시간 갱신
        let ref = Database.database().reference()
        let targetPostLikesRef = ref.child("community/\(post.postId.uuidString)/likes")
        
        targetPostLikesRef.observe(.value) { snapshot in
            guard let dict = snapshot.value as? Dictionary<String, Any> else {
                self.lblLikeCount.text = "0"
                return
            }
            
            self.lblLikeCount.text = "\(dict.count)"
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
    
    @IBAction func btnActLike(_ sender: HeartButton) {
        
        getLikeState { targetPostLikesRef, currentUID in
            
            var likeDict = Like(likeUserUID: currentUID, postID: self.post.postId.uuidString, likedDate: Date()).dictionary
            likeDict["likedDate"] = ServerValue.timestamp()
            
            targetPostLikesRef.child(currentUID).setValue(likeDict)
            print("first like success:")
            sender.setState(true)
        } likeStateCallback: { targetPostLikesRef, currentUID in
            
            var likeDict = Like(likeUserUID: currentUID, postID: self.post.postId.uuidString, likedDate: Date()).dictionary
            likeDict["likedDate"] = ServerValue.timestamp()
            
            targetPostLikesRef.child(currentUID).setValue(likeDict)
            print("like success:")
            sender.setState(true)
        } unlikeStateCallback: { targetPostLikesRef, currentUID in
            
            targetPostLikesRef.child(currentUID).removeValue { error, ref in
                if let error = error {
                    print("unlike failed:", error.localizedDescription)
                    return
                }
                print("unlike success:")
                sender.setState(false)
            }
        }
    }
    
    @IBAction func btnActPreplay(_ sender: UIButton) {
        if midiManager.midiPlayer!.isPlaying {
            midiManager.midiPlayer?.stop()
        } else {
            midiManager.midiPlayer?.play({
                print("midi play finished")
                self.midiManager.midiPlayer?.currentPosition = 0
            })
        }
    }
    
    
    
    func getThumbnail(postIdStr: String) {
        let refPath = "PostAlbumart/\(postIdStr)/\(postIdStr).jpg"
        getFileURL(childRefStr: refPath) { url in
            self.imgAlbumart.kf.setImage(with: url)
        } failedHandler: { error in
            
        }
    }
    
    typealias RefHandler = (_ targetPostLikesRef: DatabaseReference, _ currentUID: String) -> ()
    func getLikeState(nullCallback: @escaping RefHandler, likeStateCallback: @escaping RefHandler, unlikeStateCallback: @escaping RefHandler) {
        
        guard let currentUID = getCurrentUserUID() else {
            return
        }
        
        let ref = Database.database().reference()
        let targetPostLikesRef = ref.child("community/\(post.postId.uuidString)/likes")
        
        targetPostLikesRef.observeSingleEvent(of: .value) { snapshot in
            
            guard let dict = snapshot.value as? Dictionary<String, Any> else {
                nullCallback(targetPostLikesRef, currentUID)
                return
            }
            
            if dict[currentUID] == nil {
                likeStateCallback(targetPostLikesRef, currentUID)
            } else {
                unlikeStateCallback(targetPostLikesRef, currentUID)
            }
        }
    }
}

extension PostViewController: UpdatePostVCDelegate {
    
    func didUpdateBtnClicked(_ controller: UpdatePostViewController, updatedPost: Post) {
        naviBar.topItem?.title = updatedPost.postTitle
        self.txvComment.text = updatedPost.postComment
        self.post = updatedPost
    }
}
