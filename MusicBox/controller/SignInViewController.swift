//
//  SignInViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/11.
//

import UIKit
import Firebase

class SignInViewController: UIViewController {
    
    @IBOutlet weak var txtUserEmail: UITextField!
    @IBOutlet weak var txtUserPassword: UITextField!
    
    @IBOutlet weak var lblUserEmail: UILabel!
    @IBOutlet weak var lblInteresting: UILabel!
    
    
    @IBOutlet weak var viewSignUpForm: UIView!
    @IBOutlet weak var viewUserInfo: UIView!
    
    var handle: AuthStateDidChangeListenerHandle!
    
    // firebase ref
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewSignUpForm.isHidden = true
        viewUserInfo.isHidden = true
        
        // firebase reference 초기화
        ref = Database.database().reference()
        
        lblInteresting.text = "관심분야:"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                self.viewUserInfo.isHidden = false
                self.viewSignUpForm.isHidden = true
                self.lblUserEmail.text = user.email
                
                let userRef = self.ref.child("users/\(user.uid)/interesting")
                userRef.getData { error, snapshot in
                    if snapshot.exists() {
                        self.lblInteresting.text = "관심분야: \(snapshot.value ?? "-")"
                    } else if let error = error {
                        self.lblInteresting.text = "관심분야: -"
                        print("get data failed:", error.localizedDescription)
                    }
                }
                
            } else {
                self.viewUserInfo.isHidden = true
                self.viewSignUpForm.isHidden = false
                self.lblUserEmail.text = ""
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    @IBAction func btnActSubmit(_ sender: UIButton) {
        guard let userEmail = txtUserEmail.text,
              let userPassword = txtUserPassword.text else {
            return
        }
        
        Auth.auth().signIn(withEmail: userEmail, password: userPassword) { [weak self] authResult, error in
            guard self != nil else { return }
            
            if authResult != nil {
                print("로그인 되었습니다")
            } else {
                print("로그인되지 않았습니다.", error?.localizedDescription ?? "")
            }
        }
    }
    
    @IBAction func btnActSignOut(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    @IBAction func btnGoToUserOnlyPage(_ sender: UIButton) {
        performSegue(withIdentifier: "userOnlyPage", sender: nil)
    }
    
    
}
