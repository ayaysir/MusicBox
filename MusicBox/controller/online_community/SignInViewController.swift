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
    
    @IBOutlet weak var imgUserProfile: UIImageView!
    
    @IBOutlet weak var viewSignUpForm: UIView!
    @IBOutlet weak var viewUserInfo: UIView!
    
    @IBOutlet weak var imgEmailVerified: UIImageView!
    @IBOutlet weak var lblEmailVerified: UILabel!
    @IBOutlet weak var btnRefreshUserInfo: UIButton!
    
    
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
        
        imgUserProfile.layer.cornerRadius = imgUserProfile.bounds.size.width * 0.5
        imgUserProfile.clipsToBounds = true
  
        btnRefreshUserInfo.setTitle("", for: .normal)
    }
    
    func changeEmailVerified(_ isVerified: Bool) {
        if isVerified {
            lblEmailVerified.text = "이메일 인증이 완료되었습니다."
            imgEmailVerified.image = UIImage(systemName: "checkmark.circle.fill")
            imgEmailVerified.tintColor = .green
        } else {
            lblEmailVerified.text = "이메일이 인증되지 않았습니다."
            imgEmailVerified.image = UIImage(systemName: "xmark.circle.fill")
            imgEmailVerified.tintColor = .systemGray3
        }
        
    }
    
    func setUserInfoView(user: User?) {
        if let user = user {
            self.viewUserInfo.isHidden = false
            self.viewSignUpForm.isHidden = true
            self.lblUserEmail.text = user.email
            
            self.getUserAdditionalInfo(uid: user.uid)
            self.getUserProfileImage(uid: user.uid)
            
            if user.isEmailVerified {
                self.changeEmailVerified(true)
            } else {
                self.changeEmailVerified(false)
            }
            
        } else {
            self.viewUserInfo.isHidden = true
            self.viewSignUpForm.isHidden = false
            self.lblUserEmail.text = ""
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { auth, user in
            self.setUserInfoView(user: user)
        }
        
        Auth.auth().currentUser?.reload(completion: { error in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            
            self.setUserInfoView(user: Auth.auth().currentUser)
        })
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
    
    @IBAction func btnActRefreshUserInfo(_ sender: UIButton) {
        Auth.auth().currentUser?.reload(completion: { error in
            self.setUserInfoView(user: Auth.auth().currentUser)
        })
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let signUpViewController = segue.destination as! SignUpViewController
        if segue.identifier == "signUp" {
            signUpViewController.delegate = self
        }
    }
}

extension SignInViewController {
    
    func getUserAdditionInfoWithPhoto(uid: String) {
        
    }
    
    private func getUserAdditionalInfo(uid: String) {
        let userRef = self.ref.child("users/\(uid)/interesting")
        userRef.getData { error, snapshot in
            if snapshot.exists() {
                self.lblInteresting.text = "관심분야: \(snapshot.value ?? "-")"
            } else if let error = error {
                self.lblInteresting.text = "관심분야: -"
                print("get data failed:", error.localizedDescription)
            }
        }
    }
    
    private func getUserProfileImage(uid: String) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let sampleImageRef = storageRef.child("images/users/\(uid)/thumb_\(uid).jpg")

        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        sampleImageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
          if let error = error {
            // Uh-oh, an error occurred!
            print("download error", error.localizedDescription)
          } else {
            // Data for "images/island.jpg" is returned
            let image = UIImage(data: data!)
            self.imgUserProfile.image = image
          }
        }
    }
}

extension SignInViewController: SignUpDelegate {
    func didSignUpSuccess(_ controller: SignUpViewController, isSuccess: Bool, uid: String) {
        getUserAdditionalInfo(uid: uid)
        getUserProfileImage(uid: uid)
    }
}
