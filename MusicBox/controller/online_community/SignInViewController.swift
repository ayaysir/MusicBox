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
    
    @IBOutlet weak var viewLoginForm: UIView!
    @IBOutlet weak var cnstLoginFormWidth: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txfEmail.delegate = self
        txfPassword.delegate = self
        
        guard Reachability.isConnectedToNetwork() else {
            let notConnectedVC = mainStoryboard.instantiateViewController(withIdentifier: "NotConnectedViewController") as? NotConnectedViewController
            notConnectedVC?.vcName = "SignInViewController"
            
            self.navigationController?.setViewControllers([notConnectedVC!], animated: false)
            
            return
        }
        
        if Auth.auth().currentUser != nil {
            let memberVC = mainStoryboard.instantiateViewController(withIdentifier: "MemberProfileViewController")
            self.navigationController?.setViewControllers([memberVC], animated: false)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        if UIDevice.current.model.hasPrefix("iPad") {
             print("it is an iPad")
        } else {
             
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
        submitLoginInfo()
    }
}

extension SignInViewController {
    
    func submitLoginInfo() {
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

extension SignInViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case txfEmail:
            txfPassword.becomeFirstResponder()
        case txfPassword:
            submitLoginInfo()
        default:
            break
        }
        
        return true
    }
}
