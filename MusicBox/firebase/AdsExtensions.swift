//
//  AdsExtensions.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/21.
//

import UIKit
import GoogleMobileAds

// 광고 목록
/**
 setting
 - TextureCollectionViewController
 - SettingTableViewController
 - AudioMIDISettingTableViewController
 
 archiveMain
 - MemberProfileViewController
 - UserCommunityViewController
 - UploadFormViewController
 - PostViewController
 - SignUpTableViewController
 - YouNeedLoginViewController
 
 fileBrowser
 - FileCollectionViewController
 - CreateNewPaperTableViewController
 - PaperInfoTableViewController
 */

// ============ 애드몹 셋업 ============

/**
 하단 광고 넣는 방법
 1. **import GoogleMobileAds**
 
 2. VC의 멤버 변수 **private var bannerView: GADBannerView!**
    **viewDidLoad()**에 **
            bannerView = setupBannerAds(self)
            bannerView.delegate = self
    ** 추가
 
 3.  **GADBannerViewDelegate** 를 상속받은 후 **func bannerViewDidReceiveAd(...)**에서 로딩 후 작업(뷰 높이 변경 등) 진행
 
 예)
 // 광고 배너로 height 올리는거 한 번만 실행
 var bottomConstantRaiseOnce = true
 if bottomConstantRaiseOnce {
    buttonBottomConstraint.constant += bannerView.adSize.size.height
    bottomConstantRaiseOnce = false
 }

 
 
 4. **UICollectionViewController**인 경우
    ReusableView (약 50px)를 푸터 영역에 위치시킨 뒤 identifier 지정
    VC의 멤버 변수로
    **
 var shouldShowFooter: Bool = false {
     didSet {
         collectionView?.collectionViewLayout.invalidateLayout()
     }
 }
    **
    를 추가하고 **UICollectionViewDelegateFlowLayout**를 상속받은 뒤
     
    아래와 같은 함수 작성
     override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
         switch kind {
         case UICollectionView.elementKindSectionFooter:
             let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "spaceForBanner", for: indexPath)
             return footerView
         default:
             assert(false)
         }
     }

     func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
         if shouldShowFooter {
             return CGSize(width: collectionView.bounds.width, height: bannerView.adSize.size.height)
         }
         else {
             return CGSize(width: collectionView.bounds.width, height: 0)
         }
     }
 
    receivedAd에서 shouldShowFootter true
    
 */

func setupBannerAds( _ viewController: UIViewController, adUnitID: String = "ca-app-pub-3940256099942544/2934735716") -> GADBannerView {
    // let adSize = GADAdSizeFromCGSize(CGSize(width: viewController.view.frame.width, height: 50))
    print(#function, viewController.view.frame.width)
    let adSize = GADAdSizeFromCGSize(CGSize(width: viewController.view.frame.width, height: 50))
    let bannerView = GADBannerView(adSize: adSize)
    
    bannerView.translatesAutoresizingMaskIntoConstraints = false
    viewController.view.addSubview(bannerView)
    viewController.view.addConstraints( [NSLayoutConstraint(item: bannerView, attribute: .bottom, relatedBy: .equal, toItem: viewController.view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0), NSLayoutConstraint(item: bannerView, attribute: .centerX, relatedBy: .equal, toItem: viewController.view, attribute: .centerX, multiplier: 1, constant: 0) ])
    
    
    bannerView.adUnitID = adUnitID
    bannerView.rootViewController = viewController
    
    let request = GADRequest()
    bannerView.load(request)
    
    return bannerView
}
