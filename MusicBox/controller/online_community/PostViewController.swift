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
import GoogleMobileAds

class PostViewController: UIViewController {
    
    private var bannerView: GADBannerView!
    
    var post: Post!
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblPostWriter: UILabel!
    @IBOutlet weak var lblOriginalArtist: UILabel!
    @IBOutlet weak var lblPaperMaker: UILabel!
    @IBOutlet weak var txvComment: UITextView!
    @IBOutlet weak var lblUploadedDate: UILabel!
    
    @IBOutlet weak var imgAlbumart: UIImageView!
    
    @IBOutlet weak var btnDownload: UIButton!
    @IBOutlet weak var btnUpdate: UIButton!
    @IBOutlet weak var btnDelete: UIButton!
    
    @IBOutlet weak var btnHeart: HeartButton!
    @IBOutlet weak var lblLikeCount: UILabel!
    
    @IBOutlet weak var btnPreplay: UIButton!
    
    @IBOutlet weak var cnstViewHeight: NSLayoutConstraint!
    @IBOutlet weak var cnstScrollViewBottom: NSLayoutConstraint!
    
    let midiManager = MIDIManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnPreplay.setTitle("", for: .normal)
        DispatchQueue.main.async  { [self] in
            let buttonWidth = btnPreplay.bounds.width
            btnPreplay.layer.cornerRadius = buttonWidth * 0.5
            btnPreplay.setImage(makeSymbol(), for: .normal)
            
            let afterHeight = txvComment.frame.maxY + 10
            if afterHeight > cnstViewHeight.constant {
                cnstViewHeight.constant = afterHeight
            }
        }
        
        if let post = post {
            lblTitle.text = post.paperTitle
            
            getNickname(of: post.writerUID) { nickname in
                let nicknameText: String = {
                    if let nickname = nickname, nickname != "" {
                        return "Posting by \(nickname)"
                    } else {
                        return "Posting by unknown"
                    }
                }()
                self.lblPostWriter.text = nicknameText
            }
            
            lblOriginalArtist.text = "Composed by \(post.paperArtist.unknown)"
            lblPaperMaker.text = "Paper made by \(post.paperMaker.unknown)"
            txvComment.text = post.postComment
            lblUploadedDate.text = "\(post.uploadDate)"
            
            getThumbnail(postIdStr: post.postId.uuidString)
            
            lblLikeCount.text = "\(post.likes.count)"
            
            if let currentUID = getCurrentUserUID() {
                 btnHeart.setState(post.likes[currentUID] != nil)
            }
            
            // ????????? ??????
            midiManager.currentBPM = post.bpm
            midiManager.musicSequence = midiManager.convertPaperToMIDI(paperCoords: post.preplayArr)
        }
        
        // ?????? ??????
        if getCurrentUserUID() == post.writerUID {
            btnDelete.isHidden = false
            btnUpdate.isHidden = false
        } else {
            btnDelete.isHidden = true
            btnUpdate.isHidden = true
        }
        
        // ????????? ??????
        let glowColor = UIColor255(red: 30, green: 238, blue: 86)
    
        btnDownload.doGlowAnimation(withColor: glowColor)
        btnDownload.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .heavy)
        btnUpdate.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btnDelete.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        
        // ====== ?????? ====== //
        TrackingTransparencyPermissionRequest()
        if AdManager.productMode {
            bannerView = setupBannerAds(self, adUnitID: AdInfo.shared.archiveMain)
            bannerView.delegate = self
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // ????????? ??? ????????? ??????
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
        
        let childRefStr = "musicbox/\(post.postId)/\(post.originaFileNameWithoutExt).musicbox"
        
        let fm = FileManager.default
        
        let dirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let checkFilePath = dirPath.first!.appendingPathComponent(post.originaFileNameWithoutExt).appendingPathExtension("musicbox")
        
        var fileSaveURL = FileUtil.getDocumentsDirectory().appendingPathComponent(post.originaFileNameWithoutExt).appendingPathExtension("musicbox")
        
        if FileManager.default.fileExists(atPath: checkFilePath.path) {
            let fileNameWithoutExt = post.originaFileNameWithoutExt
            let newFilePath = dirPath.first!.appendingPathComponent(fileNameWithoutExt + " copy").appendingPathExtension("musicbox")
            
            if !fm.fileExists(atPath: newFilePath.path) {
                // ?????? ????????? ????????????, copy ????????? ?????? ??????
                print("\(Date())::: Firebase copy result(case 1): \(newFilePath)", to: &logger)
                fileSaveURL = newFilePath
            } else {
                // ?????? ????????? ????????????, copy ????????? ?????? ???????????? ??????
                var index = 1
                while true {
                    let targetName = "\(fileNameWithoutExt) copy \(index)"
                    let targetURL = dirPath.first!.appendingPathComponent(targetName).appendingPathExtension("musicbox")
                    
                    if fm.fileExists(atPath: targetURL.path) {
                        index += 1
                        continue
                    } else {
                        fileSaveURL = targetURL
                        break
                    }
                }
            }
            
            print("\(Date())::: Firebase copy result(case 2): \(fileSaveURL)", to: &logger)
            
        } else {
            // ????????? ????????? ??????
            print("\(Date())::: Firebase copy result(case 3): \(checkFilePath)")
        }
        
        SwiftSpinner.show("Downloading file...")
        getFileAndSave(childRefSTr: childRefStr, fileSaveURL: fileSaveURL) { url in
            SwiftSpinner.hide(nil)
            simpleYesAndNo(self, message: "File download is complete. Go to the file browser?".localized, title: "Download Complete".localized) { action in
                self.tabBarController?.selectedIndex = 0
            }
        }
    }
    
    @IBAction func btnActDelete(_ sender: Any) {
        
        guard getCurrentUserUID() == post.writerUID else {
            return
        }
        
        simpleDestructiveYesAndNo(self, message: "Are you sure you want to delete this post?".localized, title: "Delete".localized) { action in
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
            DispatchQueue.main.async {
                self.btnPreplay.setImage(self.makeSymbol(systemName: "stop.circle.fill"), for: .normal)
            }
            midiManager.midiPlayer?.play({
                print("midi play finished")
                self.midiManager.midiPlayer?.currentPosition = 0
                DispatchQueue.main.async {
                    self.btnPreplay.setImage(self.makeSymbol(systemName: "play.circle.fill"), for: .normal)
                }
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
    
    func makeSymbol(systemName: String = "play.circle.fill") -> UIImage? {
        // newImageWidth / 226 = x.xxx
        let imageWidth = imgAlbumart.bounds.width
        let multiplier: CGFloat = imageWidth / 226
        let pointSize = multiplier * 30
        
        let largeConfig = UIImage.SymbolConfiguration(pointSize:  pointSize >= 30 ? pointSize : 30, weight: .bold, scale: .large)
        return UIImage(systemName: systemName, withConfiguration: largeConfig)
    }
}

extension PostViewController: UpdatePostVCDelegate {
    func didUpdatePermissionDenied(_ controller: UpdatePostViewController) {
        print("permisson denied. Real Writer UID: \(post.writerUID), Access User UID: \(getCurrentUserUID() ?? "unknown")")
    }
    
    func didUpdateBtnClicked(_ controller: UpdatePostViewController, updatedPost: Post) {
        let parent = self.parent as? PostPageViewController
        parent?.title = updatedPost.postTitle
        self.txvComment.text = updatedPost.postComment
        self.post = updatedPost
    }
}

extension PostViewController: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        cnstScrollViewBottom.constant += bannerView.adSize.size.height
    }
}
