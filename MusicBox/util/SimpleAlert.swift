//
//  AlertUtil.swift
//  DiffuserStick
//
//  Created by yoonbumtae on 2021/07/15.
//
import UIKit

func simpleAlert(_ controller: UIViewController, message: String) {
    let alertController = UIAlertController(title: "Caution", message: message, preferredStyle: .alert)
    let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    alertController.addAction(alertAction)
    controller.present(alertController, animated: true, completion: nil)
}

func simpleAlert(_ controller: UIViewController, message: String, title: String, handler: ((UIAlertAction) -> Void)?) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let alertAction = UIAlertAction(title: "OK", style: .default, handler: handler)
    alertController.addAction(alertAction)
    controller.present(alertController, animated: true, completion: nil)
}

func simpleDestructiveYesAndNo(_ controller: UIViewController, message: String, title: String, yesHandler: ((UIAlertAction) -> Void)?) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let alertActionNo = UIAlertAction(title: "No", style: .cancel, handler: nil)
    let alertActionYes = UIAlertAction(title: "Yes", style: .destructive, handler: yesHandler)
    alertController.addAction(alertActionNo)
    alertController.addAction(alertActionYes)
    controller.present(alertController, animated: true, completion: nil)
}

func simpleYesAndNo(_ controller: UIViewController, message: String, title: String, yesHandler: ((UIAlertAction) -> Void)?) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let alertActionNo = UIAlertAction(title: "No", style: .cancel, handler: nil)
    let alertActionYes = UIAlertAction(title: "Yes", style: .default, handler: yesHandler)
    alertController.addAction(alertActionNo)
    alertController.addAction(alertActionYes)
    controller.present(alertController, animated: true, completion: nil)
}
