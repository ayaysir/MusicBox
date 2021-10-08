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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

extension UserCommunityViewController {
    
    @objc func getPost(sender: UIButton) {
        print(sender.tag)
        var ref = Database.database().reference(withPath: "community/UVID1")
        ref.observe(.value) { (snapshot: DataSnapshot) in
            print(snapshot.value as Any)
        }
    }
}

extension UserCommunityViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        32
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: "PostCell", for: indexPath) as? PostCell else {
            return UICollectionViewCell()
        }
        cell.update(id: indexPath.row)
        cell.btnEnterPost.tag = indexPath.row
        cell.btnEnterPost.addTarget(self, action: #selector(getPost), for: .touchUpInside)
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        print(#function)
    }
    
    func update(id: Int) {
        
        imgAlbumart.layer.cornerRadius = 10
        imgAlbumart.clipsToBounds = true
        
        imgUserProfile.layer.cornerRadius = imgUserProfile.bounds.size.width * 0.5
        imgUserProfile.clipsToBounds = true
        

        
        lblUserNickname.text = "\(id)"
    }
    
    

}

class PostCellContentView: UIView {
    
}
