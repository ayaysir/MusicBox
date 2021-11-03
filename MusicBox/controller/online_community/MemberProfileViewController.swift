//
//  MemberProfileViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/11.
//

import UIKit
import Firebase
import SwiftSpinner

class MemberProfileViewController: UIViewController {
    
    @IBOutlet weak var lblUserEmail: UILabel!
    @IBOutlet weak var lblNickname: UILabel!
    @IBOutlet weak var lblInteresting: UILabel!
    @IBOutlet weak var imgUserProfile: UIImageView!
    
    @IBOutlet weak var imgEmailVerified: UIImageView!
    @IBOutlet weak var lblEmailVerified: UILabel!
    @IBOutlet weak var btnRefreshUserInfo: UIButton!
    
    var handle: AuthStateDidChangeListenerHandle!
    
    // firebase ref
    var ref = Database.database().reference()
    var storageRef = Storage.storage().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
//        handle = Auth.auth().addStateDidChangeListener { auth, user in
//            self.setUserInfoView(user: user)
//        }
        
        SwiftSpinner.show("회원 정보를 로딩하고 있습니다...")
        Auth.auth().currentUser?.reload(completion: { error in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            
            self.setUserInfoView(user: Auth.auth().currentUser)
        })
    }
    
    @IBAction func btnActUpdateUserInfo(_ sender: Any) {
        guard let updateVC = mainStoryboard.instantiateViewController(withIdentifier: "SignUpTableViewController") as? SignUpTableViewController else {
            return
        }
        updateVC.pageMode = .updateMode
        updateVC.resignDelegate = self
        self.navigationController?.pushViewController(updateVC, animated: true)
    }
    
    @IBAction func btnActSignOut(_ sender: UIButton) {
        do {
            SwiftSpinner.hide(nil)
            try Auth.auth().signOut()
            let loginVC = mainStoryboard.instantiateViewController(withIdentifier: "SignInViewController")
            self.navigationController?.setViewControllers([loginVC], animated: true)
        } catch {
            simpleAlert(self, message: "로그아웃에 실패하였습니다. \(error.localizedDescription)")
        }
    }
    
    @IBAction func btnActRefreshUserInfo(_ sender: UIButton) {
        Auth.auth().currentUser?.reload(completion: { error in
            self.setUserInfoView(user: Auth.auth().currentUser)
        })
    }
}

extension MemberProfileViewController {
    
    private func setUserInfoView(user: User?) {
        guard let user = user else {
            return
        }

        self.lblUserEmail.text = user.email
        self.getUserAdditionalInfo(uid: user.uid)
        
        if user.isEmailVerified {
            self.changeEmailVerified(true)
        } else {
            self.changeEmailVerified(false)
        }
    }
    
    private func changeEmailVerified(_ isVerified: Bool) {
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
    
    private func getUserAdditionalInfo(uid: String) {
        let userRef = self.ref.child("users/\(uid)/")
        userRef.getData { error, snapshot in
            if snapshot.exists() {
                let dict = snapshot.value as? [String: String]
                let interesting = dict["interesting"] ?? "-"
                let nickname = dict["nickname"] ?? "-"
                self.lblInteresting.text = "관심분야: \(interesting)"
                self.lblNickname.text = "닉네임: \(nickname)"
                
            } else if let error = error {
                self.lblInteresting.text = "관심분야: -"
                self.lblNickname.text = "닉네임: -"
                print("get data failed:", error.localizedDescription)
            }
            
            self.getUserProfileImage(uid: uid)
        }
    }
    
    private func getUserProfileImage(uid: String) {
        
        let sampleImageRef = storageRef.child("images/users/\(uid)/thumb_\(uid).jpg")
        
        SwiftSpinner.show("프로필 사진을 로딩하고 있습니다...")
        
        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        sampleImageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                // Uh-oh, an error occurred!
                print("download error", error.localizedDescription)
                SwiftSpinner.show(duration: 3, title: "프로필 사진 로딩에 실패하였습니다.", animated: false, completion: nil)
            } else {
                // Data for "images/island.jpg" is returned
                let image = UIImage(data: data!)
                self.imgUserProfile.image = image
                SwiftSpinner.hide(nil)
            }
        }
    }
    
}

extension MemberProfileViewController: ResignMemberDelegate {
    func didResignSuccess(_ controller: SignUpTableViewController) {
        SwiftSpinner.hide(nil)
        let loginVC = mainStoryboard.instantiateViewController(withIdentifier: "SignInViewController")
        self.navigationController?.setViewControllers([loginVC], animated: false)
    }
}
