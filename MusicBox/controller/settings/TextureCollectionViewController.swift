//
//  PaperTextureCollectionViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/10.
//

import UIKit

private let reuseIdentifier = "PaperCell"

class TextureCollectionViewController: UICollectionViewController {
    
    enum Category {
        case paper, background
    }
    
    var category: Category = .paper

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
//        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        switch category {
        case .paper:
            self.title = "Select a Paper Pattern"
        case .background:
            self.title = "Select a Background Pattern"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let storedPatternName = UserDefaults.standard.string(forKey: .cfgPaperTextureName) ?? ""
        let patternIndex = PAPER_TEXTURE_LIST.firstIndex(of: storedPatternName) ?? PAPER_TEXTURE_LIST.count - 1
        
        self.collectionView.selectItem(at: IndexPath(row: patternIndex, section: 0), animated: false, scrollPosition: .left)
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return PAPER_TEXTURE_LIST.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PaperTextureCell
    
        // Configure the cell
        cell.update(assetName: PAPER_TEXTURE_LIST[indexPath.row])

        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }
        
        // save to UserDefaults
        UserDefaults.standard.set(PAPER_TEXTURE_LIST[indexPath.row], forKey: .cfgPaperTextureName)

        cell.isSelected = true
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }

        cell.isSelected = false
    }

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

class PaperTextureCell: UICollectionViewCell {
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                layer.borderWidth = 5
                layer.borderColor = UIColor.red.cgColor
            } else {
                layer.borderWidth = 0
            }
        }
    }
    
    @IBOutlet weak var imgViewPaperTexture: UIImageView!
    
    func update(assetName: String) {
        if let patternImage = UIImage(named: assetName) {
            backgroundColor = UIColor(patternImage: patternImage)
        }
    }
}
