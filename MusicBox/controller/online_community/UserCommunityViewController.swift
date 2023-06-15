//
//  UserCommunityControllView.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/07.
//

import UIKit
import Firebase
import Combine
import SwiftSpinner
import GoogleMobileAds
import SpeechBubbleView
import Lottie

class UserCommunityViewController: UIViewController {
    
    private var bannerView: GADBannerView!
    var shouldShowFooter: Bool = false {
        didSet {
            collectionView?.collectionViewLayout.invalidateLayout()
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var btnAddPost: UIButton!
    @IBOutlet weak var barBtnUserInfo: UIBarButtonItem!
    @IBOutlet weak var buttonBottomConstraint: NSLayoutConstraint!
    
    let sectionInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    var posts: [Post] = []
    
    private var subscriber: AnyCancellable?
    private var userThumbSubscriber: AnyCancellable?
    private let storageRef = Storage.storage().reference()
    
    // 광고 배너로 height 올리는거 한 번만 실행
    var bottomConstantRaiseOnce = true
    
    let KEY_OnlyOnce_SpeechBubbleForNoticeUserInfoFeature = "OnlyOnce_SpeechBubbleForNoticeUserInfoFeature"
    let TAG_overlay = 140031
    let TAG_bubble = 140032
    let TAG_label = 140033
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        btnAddPost.setTitle("", for: .normal)
        // 그림자
        let shadowColor: UIColor = {
            if let basicColor = UIColor(named: "color-button-shadow") {
                return basicColor
            } else {
                return UIColor.label
            }
        }()
        
        btnAddPost.layer.shadowColor = shadowColor.cgColor
        btnAddPost.layer.shadowOpacity = 0.5
        btnAddPost.layer.shadowOffset = CGSize(width: 2, height: 2)
        btnAddPost.layer.shadowRadius = 6
        btnAddPost.layer.masksToBounds = false
        
        // 업데이트 알림 말풍선
        popupSpeechBubbleForNoticeUserInfoFeature()
        
        // ====== 광고 ====== //
        TrackingTransparencyPermissionRequest()
        if AdManager.productMode {
            bannerView = setupBannerAds(self, adUnitID: AdInfo.shared.archiveMain)
            bannerView.delegate = self
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // navigationController?.setNavigationBarHidden(true, animated: animated)
        
        barBtnUserInfo.customView = nil
        barBtnUserInfo.image = nil
        
        guard Reachability.isConnectedToNetwork() else {
            let notConnectedVC = mainStoryboard.instantiateViewController(withIdentifier: "NotConnectedViewController") as? NotConnectedViewController
            notConnectedVC?.vcName = "UserCommunityViewController"
            
            self.navigationController?.setViewControllers([notConnectedVC!], animated: false)
            return
        }
        
        // guard Auth.auth().currentUser != nil else {
        //     let needLoginVC = mainStoryboard.instantiateViewController(withIdentifier: "YouNeedLoginViewController")
        //     self.navigationController?.setViewControllers([needLoginVC], animated: false)
        //
        //     return
        // }
        
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { authResult, error in
                if let error = error {
                    print("signInAnonymously error:", error)
                }
                
                print(authResult!)
                self.getPostList()
            }
        } else {
            getPostList()
        }
        
        // 프로필 사진 로딩
        if let user = getCurrentUser(), !user.isAnonymous {
            storageRef.child("images/users/\(user.uid)/thumb_\(user.uid).jpg").downloadURL { url, error in
                if let error = error {
                    print("get profile thumb failed:", error.localizedDescription)
                    self.assingImageToBarBtnUserInfo(image: UIImage(named: "sample")!)
                    return
                }
                
                if let url = url {
                    self.userThumbSubscriber = ImageManager.shared.imagePublisher(for: url, errorImage: UIImage(systemName: "person.circle.fill")).sink(receiveValue: { output in
                        self.assingImageToBarBtnUserInfo(image: output!)
                    })
                }
            }
        } else {
            barBtnUserInfo.image = UIImage(systemName: "person.circle.fill")
            // btnAddPost.isHidden = true
        }
    }
    
    @objc func cvTapped() {
        goToLoginVC()
    }
    
    private func assingImageToBarBtnUserInfo(image: UIImage) {
        let size = self.barBtnUserInfo.image?.size.scale(1.5) ?? CGSize(width: 25, height: 25)
        let scaledImage = try? resizeImage(image: image, maxSize: Int(size.width))
        let imageView = UIImageView(image: scaledImage)
        imageView.frame = CGRect(origin: .zero, size: size)
        imageView.layer.cornerRadius = imageView.frame.size.width / 2
        imageView.clipsToBounds = true
        self.barBtnUserInfo.customView = imageView
        
        let cvTap = UITapGestureRecognizer(target: self, action: #selector(self.cvTapped))
        self.barBtnUserInfo.customView?.addGestureRecognizer(cvTap)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        if !configStore.bool(forKey: KEY_OnlyOnce_SpeechBubbleForNoticeUserInfoFeature) {
            removeOvelays()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView?.collectionViewLayout.invalidateLayout()
        
        bannerView?.fitInView(self)
    }
    
    @IBAction func barBtnActUserInfo(_ sender: Any) {
        goToLoginVC()
    }
    
    @IBAction func btnActAddPost(_ sender: UIButton) {
        if let user = getCurrentUser(),
           !user.isAnonymous {
            performSegue(withIdentifier: "UploadFormSegue", sender: nil)
        } else {
            goToLoginVC()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "PostPageSegue":
            guard let vc = segue.destination as? PostPageViewController,
                  let indexPath = sender as? IndexPath else {
                return
            }
            vc.posts = posts
            vc.currentIndex = indexPath.row
        case "PostPageSegue_withoutPageView":
            guard let postVC = segue.destination as? PostViewController,
                  let indexPath = sender as? IndexPath else {
                print("Error occured PostPageSegue_withoutPageView segue.")
                return
            }
            postVC.post = posts[indexPath.row]
        case "UploadFormSegue":
            guard let uploadVC = segue.destination as? UploadFormViewController else {
                print("Error occured UploadFormSegue.")
                return
            }
            uploadVC.delegate = self
        default:
            break
        }
    }
    
    private func goToLoginVC() {
        if let user = getCurrentUser(), !user.isAnonymous {
            performSegue(withIdentifier: "MemberVC_Segue", sender: nil)
        } else {
            performSegue(withIdentifier: "LoginVC_Segue", sender: nil)
        }
        
    }
}

extension UserCommunityViewController {
    
    func getPostList() {
        SwiftSpinner.show("Loading post list...".localized)
        let ref = Database.database().reference(withPath: "community")
        ref.observe(.value) { (snapshot: DataSnapshot) in
            
            guard let snapshotDict = snapshot.value as? Dictionary<String, Any> else {
                SwiftSpinner.show(duration: 2, title: "There are no articles.".localized, animated: false, completion: nil)
                return
            }
            let array = snapshotDict.map { (key: String, value: Any) in
                return value as! Dictionary<String, Any>
            }
            
            do {
                self.posts = []
                self.posts = try array.map { (dict: Dictionary<String, Any>) -> Post in
                    let post = try Post(dictionary: dict)
                    return post
                }
                self.posts.sort { p1, p2 in
                    p1.uploadDate > p2.uploadDate
                }
                
                SwiftSpinner.hide {
                    self.collectionView.reloadData()
                }
                
            } catch {
                print("getPost Error:", error.localizedDescription)
                SwiftSpinner.show(duration: 2, title: "getPost Error: \(error.localizedDescription)", animated: false, completion: nil)
            }
        }
    }
    
    @objc func getPost(sender: UIButton) {
        
    }
}

extension UserCommunityViewController {
    func popupSpeechBubbleForNoticeUserInfoFeature() {
        
        // 한 번 봤으면 다시 표시하지 않음: 테스트하려면 아래 if문 주석처리
        if configStore.bool(forKey: KEY_OnlyOnce_SpeechBubbleForNoticeUserInfoFeature) { return }
        
        // overlay
        let overlayFrame = CGRect(x: view.frame.minX,
                                  y: view.frame.minY + topBarHeight,
                                  width: view.frame.width,
                                  height: view.frame.height - topBarHeight)
        let overlay = UIView(frame: overlayFrame)
        overlay.backgroundColor = .black
        overlay.layer.opacity = 0.5
        
        let overlayTap = UITapGestureRecognizer(target: self, action: #selector(didTouchedOverlay))
        overlay.addGestureRecognizer(overlayTap)
        
        let width: CGFloat = 275
        let height: CGFloat = 150
        let x = self.view.frame.width - CGFloat(width + 5)
        let y = self.topBarHeight
        
        let speechBubble = SpeechBubbleView(frame: CGRect(x: x, y: y, width: width, height: height))
        speechBubble.backgroundColor = .clear
        speechBubble.speechBubbleColor = .yellow
        speechBubble.lineColor = .systemGray3
        speechBubble.lineWidth = 3
        speechBubble.cornerRadius = 3

        speechBubble.triangleType = .left
        speechBubble.triangleSpacing = 10
        speechBubble.triangleWidth = 10
        speechBubble.triangleHeight = 10
        
        let transform = CGAffineTransform(rotationAngle: 3.14)
        speechBubble.transform = transform
        
        // speech bubble - text
        // 한글: '나의 정보' 메뉴가 아카이브와 통합되었습니다.\n앞으로 로그인 및 회원정보 조회는 오른쪽 상단의 이 버튼을 누르면 됩니다.
        let text = "The My Info menu has been integrated with the Archive.\nFrom now on, you can tap this button in the upper right corner to sign in and view my user information.".localized
        let label = UILabel(frame: CGRect(x: x + 10, y: y + 10, width: width - 20, height: height - 10))
        label.textColor = .black
        label.numberOfLines = 0
        label.text = text
        
        if let languageCode = Locale.current.languageCode, languageCode == "ko" {
            label.lineBreakMode = .byCharWrapping
        } else {
            label.lineBreakMode = .byWordWrapping
        }
        
        overlay.tag = TAG_overlay
        speechBubble.tag = TAG_bubble
        label.tag = TAG_label
        self.view.addSubview(overlay)
        self.view.addSubview(speechBubble)
        self.view.addSubview(label)
        
    }
    
    @objc func didTouchedOverlay() {
        removeOvelays()
    }
    
    func removeOvelays() {
        let targetSubviewTags = [TAG_overlay, TAG_bubble, TAG_label]
        self.view.subviews.forEach { view in
            if targetSubviewTags.contains(view.tag) {
                view.removeFromSuperview()
            }
        }
        configStore.set(true, forKey: KEY_OnlyOnce_SpeechBubbleForNoticeUserInfoFeature)
    }
}

extension UserCommunityViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: "PostCell", for: indexPath) as? PostCell else {
            return UICollectionViewCell()
        }

        let targetPost = posts[indexPath.row]
        cell.update(post: targetPost)
        cell.tag = indexPath.row
        
        let postUUIDString = targetPost.postId.uuidString
        let refPath = "PostThumbnail/\(postUUIDString)/\(postUUIDString).jpg"
        getFileURL(childRefStr: refPath) { url in
            guard let url = url else {
                return
            }
            
            cell.setImage(to: url)
        } failedHandler: { error in
            DispatchQueue.main.async {
                cell.imgAlbumart.image = UIImage(named: "sample")
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CollectionViewHeader", for: indexPath)
            return headerView
        case UICollectionView.elementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "spaceForBanner", for: indexPath)
            return footerView
        default:
            break
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        SwiftSpinner.show("Loading the post...".localized)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [unowned self] in
            performSegue(withIdentifier: "PostPageSegue_withoutPageView", sender: indexPath)
        }
        
    }
    
    // 사이즈 결정
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // 160 : 280 = 1.75
        let width = collectionView.frame.width
        
        var itemsPerRow: CGFloat {
            if view.bounds.width <= 500 {
                return 2
            } else {
                return floor(view.bounds.width / 200)
            }
        }
        
        let widthPadding = sectionInsets.left * (itemsPerRow + 1)
        
        let cellWidth = (width - widthPadding) / itemsPerRow
        let cellHeight = cellWidth * 1.5
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }

    // banner
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if shouldShowFooter {
            return CGSize(width: collectionView.bounds.width, height: bannerView.adSize.size.height)
        }
        else {
            return CGSize(width: collectionView.bounds.width, height: 0)
        }
    }
}

extension UserCommunityViewController: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        if bottomConstantRaiseOnce {
            buttonBottomConstraint.constant += bannerView.adSize.size.height
            shouldShowFooter = true
            bottomConstantRaiseOnce = false
        }
        
    }
}

extension UserCommunityViewController: UploadFormVCDelegate {
    func didNotLogined(_ controller: UploadFormViewController) {
        goToLoginVC()
    }
}

class PostCell: UICollectionViewCell {
    
    lazy var lottieView: LottieAnimationView = {
        let width = 200
        let animationView = LottieAnimationView(name: "lf30_editor_s2qiyrio")
        animationView.frame = CGRect(x: 0, y: 0,
                                     width: width, height: width)

        animationView.contentMode = .scaleAspectFill
        animationView.stop()
        animationView.isHidden = true
        animationView.loopMode = .loop
        
        return animationView
    }()
    
    @IBOutlet weak var imgAlbumart: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgUserProfile: UIImageView!
    @IBOutlet weak var lblUserNickname: UILabel!
    
    @IBOutlet weak var imgHeart: UIImageView!
    @IBOutlet weak var lblLikeCount: UILabel!
    
    private var subscriber: AnyCancellable?
    private var userThumbSubscriber: AnyCancellable?
    
    let ref = Database.database().reference()
    let storageRef = Storage.storage().reference()
    
    var post: Post!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        subscriber?.cancel()
        // imgAlbumart.image = UIImage(named: "loading-icon-static")
    }
    
    func reset() {
        imgAlbumart.image = nil
        lblTitle.text = nil
        imgUserProfile.image = nil
        lblUserNickname.text = nil
        lblLikeCount.text = nil
    }
    
    func update(post: Post) {
        
        imgAlbumart.image = nil
        lottieView.center = imgAlbumart.center
        lottieView.isHidden = false
        lottieView.play()
        imgAlbumart.addSubview(lottieView)
        
        self.post = post
        
        imgAlbumart.layer.cornerRadius = 10
        imgAlbumart.clipsToBounds = true
        print(imgAlbumart.bounds)
        
        imgUserProfile.layer.cornerRadius = imgUserProfile.bounds.size.width * 0.5
        imgUserProfile.clipsToBounds = true
        storageRef.child("images/users/\(post.writerUID)/thumb_\(post.writerUID).jpg").downloadURL { url, error in
            if let error = error {
                print("get profile thumb failed:", error.localizedDescription)
                self.imgUserProfile.image = UIImage(named: "sample")
                return
            }
            
            if let url = url {
                self.userThumbSubscriber = ImageManager.shared.imagePublisher(for: url, errorImage: UIImage(systemName: "xmark.octagon")).assign(to: \.imgUserProfile.image, on: self)
            }
        }
        
        
        lblUserNickname.text = "noname"
        ref.child("users").child(post.writerUID).child("nickname").observe(.value) { snapshot in
            if snapshot.exists() {
                self.lblUserNickname.text = snapshot.value as? String
            }
        }
        // ref.child("users").child(post.writerUID).child("nickname").getData { error, snapshot in
        //     if let error = error {
        //         print("get nickname failed:", error)
        //         return
        //     }
        //
        //     if snapshot.exists() {
        //         self.lblUserNickname.text = snapshot.value as? String
        //     }
        // }
        //
        
        lblTitle.text = post.postTitle
        
        lblLikeCount.text = "\(post.likes.count)"
        
        if let currentUID = getCurrentUserUID() {
            let identifier = post.likes[currentUID] != nil ? "heart.fill" : "heart"
            imgHeart.image = UIImage(systemName: identifier)
        }
    }
    
    func setImage(to url: URL) {
        subscriber = ImageManager.shared
            .imagePublisher(for: url, errorImage: UIImage(systemName: "heart.fill"), handler: {
                DispatchQueue.main.async { [unowned self] in
                    lottieView.stop()
                    lottieView.isHidden = true
                }
            })
            .assign(to: \.imgAlbumart.image, on: self)
    }
}
