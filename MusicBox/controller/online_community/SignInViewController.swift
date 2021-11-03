//
//  SignUpViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/03.
//

import UIKit
import Firebase

class SignInViewController: UIViewController {
    
    @IBOutlet weak var txfEmail: UITextField!
    @IBOutlet weak var txfPassword: UITextField!
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func btnActSubmit(_ sender: UIButton) {
        guard let userEmail = txfEmail.text,
              let userPassword = txfPassword.text
        else {
            return
        }
        
        Auth.auth().signIn(withEmail: userEmail, password: userPassword) { [self] authResult, error in
            
            if authResult != nil {
                print("로그인 되었습니다")
                let memberVC = mainStoryboard.instantiateViewController(withIdentifier: "MemberProfileViewController")
                self.navigationController?.setViewControllers([memberVC], animated: true)
                
            } else {
                simpleAlert(self, message: "로그인되지 않았습니다. \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    
    
}
