//
//  YouNeedLoginViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/08.
//

import UIKit
import Firebase
import GoogleMobileAds

class YouNeedLoginViewController: UIViewController {
    
    private var bannerView: GADBannerView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // ====== 광고 ====== //
        if AdManager.productMode {
            bannerView = setupBannerAds(self, adUnitID: AdInfo.shared.archiveMain)
            bannerView.delegate = self
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if Auth.auth().currentUser != nil {
            let postListVC = mainStoryboard.instantiateViewController(withIdentifier: "UserCommunityViewController")
            self.navigationController?.setViewControllers([postListVC], animated: false)
        }
    }
    
    @IBAction func btnActGoToLoginPage(_ sender: Any) {
        self.tabBarController?.selectedIndex = 2
    }
}

extension YouNeedLoginViewController: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        
    }
}
