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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Auth.auth().currentUser != nil {
            let memberVC = mainStoryboard.instantiateViewController(withIdentifier: "MemberProfileViewController")
            self.navigationController?.setViewControllers([memberVC], animated: false)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SignUpSegue" {
            let destVC = segue.destination as? SignUpTableViewController
            destVC?.pageMode = .signUpMode
            destVC?.delegate = self
        }
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

extension SignInViewController: SignUpDelegate {
    
    func changeRootController() {
        if Auth.auth().currentUser != nil {
            let memberVC = mainStoryboard.instantiateViewController(withIdentifier: "MemberProfileViewController")
            self.navigationController?.setViewControllers([memberVC], animated: false)
        }
    }
    
    func didUpdateUserInfoSuccess(_ controller: SignUpTableViewController, isSuccess: Bool) {
    }

    func didSignUpSuccess(_ controller: SignUpTableViewController, isSuccess: Bool, uid: String) {
        changeRootController()
    }
}
