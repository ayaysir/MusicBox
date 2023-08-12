//
//  AppDelegate.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/09.
//

import UIKit
import Firebase
import GoogleMobileAds
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard url.isFileURL else {
            print(#function, to: &logger)
            return false
        }
        
        print(#function, url, to: &logger)
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Check app launched first or updated.
        checkAppUpgrade {
            OnlyOnceAfterInstall()
        } updated: {
            print("App Status: updated")
            
            // ONCE: 앱을 업데이트시 최초 한 번만 .cfgPlayPitchWhenInputNotes 를 true로
            let ONCE_isForcedChangePlayPitch = configStore.bool(forKey: "ONCE_isForcedChangePlayPitch")
            if !ONCE_isForcedChangePlayPitch {
                configStore.set(true, forKey: .cfgPlayPitchWhenInputNotes)
                configStore.set(true, forKey: "ONCE_isForcedChangePlayPitch")
            }
        } nothingChanged: {
            print("App Status: nothing")
        }

        // Override point for customization after application launch.
        
        // Initialize the Google Mobile Ads SDK.
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = false
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        // 앱을 출시하기 전에 이러한 테스트 기기를 설정하는 코드를 반드시 삭제하세요.
        // GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = ["2077ef9a63d2b398840261c8221a0c9b"]
        
        IQKeyboardManager.shared.enable = true
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

