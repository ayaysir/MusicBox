//
//  PhotoAuth.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/08.
//

import UIKit
import Photos

private func photoAuth(isCamera: Bool, viewController: UIViewController) -> Bool {
    
    let name = isCamera ? "camera".localized : "photo library".localized
    let status: Int = isCamera
            ? AVCaptureDevice.authorizationStatus(for: AVMediaType.video).rawValue
            : PHPhotoLibrary.authorizationStatus().rawValue
    
    // PHAuthorizationStatus
    // AVAuthorizationStatus
    switch status {
    case 0:
        // .notDetermined
        let msg = "Are you sure you want to change the permission settings for your %@?"
        simpleDestructiveYesAndNo(viewController, message: msg.localizedFormat(name), title: "No Permission Status", yesHandler: openSetting)
    case 1:
        // .restricted
        simpleAlert(viewController, message: "Rejected by the system.")
    case 2:
        // .denied
        let msg = "The %@ permission is denied and cannot be used. Do you want to change the %@ permission settings?"
        simpleDestructiveYesAndNo(viewController, message: msg.localizedFormat(name, name), title: "Permission Denied", yesHandler: openSetting(action:))
    case 3:
        // .authorized
        return true
    case 4:
        // .limited (라이브러리 전용)
        return true
    default:
        simpleAlert(viewController, message: "unknown")
    }
    
    return false
}

func authPhotoLibrary(_ viewController: UIViewController) -> Bool {
    return photoAuth(isCamera: false, viewController: viewController)
}

func authDeviceCamera(_ viewController: UIViewController) -> Bool {
    return photoAuth(isCamera: true, viewController: viewController)
}

private func openSetting(action: UIAlertAction) -> Void {
    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
        return
    }

    if UIApplication.shared.canOpenURL(settingsUrl) {
        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
            print("Settings opened: \(success)") // Prints true
        })
    }
}
