//
//  UserCommunityControllView.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/07.
//

import UIKit
import Firebase

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
        
        
        getPostList()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

extension UserCommunityViewController {
    
    func getPostList() {
        let ref = Database.database().reference(withPath: "community")
        ref.observe(.value) { (snapshot: DataSnapshot) in
            let snapshotDict = snapshot.value as! Dictionary<String, Any>
            let array = snapshotDict.map { (key: String, value: Any) in
                return value as! Dictionary<String, Any>
            }
            
            do {
                self.posts = try array.map { (dict: Dictionary<String, Any>) -> Post in
                    print(dict)
                    let post = try Post(dictionary: dict)
                    return post
                }
                self.collectionView.reloadData()
            } catch {
                
            }
            
        }
    }
    
    @objc func getPost(sender: UIButton) {
        print(sender.tag)
    }
    
    private func getPostThumbImage(_ cell: PostCell, indexPath: IndexPath, postIdStr: String) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let sampleImageRef = storageRef.child("PostThumbnail/\(postIdStr)/\(postIdStr).jpg")
        
        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        sampleImageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                // Uh-oh, an error occurred!
                print(#function, "download error", error.localizedDescription)
                cell.setAlbumartImage(image: UIImage(named: "sample")!)
            } else {
                // Data for "images/island.jpg" is returned
                guard let image = UIImage(data: data!) else {
                    return
                }
                cell.setAlbumartImage(image: image)
            }
        }
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
        cell.btnEnterPost.tag = indexPath.row
        cell.btnEnterPost.addTarget(self, action: #selector(getPost), for: .touchUpInside)
        cell.tag = indexPath.row
        getPostThumbImage(cell, indexPath: indexPath, postIdStr: targetPost.postId.uuidString)
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
    
    // 사이즈 결정
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // 160 : 280 = 1.75
        let width = collectionView.frame.width
        
        let itemsPerRow: CGFloat = 2
        let widthPadding = sectionInsets.left * (itemsPerRow + 1)
        
        let cellWidth = (width - widthPadding) / itemsPerRow
        let cellHeight = cellWidth * 1.525
        
        print("cellSize:", cellWidth, cellHeight)
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
    
    @IBOutlet weak var btnEnterPost: UIButton!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imgAlbumart?.image = nil
    }
    
    func reset() {
        imgAlbumart.image = nil
        lblTitle.text = ""
        imgUserProfile.image = nil
        lblUserNickname.text = nil
    }
    
    func update(post: Post) {
        
        imgAlbumart.layer.cornerRadius = 10
        imgAlbumart.clipsToBounds = true
        print(imgAlbumart.bounds)
        
        imgUserProfile.layer.cornerRadius = imgUserProfile.bounds.size.width * 0.5
        imgUserProfile.clipsToBounds = true
        
        lblUserNickname.text = "\(post.writerUID)"
        lblTitle.text = post.postTitle
    }
    
    func setAlbumartImage(image: UIImage) {
        DispatchQueue.main.async {
            self.imgAlbumart.image = image
        }
    }
    
    

}

class PostCellContentView: UIView {
    
}
