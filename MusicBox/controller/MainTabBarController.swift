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

        // Do any additional setup after loading the view.
        
        // 무음모드에서 소리가 나게 하기
        do {
            let playInSilentMode = UserDefaults.standard.bool(forKey: .cfgPlayInSilentMode)
            if playInSilentMode {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            }
            
        } catch {
            
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
