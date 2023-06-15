//
//  SceneDelegate.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/09.
//

import UIKit

class OpenFromExternalAppManager {
    static let shared = OpenFromExternalAppManager()
    var isFromExternalApp: Bool = false
    var fileURL: URL!
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        if connectionOptions.urlContexts.isNotEmpty {
//            print("from WillConnectTo:", connectionOptions.urlContexts.first?.url, to: &logger)
            assignURLToRootForWCT(fileURL: connectionOptions.urlContexts.first?.url)
        }
        
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
//        print("from openURLContexts", URLContexts.first?.url, to: &logger)
        assignURLToRoot(fileURL: URLContexts.first?.url)
    }

    private func assignURLToRoot(fileURL: URL?) {
        
        guard let fileURL = fileURL else {
            print("SceneDelegate: URL is null.", to: &logger)
            return
        }
        
        guard fileURL.isFileURL else {
            print("SceneDelegate: URL is not file url.", to: &logger)
            return
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "OpenFromExternalApp"), object: fileURL)
        print("reached this area:", to: &logger)
    }
    
    private func assignURLToRootForWCT(fileURL: URL?) {
        
        guard let fileURL = fileURL else {
            print("SceneDelegate: URL is null.", to: &logger)
            return
        }
        
        guard fileURL.isFileURL else {
            print("SceneDelegate: URL is not file url.", to: &logger)
            return
        }
        
        OpenFromExternalAppManager.shared.isFromExternalApp = true
        OpenFromExternalAppManager.shared.fileURL = fileURL
        
    }
}

