//
//  AlertUtil.swift
//  DiffuserStick
//
//  Created by yoonbumtae on 2021/07/15.
//
import UIKit

func simpleAlert(_ controller: UIViewController, message: String) {
    let alertController = UIAlertController(title: "경고", message: message, preferredStyle: .alert)
    let alertAction = UIAlertAction(title: "확인", style: .default, handler: nil)
    alertController.addAction(alertAction)
    controller.present(alertController, animated: true, completion: nil)
}

func simpleAlert(_ controller: UIViewController, message: String, title: String, handler: ((UIAlertAction) -> Void)?) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let alertAction = UIAlertAction(title: "확인", style: .default, handler: handler)
    alertController.addAction(alertAction)
    controller.present(alertController, animated: true, completion: nil)
}

func simpleDestructiveYesAndNo(_ controller: UIViewController, message: String, title: String, yesHandler: ((UIAlertAction) -> Void)?) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let alertActionNo = UIAlertAction(title: "아니오", style: .cancel, handler: nil)
    let alertActionYes = UIAlertAction(title: "예", style: .destructive, handler: yesHandler)
    alertController.addAction(alertActionNo)
    alertController.addAction(alertActionYes)
    controller.present(alertController, animated: true, completion: nil)
}
