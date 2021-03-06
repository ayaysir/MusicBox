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

class UserCommunityViewController: UIViewController {
    
    private var bannerView: GADBannerView!
    var shouldShowFooter: Bool = false {
        didSet {
            collectionView?.collectionViewLayout.invalidateLayout()
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var btnAddPost: UIButton!
    @IBOutlet weak var buttonBottomConstraint: NSLayoutConstraint!
    
    let sectionInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    var posts: [Post] = []
    
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
        
        // ====== 광고 ====== //
        TrackingTransparencyPermissionRequest()
        if AdManager.productMode {
            bannerView = setupBannerAds(self, adUnitID: AdInfo.shared.archiveMain)
            bannerView.delegate = self
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        guard Reachability.isConnectedToNetwork() else {
            let notConnectedVC = mainStoryboard.instantiateViewController(withIdentifier: "NotConnectedViewController") as? NotConnectedViewController
            notConnectedVC?.vcName = "UserCommunityViewController"
            
            self.navigationController?.setViewControllers([notConnectedVC!], animated: false)
            return
        }
        
        guard Auth.auth().currentUser != nil else {
            let needLoginVC = mainStoryboard.instantiateViewController(withIdentifier: "YouNeedLoginViewController")
            self.navigationController?.setViewControllers([needLoginVC], animated: false)
            
            return
        }
        
        getPostList()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PostPageSegue" {
            guard let vc = segue.destination as? PostPageViewController,
                  let indexPath = sender as? IndexPath else {
                return
            }
            vc.posts = posts
            vc.currentIndex = indexPath.row
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
        
        performSegue(withIdentifier: "PostPageSegue", sender: indexPath)
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
        buttonBottomConstraint.constant += bannerView.adSize.size.height
        shouldShowFooter = true
    }
}

class PostCell: UICollectionViewCell {
    
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
        imgAlbumart.image = UIImage(named: "loading-icon-static")
    }
    
    func reset() {
        imgAlbumart.image = nil
        lblTitle.text = nil
        imgUserProfile.image = nil
        lblUserNickname.text = nil
        lblLikeCount.text = nil
    }
    
    func update(post: Post) {
        
        self.post = post
        
        imgAlbumart.layer.cornerRadius = 10
        imgAlbumart.clipsToBounds = true
        print(imgAlbumart.bounds)
        
        imgUserProfile.layer.cornerRadius = imgUserProfile.bounds.size.width * 0.5
        imgUserProfile.clipsToBounds = true
        storageRef.child("images/users/\(post.writerUID)/thumb_\(post.writerUID).jpg").downloadURL { url, error in
            if let error = error {
                print("get profile thumb failed:", error.localizedDescription)
                return
            }
            
            if let url = url {
                self.userThumbSubscriber = ImageManager.shared.imagePublisher(for: url, errorImage: UIImage(systemName: "xmark.octagon")).assign(to: \.imgUserProfile.image, on: self)
            }
        }
        
        
        lblUserNickname.text = "noname"
        ref.child("users").child(post.writerUID).child("nickname").getData { error, snapshot in
            if let error = error {
                print("get nickname failed:", error.localizedDescription)
                return
            }
            
            if snapshot.exists() {
                self.lblUserNickname.text = snapshot.value as? String
            }
        }
        
        
        lblTitle.text = post.postTitle
        
        lblLikeCount.text = "\(post.likes.count)"
        
        if let currentUID = getCurrentUserUID() {
            let identifier = post.likes[currentUID] != nil ? "heart.fill" : "heart"
            imgHeart.image = UIImage(systemName: identifier)
        }
    }
    
    func setImage(to url: URL) {
        subscriber = ImageManager.shared.imagePublisher(for: url, errorImage: UIImage(systemName: "heart.fill"))
                    .assign(to: \.imgAlbumart.image, on: self)
    }
}

class PostCellContentView: UIView {
    
}

