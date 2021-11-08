//
//  UserCommunityControllView.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/07.
//

import UIKit
import Firebase
import Combine

class UserCommunityViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let sectionInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    var posts: [Post] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
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
        let ref = Database.database().reference(withPath: "community")
        ref.observe(.value) { (snapshot: DataSnapshot) in
            
            guard let snapshotDict = snapshot.value as? Dictionary<String, Any> else {
                print("글이 없습니다.")
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
                self.collectionView.reloadData()
            } catch {
                print("getPost Error:", error.localizedDescription)
            }
            
        }
    }
    
    @objc func getPost(sender: UIButton) {
        print(sender.tag)
    }
    
//    private func getPostThumbImage(_ cell: PostCell, indexPath: IndexPath, postIdStr: String) {
//
//        let refPath = "PostThumbnail/\(postIdStr)/\(postIdStr).jpg"
//        getFileURL(childRefStr: refPath) { url in
//            guard let url = url else {
//                return
//            }
//
////            cell.imgAlbumart.kf.setImage(with: url, placeholder: UIImage(named: "sample"), options: [.cacheOriginalImage], completionHandler: nil)
//
//        }
//    }
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
        
//        getPostThumbImage(cell, indexPath: indexPath, postIdStr: targetPost.postId.uuidString)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CollectionViewHeader", for: indexPath)
            return headerView
        default:
            return UICollectionReusableView()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: "PostPageSegue", sender: indexPath)
    }
    
    // 사이즈 결정
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // 160 : 280 = 1.75
        let width = collectionView.frame.width
        
        let itemsPerRow: CGFloat = 2
        let widthPadding = sectionInsets.left * (itemsPerRow + 1)
        
        let cellWidth = (width - widthPadding) / itemsPerRow
        let cellHeight = cellWidth * 1.525
        
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
        imgAlbumart.image = nil
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
