//
//  MainTabBarViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/04.
//

import UIKit
import AVFoundation
import StoreKit

class MainTabBarController: UITabBarController {
    
    var fileURL: URL?
    
    var products: [SKProduct] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 14, *) {
            self.tabBar.items![3].image = UIImage(systemName: "gearshape.fill")
        }
        
        TrackingTransparencyPermissionRequest()
        
        // 무음모드에서 소리가 나게 하기
        do {
            let playInSilentMode = UserDefaults.standard.bool(forKey: .cfgPlayInSilentMode)
            if playInSilentMode {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            }
            
        } catch {
            
        }
        
        iapTest()
    }
    
}

extension MainTabBarController {
    
    private func iapTest() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlePurchaseNotification), name: .IAPHelperPurchaseNotification, object: nil)
        
        MusicBoxProducts.store.requestProducts { [weak self] success, products in
            guard let self = self else { return }
            if success {
                self.products = products!
                print("iap: ", products as Any)
            } else {
                print("iap load failed")
            }
        }
    }
    
    @objc func handlePurchaseNotification(_ notification: Notification) {
        guard
            let productID = notification.object as? String,
            let index = products.firstIndex(where: { product -> Bool in
                product.productIdentifier == productID
            })
        else { return }
        
        print("iap index:", index)
    }
}
