//
//  MemberProfileViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/11.
//

import UIKit
import Firebase
import SwiftSpinner
import GoogleMobileAds

class MemberProfileViewController: UIViewController {
    
    private var bannerView: GADBannerView!
    
    @IBOutlet weak var lblUserEmail: UILabel!
    @IBOutlet weak var lblNickname: UILabel!
    @IBOutlet weak var lblInteresting: UILabel!
    @IBOutlet weak var imgUserProfile: UIImageView!
    
    @IBOutlet weak var imgEmailVerified: UIImageView!
    @IBOutlet weak var lblEmailVerified: UILabel!
    @IBOutlet weak var btnRefreshUserInfo: UIButton!
    
    @IBOutlet weak var alignXConstraint: NSLayoutConstraint!
    
    var handle: AuthStateDidChangeListenerHandle!
    
    // firebase ref
    var ref = Database.database().reference()
    var storageRef = Storage.storage().reference()
    
    var bottomConstantRaiseOnce = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ====== 광고 ====== //
        TrackingTransparencyPermissionRequest()
        if AdManager.productMode {
            bannerView = setupBannerAds(self, adUnitID: AdInfo.shared.archiveMain)
            bannerView.delegate = self
        }
        
        DispatchQueue.main.async {
            let realWidth = self.imgUserProfile.bounds.width
            self.imgUserProfile.layer.cornerRadius = realWidth * 0.5
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if Reachability.isConnectedToNetwork() {
            SwiftSpinner.show("Loading user information...".localized)
            Auth.auth().currentUser?.reload(completion: { error in
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }
                
                self.setUserInfoView(user: Auth.auth().currentUser)
            })
        } else {
            simpleAlert(self, message: "Not connected.")
            return
        }
        
        btnRefreshUserInfo.setTitle("", for: .normal)
        
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
            var viewControllers: [UIViewController] = []
            if let rootVC = self.navigationController?.viewControllers[0] as? UserCommunityViewController {
                viewControllers.append(rootVC)
            }
            let loginVC = mainStoryboard.instantiateViewController(withIdentifier: "SignInViewController")
            viewControllers.append(loginVC)
            self.navigationController?.setViewControllers(viewControllers, animated: true)
        } catch {
            simpleAlert(self, message: "Sign out failed: \(error.localizedDescription)")
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
            lblEmailVerified.text = "Email has been verified.".localized
            imgEmailVerified.image = UIImage(systemName: "checkmark.circle.fill")
            imgEmailVerified.tintColor = .green
        } else {
            lblEmailVerified.text = "Email is not verified.".localized
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
                self.lblInteresting.text = "Interesting: \(interesting)"
                self.lblNickname.text = "Nickname: \(nickname)"
                
            } else if let error = error {
                self.lblInteresting.text = "Interesting: -"
                self.lblNickname.text = "Nickname: -"
                print("get data failed:", error.localizedDescription)
            }
            
            self.getUserProfileImage(uid: uid)
        }
    }
    
    private func getUserProfileImage(uid: String) {
        
        let sampleImageRef = storageRef.child("images/users/\(uid)/thumb_\(uid).jpg")
        
        SwiftSpinner.show("Loading user's profile photo...".localized)
        
        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        sampleImageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                // Uh-oh, an error occurred!
                print("download error", error.localizedDescription)
                // SwiftSpinner.show(duration: 3, title: "Failed to load profile photo.".localized, animated: false, completion: nil)
            } else {
                // Data for "images/island.jpg" is returned
                let image = UIImage(data: data!)
                self.imgUserProfile.image = image
            }
            
            SwiftSpinner.hide(nil)
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

extension MemberProfileViewController: GADBannerViewDelegate {
    
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        if bottomConstantRaiseOnce {
            alignXConstraint.constant -= bannerView.adSize.size.height
            bottomConstantRaiseOnce = false
        }
    }
}
