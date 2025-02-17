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
import Lottie

class PostViewController: UIViewController {
  private var interstitial: InterstitialAd?
  
  lazy var lottieView: LottieAnimationView = {
    let animationView = LottieAnimationView(name: "129574-ginger-bread-socks-christmas")
    animationView.frame = CGRect(x: 0, y: 0,
                                 width: 250, height: 250)
    animationView.center = imgAlbumart.center
    animationView.contentMode = .scaleAspectFill
    animationView.stop()
    animationView.isHidden = true
    animationView.loopMode = .loop
    
    animationView.layer.shadowColor = UIColor.black.cgColor
    animationView.layer.shadowOpacity = 0.7
    animationView.layer.shadowOffset = .zero
    animationView.layer.shadowRadius = 7
    
    return animationView
  }()
  
  private var bannerView: BannerView!
  
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
  
  // 광고 배너로 height 올리는거 한 번만 실행
  var bottomConstantRaiseOnce = true
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.addSubview(lottieView)
    lottieView.isHidden = false
    lottieView.play()
    
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
      self.title = post.postTitle
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
      
      // 업로드 날짜
      let formatter = DateFormatter()
      formatter.timeZone = .autoupdatingCurrent
      formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
      let timezoneAbbr = TimeZone.abbreviationDictionary.first { $1 == formatter.timeZone.identifier }
      
      lblUploadedDate.text = formatter.string(from: post.uploadDate)
      if let timezoneAbbr = timezoneAbbr {
        lblUploadedDate.text! += " (\(timezoneAbbr.key))"
      }
      
      getThumbnail(postIdStr: post.postId.uuidString)
      
      lblLikeCount.text = "\(post.likes.count)"
      
      if let currentUID = getCurrentUserUID() {
        btnHeart.setState(post.likes[currentUID] != nil)
      }
      
      // 시퀀스 준비
      midiManager.currentBPM = post.bpm
      midiManager.musicSequence = midiManager.convertPaperToMIDI(paperCoords: post.preplayArr)
    }
    
    // 권한 설정
    if getCurrentUserUID() == post.writerUID {
      btnDelete.isHidden = false
      btnUpdate.isHidden = false
    } else {
      btnDelete.isHidden = true
      btnUpdate.isHidden = true
    }
    
    // 텍스트 효과
    let glowColor = UIColor255(red: 30, green: 238, blue: 86)
    
    btnDownload.doGlowAnimation(withColor: glowColor)
    btnDownload.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .heavy)
    btnUpdate.titleLabel?.font = UIFont.systemFont(ofSize: 15)
    btnDelete.titleLabel?.font = UIFont.systemFont(ofSize: 15)
    
    // ====== 광고 ====== //
    TrackingTransparencyPermissionRequest()
    if AdManager.isReallyShowAd {
      bannerView = setupBannerAds(self, adUnitID: AdInfo.shared.archiveMain)
      bannerView.delegate = self
    }
    
    SwiftSpinner.hide()
    
    prepareFullScreenAd()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
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
  
  override func viewWillDisappear(_ animated: Bool) {
    midiManager.midiPlayer?.stop()
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    bannerView?.fitInView(self)
  }
  
  override func willMove(toParent parent: UIViewController?) {
    if AdManager.isReallyShowAd, let interstitial {
      interstitial.present(from: self)
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
        // 기존 파일이 존재하며, copy 파일은 없는 경우
        print("\(Date())::: Firebase copy result(case 1): \(newFilePath)", to: &logger)
        fileSaveURL = newFilePath
      } else {
        // 기존 파일이 존재하며, copy 파일도 이미 존재하는 경우
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
      // 새로운 파일인 경우
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
      
      Vibration.medium.vibrate()
      sender.setState(true)
    } likeStateCallback: { targetPostLikesRef, currentUID in
      var likeDict = Like(likeUserUID: currentUID, postID: self.post.postId.uuidString, likedDate: Date()).dictionary
      likeDict["likedDate"] = ServerValue.timestamp()
      
      targetPostLikesRef.child(currentUID).setValue(likeDict)
      print("like success:")
      
      Vibration.medium.vibrate()
      sender.setState(true)
    } unlikeStateCallback: { targetPostLikesRef, currentUID in
      // 미리 좋아요 표시 제거 (실제 unlike 된 후 실행하면 딜레이 느껴짐)
      sender.setState(false)
      targetPostLikesRef.child(currentUID).removeValue { error, ref in
        if let error = error {
          print("unlike failed:", error.localizedDescription)
          // 롤백: unlike 하는 경우는 이전 상태가 liked 인 경우밖에 없음
          sender.setState(true)
          return
        }
        print("unlike success:")
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
      self.imgAlbumart.kf.setImage(with: url) { result in
        self.lottieView.isHidden = true
      }
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

extension PostViewController: BannerViewDelegate {
  func bannerViewDidReceiveAd(_ bannerView: BannerView) {
    if bottomConstantRaiseOnce {
      cnstScrollViewBottom.constant += bannerView.adSize.size.height
      bottomConstantRaiseOnce = false
    }
  }
}

extension PostViewController: FullScreenContentDelegate {
  /// 전면 광고 준비
  func prepareFullScreenAd() {
    guard AdManager.isReallyShowAd else {
      return
    }
    
    let request = Request()
    request.keywords = [
      "음악",
      "악기",
      "Music",
      "instrument",
      "score",
      "sheet",
      "piano",
      "roll",
      "노래",
      "song",
      "classical",
      "클래식",
      "유아",
      "청소년",
      "학습",
      "공부",
      "musical",
      "연주",
      "performance",
      "칼림바",
      "kalimba",
      "커뮤니티",
      "온라인",
      "트럼펫",
      "학원",
      "academy"
    ]
    
    InterstitialAd.load(with: AdInfo.shared.paperFullScreen,
                        request: request,
                        completionHandler: { [self] ad, error in
      if let error = error {
        print("Failed to load interstitial ad with error: \(error.localizedDescription)")
        return
      }
      
      interstitial = ad
      interstitial?.fullScreenContentDelegate = self
    })
  }
}
