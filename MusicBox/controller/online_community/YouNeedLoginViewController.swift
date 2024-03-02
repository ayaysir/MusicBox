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
        TrackingTransparencyPermissionRequest()
        if AdManager.isReallyShowAd {
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        bannerView?.fitInView(self)
    }
    
    @IBAction func btnActGoToLoginPage(_ sender: Any) {
        // self.tabBarController?.selectedIndex = 2
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
}

extension YouNeedLoginViewController: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        
    }
}
