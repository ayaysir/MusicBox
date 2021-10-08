//
//  PhotoAuth.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/08.
//

import UIKit
import Photos

private func photoAuth(isCamera: Bool, viewController: UIViewController) -> Bool {
    
    let name = isCamera ? "카메라" : "사진 라이브러리"
    let status: Int = isCamera
            ? AVCaptureDevice.authorizationStatus(for: AVMediaType.video).rawValue
            : PHPhotoLibrary.authorizationStatus().rawValue
    
    // PHAuthorizationStatus
    // AVAuthorizationStatus
    switch status {
    case 0:
        // .notDetermined
        simpleDestructiveYesAndNo(viewController, message: "\(name) 권한 설정을 변경하시겠습니까?", title: "권한 정보 없음", yesHandler: openSetting)
    case 1:
        // .restricted
        simpleAlert(viewController, message: "시스템에 의해 거부되었습니다.")
    case 2:
        // .denied
        simpleDestructiveYesAndNo(viewController, message: "\(name) 기능 권한이 거부되어 사용할 수 없습니다. \(name) 권한 설정을 변경하시겠습니까?", title: "권한 거부됨", yesHandler: openSetting(action:))
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

func doTaskByPhotoAuthorization(_ viewController: UIViewController) -> Bool {
    return photoAuth(isCamera: true, viewController: viewController)
}

func doTaskByCameraAuthorization(_ viewController: UIViewController) -> Bool {
    return photoAuth(isCamera: false, viewController: viewController)
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
