//
//  TextureCollectionViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/10.
//

import UIKit
import GoogleMobileAds

private let reuseIdentifier = "PaperCell"

class TextureCollectionViewController: UICollectionViewController {
  
  private var bannerView: BannerView!
  
  enum Category {
    case paper, background
  }
  
  var category: Category = .paper
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // ====== 광고 ====== //
    TrackingTransparencyPermissionRequest()
    if AdManager.isReallyShowAd {
      bannerView = setupBannerAds(self, adUnitID: AdInfo.shared.setting)
    }
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    
    switch category {
    case .paper:
      self.title = "Select a Paper Pattern".localized
    case .background:
      self.title = "Select a Background Pattern".localized
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    
    switch category {
    case .paper:
      let storedPatternName = configStore.string(forKey: .cfgPaperTextureName) ?? ""
      let patternIndex = PAPER_TEXTURE_LIST.firstIndex(of: storedPatternName) ?? PAPER_TEXTURE_LIST.count - 1
      
      self.collectionView.selectItem(at: IndexPath(row: patternIndex, section: 0), animated: false, scrollPosition: .left)
    case .background:
      let storedPatternName = configStore.string(forKey: .cfgBackgroundTextureName) ?? ""
      let patternIndex = BG_TEXTURE_LIST.firstIndex(of: storedPatternName) ?? 1
      
      self.collectionView.selectItem(at: IndexPath(row: patternIndex, section: 0), animated: false, scrollPosition: .left)
    }
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    bannerView?.fitInView(self)
  }
  
  // MARK: - UICollectionViewDataSource
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    // #warning Incomplete implementation, return the number of sections
    return 1
  }
  
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    // #warning Incomplete implementation, return the number of items
    switch category {
    case .paper:
      return PAPER_TEXTURE_LIST.count
    case .background:
      return BG_TEXTURE_LIST.count
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! TextureCell
    
    switch category {
    case .paper:
      cell.update(assetName: PAPER_TEXTURE_LIST[indexPath.row])
    case .background:
      cell.update(assetName: BG_TEXTURE_LIST[indexPath.row])
    }
    
    return cell
  }
  
  // MARK: UICollectionViewDelegate
  
  override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let cell = collectionView.cellForItem(at: indexPath) else {
      return
    }
    
    // save to UserDefaults
    switch category {
    case .paper:
      configStore.set(PAPER_TEXTURE_LIST[indexPath.row], forKey: .cfgPaperTextureName)
    case .background:
      configStore.set(BG_TEXTURE_LIST[indexPath.row], forKey: .cfgBackgroundTextureName)
    }
    
    cell.isSelected = true
  }
  
  override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    guard let cell = collectionView.cellForItem(at: indexPath) else {
      return
    }
    
    cell.isSelected = false
  }
}

extension TextureCollectionViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let width = collectionView.frame.width
    let itemsPerRow: CGFloat = 3
    let widthPadding = 5 * (itemsPerRow + 1)
    let cellWidth = (width - widthPadding) / itemsPerRow
    
    return CGSize(width: cellWidth, height: cellWidth)
    
  }
}

class TextureCell: UICollectionViewCell {
  
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
