//
//  MainTabBarViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/04.
//

import UIKit
import AVFoundation

class MainTabBarController: UITabBarController {
    
    var fileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        TrackingTransparencyPermissionRequest()
        
        // 무음모드에서 소리가 나게 하기
        do {
            let playInSilentMode = UserDefaults.standard.bool(forKey: .cfgPlayInSilentMode)
            if playInSilentMode {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            }
        } catch {
            print("MainTabBarController:", error)
        }
    }
}
