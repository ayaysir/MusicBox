//
//  SignUpTableViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/03.
//

import UIKit
import Firebase
import Photos
import SwiftSpinner
import Kingfisher
import GoogleMobileAds

let interestingList = ["Pop", "Classical", "Soundtrack", "Rock", "Hiphop", "R&B", "Alternative", "Jazz"]
let availableImageExtList = ["png", "jpg", "jpeg", "gif"]

enum SignUpPageMode: String {
  case signUpMode, updateMode
}

protocol SignUpDelegate: AnyObject {
  func didSignUpSuccess (_ controller: SignUpTableViewController, isSuccess: Bool, uid: String)
  func didUpdateUserInfoSuccess (_ controller: SignUpTableViewController, isSuccess: Bool)
}

protocol ResignMemberDelegate: AnyObject {
  func didResignSuccess(_ controller: SignUpTableViewController)
}

class SignUpTableViewController: UITableViewController {
  
  private var bannerView: BannerView!
  
  @IBOutlet weak var txfUserEmail: UITextField!
  @IBOutlet weak var txfPassword: UITextField!
  @IBOutlet weak var txfPasswordConfirm: UITextField!
  @IBOutlet weak var lblPasswordConfirmed: UILabel!
  @IBOutlet weak var txfNickname: UITextField!
  @IBOutlet weak var pkvInteresting: UIPickerView!
  @IBOutlet weak var imgProfilePicture: UIImageView!
  
  @IBOutlet weak var btnSubmitInfo: UIButton!
  @IBOutlet weak var btnResetPageInfo: UIButton!
  @IBOutlet weak var btnWithdrawMember: UIButton!
  
  @IBOutlet weak var cellResignMember: UITableViewCell!
  
  // 회원정보 업데이트의 경우 리셋 기능을 위해 임시 저장
  private var userInterestingIndex: Int?
  private var userInterestingStr: String?
  private var userNickname: String?
  private var userImage: UIImage?
  
  var isImageChanged: Bool = false
  
  weak var delegate: SignUpDelegate?
  weak var resignDelegate: ResignMemberDelegate?
  var pageMode: SignUpPageMode = .signUpMode
  
  var ref = Database.database().reference()
  var storageRef = Storage.storage().reference()
  
  var selectedInteresting: String!
  
  var imagePickerController = UIImagePickerController()
  var userProfileThumbnail: UIImage! = UIImage(named: "sample")
  
  var block: FileCompletionBlock?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // 사진, 카메라 권한 (최초 요청)
    PHPhotoLibrary.requestAuthorization { status in
    }
    AVCaptureDevice.requestAccess(for: .video) { granted in
    }
    
    // 모드에 따라 제목 변경
    self.title = pageMode == .signUpMode ? "Sign Up" : "Update User Information"
    
    // 피커뷰 딜리게이트, 데이터소스 연결
    pkvInteresting.delegate = self
    pkvInteresting.dataSource = self
    
    // 사진: 이미지 피커에 딜리게이트 생성
    imagePickerController.delegate = self
    
    txfUserEmail.delegate = self
    txfPassword.delegate = self
    txfPasswordConfirm.delegate = self
    
    lblPasswordConfirmed.text = ""
    
    switch pageMode {
    case .signUpMode:
      
      selectedInteresting = interestingList[0]
      btnWithdrawMember.isHidden = true
      cellResignMember.isHidden = true
      
    case .updateMode:
      
      btnWithdrawMember.isHidden = false
      cellResignMember.isHidden = false
      btnSubmitInfo.setTitle("Update", for: .normal)
      
      loadExistingUserInfo()
    }
    
    txfPassword.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    txfPasswordConfirm.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    
    // ====== 광고 ====== //
    TrackingTransparencyPermissionRequest()
    if AdManager.isReallyShowAd {
      bannerView = setupBannerAds(self, adUnitID: AdInfo.shared.archiveMain)
      bannerView.delegate = self
    }
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    bannerView?.fitInView(self)
  }
  
  @IBAction func btnActCancel(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func btnActReset(_ sender: UIButton) {
    
    txfPassword.text = ""
    txfPasswordConfirm.text = ""
    lblPasswordConfirmed.text = ""
    
    switch pageMode {
    case .signUpMode:
      txfUserEmail.text = ""
      txfNickname.text = ""
      pkvInteresting.selectRow(0, inComponent: 0, animated: false)
      selectedInteresting = interestingList[0]
      // -- 사진 초기화 --
      imgProfilePicture.image = UIImage(named: "sample")
    case .updateMode:
      txfNickname.text = userNickname
      pkvInteresting.selectRow(userInterestingIndex ?? 0, inComponent: 0, animated: true)
      selectedInteresting = userInterestingStr ?? interestingList[0]
      imgProfilePicture.image = userImage
    }
    isImageChanged = false
    
  }
  
  @IBAction func btnActSubmit(_ sender: UIButton) {
    print(#function, sender.bounds)
    submit()
  }
  
  @IBAction func barBtnActSubmit(_ sender: Any) {
    submit()
  }
  
  @IBAction func btnActWithdrawal(_ sender: Any) {
    guard pageMode == .updateMode else {
      return
    }
    
    simpleDestructiveYesAndNo(self, message: "Are you sure you want to withdrawal membership? If you cancel your membership, your member information is deleted and cannot be recovered. Posts written are not deleted.".localized, title: "Withdrawal Membership".localized) { action in
      
      guard let user = Auth.auth().currentUser else {
        return
      }
      
      self.ref.child("users/\(user.uid)").removeValue { error, ref in
        SwiftSpinner.show("Membership cancellation in progress...".localized)
        if let error = error {
          print("userinfo delete failed:", error.localizedDescription)
        }
        
        self.storageRef.child("images/users/\(user.uid)").delete { error in
          if let error = error {
            print("Image delete failed:", error.localizedDescription)
          }
          
          user.delete { error in
            print("deleting user information:", user.uid)
            
            if let error = error {
              // An error happened.
              SwiftSpinner.hide(nil)
              simpleAlert(self, message: error.localizedDescription)
              return
            } else {
              // Account deleted.
              SwiftSpinner.hide {
                self.navigationController?.popViewController(animated: true)
                if let resignDelegate = self.resignDelegate {
                  resignDelegate.didResignSuccess(self)
                }
              }
            }
          }
        }
      }
    }
  }
  
  @IBAction func btnActTakePhoto(_ sender: UIButton) {
    takePhoto()
  }
  
  @IBAction func btnActFromLoadPhoto(_ sender: UIButton) {
    getPhotoFromLibrary()
  }
  
}

// MARK: - Firebase Method

extension SignUpTableViewController {
  
  private func submit() {
    guard validateFieldValues() else {
      return
    }
    
    switch pageMode {
    case .signUpMode:
      
      guard let userEmail = txfUserEmail.text, let userPassword = txfPassword.text else {
        return
      }
      
      sendInfoToFirebase(withEmail: userEmail, password: userPassword)
    case .updateMode:
      guard let user = getCurrentUser() else {
        return
      }
      guard let newPassword = txfPassword.text,
            let newPasswordConfirm = txfPasswordConfirm.text else {
        return
      }
      
      // 비빌번호를 두 쪽 다 입력한 때
      if newPassword != "" || newPasswordConfirm != "" {
        guard newPassword == newPasswordConfirm else {
          simpleAlert(self, message: "Passwords do not match.".localized)
          return
        }
        sendInfoToFirebase(withEmail: user.email!, password: newPassword)
      } else {
        // 비밀번호가 입력되지 않은 때
        sendInfoToFirebaseOnlyAdditionalInfo()
      }
    }
  }
  
  func sendVerificationMail(authUser: User?) {
    if authUser != nil && authUser!.isEmailVerified == false {
      SwiftSpinner.show("Sending a verification email...".localized)
      authUser!.sendEmailVerification(completion: { (error) in
        // Notify the user that the mail has sent or couldn't because of an error.
        if error != nil {
          print(error!.localizedDescription, error!)
          return
        }
        
        print("이메일 전송 완료")
      })
    }
    else {
      // Either the user is not available, or the user is already verified.
    }
  }
  
  func sendInfoToFirebase(withEmail userEmail: String, password userPassword: String) {
    
    SwiftSpinner.show("Sending member information to server...")
    
    // 추가 정보 입력
    let interesting = selectedInteresting ?? "None"
    let nickname = txfNickname.text ?? "None"
    
    do {
      let image = try resizeImage(image: imgProfilePicture.image!, maxSize: 1020)
      try userProfileThumbnail = resizeImage(image: imgProfilePicture.image!, maxSize: 200)
      
      switch pageMode {
      case .signUpMode:
        
        if let user = getCurrentUser(), user.isAnonymous {
          let credential = EmailAuthProvider.credential(withEmail: userEmail, password: userPassword)
          user.link(with: credential) { [self] authResult, error in
            guard let user = authResult?.user, error == nil else {
              simpleAlert(self, message: error!.localizedDescription)
              return
            }
            
            // 이메일 인증 요청
            sendVerificationMail(authUser: user)
            
            ref.child("users").child(user.uid).child("interesting").setValue(interesting)
            ref.child("users").child(user.uid).child("nickname").setValue(nickname)
            
            // 이미지 업로드
            if isImageChanged {
              SwiftSpinner.show("Your profile image is being sent...".localized)
              
              let images = [
                ImageWithName(name: "\(user.uid)/thumb_\(user.uid)", image: userProfileThumbnail, fileExt: "jpg"),
                ImageWithName(name: "\(user.uid)/original_\(user.uid)", image: image, fileExt: "jpg")
              ]
              
              uploadUserProfileImage(images: images)
            } else {
              completed()
            }
          }
        }
      case .updateMode:
        
        guard let user = getCurrentUser() else {
          return
        }
        
        ref.child("users").child(user.uid).child("interesting").setValue(interesting)
        ref.child("users").child(user.uid).child("nickname").setValue(nickname)
        
        Auth.auth().currentUser?.updatePassword(to: userPassword, completion: { [self] error in
          if let error = error {
            simpleAlert(self, message: error.localizedDescription)
            return
          }
          
          // 이미지 업로드
          if isImageChanged {
            
            SwiftSpinner.show("Your profile image is being sent...".localized)
            let images = [
              ImageWithName(name: "\(user.uid)/thumb_\(user.uid)", image: userProfileThumbnail, fileExt: "jpg"),
              ImageWithName(name: "\(user.uid)/original_\(user.uid)", image: image, fileExt: "jpg")
            ]
            
            uploadUserProfileImage(images: images)
          } else {
            completed()
          }
          
        })
      }
      
    } catch  {
      print("Image convert failed:", error)
      return
    }
    
  }
  
  func sendInfoToFirebaseOnlyAdditionalInfo() {
    guard pageMode == .updateMode else {
      return
    }
    
    guard let user = getCurrentUser() else {
      return
    }
    
    do {
      let image = try resizeImage(image: imgProfilePicture.image!, maxSize: 1020)
      try userProfileThumbnail = resizeImage(image: imgProfilePicture.image!, maxSize: 200)
      
      SwiftSpinner.show("Sending member information to server...".localized)
      
      // 추가 정보 입력
      let interesting = selectedInteresting ?? "None"
      let nickname = txfNickname.text ?? "None"
      
      ref.child("users").child(user.uid).child("interesting").setValue(interesting)
      ref.child("users").child(user.uid).child("nickname").setValue(nickname)
      
      // 이미지 업로드
      if isImageChanged {
        SwiftSpinner.show("Your profile image is being sent...".localized)
        
        let images = [
          ImageWithName(name: "\(user.uid)/thumb_\(user.uid)", image: userProfileThumbnail, fileExt: "jpg"),
          ImageWithName(name: "\(user.uid)/original_\(user.uid)", image: image, fileExt: "jpg")
        ]
        uploadUserProfileImage(images: images)
      } else {
        completed()
      }
      
    } catch {
      print(error.localizedDescription)
    }
  }
  
  func loadExistingUserInfo() {
    SwiftSpinner.show("Loading existing profile image...".localized)
    
    if pageMode == .updateMode {
      // 회원 정보 불러오기
      guard let userUID = getCurrentUserUID() else {
        return
      }
      guard let user = getCurrentUser() else {
        return
      }
      
      txfUserEmail.text = user.email
      txfUserEmail.isEnabled = false
      
      ref.child("users/\(userUID)").getData { error, snapshot in
        if let error = error {
          print("get user information failed:", error.localizedDescription)
          return
        }
        
        if let snapshot = snapshot, snapshot.exists() {
          let dict = snapshot.value as? [String: String]
          
          if let interesting = dict["interesting"] as? String {
            let index = interestingList.firstIndex(of: interesting) ?? 0
            self.pkvInteresting.selectRow(index, inComponent: 0, animated: true)
            self.selectedInteresting = interesting
            
            self.userInterestingIndex = index
            self.userInterestingStr = interesting
          }
          
          let nickname = dict["nickname"] as? String
          self.txfNickname.text = nickname
          self.userNickname = nickname
        }
      }
      
      
      getFileURL(childRefStr: "images/users/\(userUID)/original_\(userUID).jpg") { url in
        
        guard let url = url else {
          return
        }
        self.imgProfilePicture.kf.setImage(with: url, placeholder: nil, options: nil) { result in
          self.userImage = self.imgProfilePicture.image
          SwiftSpinner.hide(nil)
        }
      } failedHandler: { error in
        SwiftSpinner.show(duration: 1.5, title: "Failed to load existing profile image.", animated: false, completion: nil)
      }
    }
  }
}

// MARK: - Image Upload

extension SignUpTableViewController {
  
  func uploadUserProfileImage(images: [ImageWithName]) {
    startUploading(images: images, childRefPath: "images/users") {
      self.completed()
    }
  }
  
  private func completed() {
    
    guard let user = getCurrentUser() else {
      return
    }
    
    SwiftSpinner.hide(nil)
    
    let attachTextEN = self.pageMode == .signUpMode ? "registration".localized : "membership information update".localized
    
    let englishMsg = "%@: Your membership %@ is complete.".localizedFormat(user.email!, attachTextEN)
    
    simpleAlert(self, message: englishMsg, title: "Completed") { action in
      
      self.navigationController?.popViewController(animated: true)
      if self.delegate != nil {
        self.delegate!.didSignUpSuccess(self, isSuccess: true, uid: user.uid)
      }
    }
  }
  
  func startUploading(images: [ImageWithName], childRefPath: String, completion: @escaping FileCompletionBlock) {
    if images.count == 0 {
      completion()
      return;
    }
    
    block = completion
    uploadImage(forIndex: 0, images: images, childRefPath: childRefPath)
  }
  
  private func uploadImage(forIndex index:Int, images: [ImageWithName], childRefPath: String) {
    
    if index < images.count {
      /// Perform uploading
      
      let imageInfo = images[index]
      let name = imageInfo.name
      let image = imageInfo.image
      let fileExt = imageInfo.fileExt
      let quality = imageInfo.compressionQuality
      
      guard let data = image.jpegData(compressionQuality: quality) else {
        return
      }
      
      let fileName = "\(name).\(fileExt)"
      
      FirebaseFileManager.shared.setChild(childRefPath)
      FirebaseFileManager.shared.upload(data: data, withName: fileName, block: { (url) in
        /// After successfully uploading call this method again by increment the **index = index + 1**
        print(url ?? "Couldn't not upload. You can either check the error or just skip this.")
        self.uploadImage(forIndex: index + 1, images: images, childRefPath: childRefPath)
      })
      return;
    }
    
    if block != nil {
      block!()
    }
  }
}

// MARK: - Validate fields
extension SignUpTableViewController {
  func validateFieldValues() -> Bool {
    
    let alertTitle = "Unable to Create".localized
    
    guard let userEmail = txfUserEmail.text,
          let userPassword = txfPassword.text,
          let userPasswordConfirm = txfPasswordConfirm.text else {
      return false
    }
    
    switch pageMode {
    case .signUpMode:
      
      guard userEmail != "" else {
        simpleAlert(self, message: "Please enter your e-mail.".localized, title: alertTitle) { action in
          self.txfUserEmail.becomeFirstResponder()
        }
        return false
      }
      
      let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
      guard userEmail.range(of: emailRegex, options: .regularExpression, range: nil, locale: nil) != nil else {
        simpleAlert(self, message: "Email format is incorrect. Please rewrite your email.".localized, title: alertTitle) { action in
          self.txfUserEmail.becomeFirstResponder()
        }
        return false
      }
      
      guard userPassword != "" else {
        simpleAlert(self, message: "You must enter a password.".localized, title: alertTitle) { action in
          self.txfPassword.becomeFirstResponder()
        }
        return false
      }
      
      guard userPasswordConfirm != "" else {
        simpleAlert(self, message: "You must enter a password confirmation.".localized, title: alertTitle) { action in
          self.txfPasswordConfirm.becomeFirstResponder()
        }
        return false
      }
      
      guard userPassword == userPasswordConfirm else {
        simpleAlert(self, message: "Passwords do not match.".localized, title: alertTitle) { action in
          self.txfPassword.becomeFirstResponder()
        }
        return false
      }
      
    case .updateMode:
      break
    }
    
    guard txfNickname.text!.count >= 1 && txfNickname.text!.count <= 10 else {
      simpleAlert(self, message: "Please write your nickname within 1-10 characters.".localized, title: alertTitle) { action in
        self.txfNickname.becomeFirstResponder()
      }
      return false
    }
    
    return true
  }
}

// MARK: - Delegate Extensions

extension SignUpTableViewController: UIPickerViewDelegate, UIPickerViewDataSource {
  // 컴포넌트(열) 개수
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  // 리스트(행) 개수
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return interestingList.count
  }
  
  // 피커뷰 목록 표시
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return interestingList[row]
  }
  
  // 특정 피커뷰 선택시 selectedInteresting에 할당
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    selectedInteresting = interestingList[row]
  }
}

extension SignUpTableViewController: UITextFieldDelegate {
  
  func setLabelPasswordConfirm(_ password: String, _ passwordConfirm: String)  {
    
    guard passwordConfirm != "" else {
      lblPasswordConfirmed.text = ""
      return
    }
    
    if password == passwordConfirm {
      lblPasswordConfirmed.textColor = .green
      lblPasswordConfirmed.text = "Passwords match.".localized
    } else {
      lblPasswordConfirmed.textColor = .red
      lblPasswordConfirmed.text = "Passwords do not match.".localized
    }
  }
  
  @objc func textFieldDidChange(_ textField: UITextField) {
    
    switch textField {
    case txfPassword:
      guard let password = textField.text, let passwordConfirm = txfPasswordConfirm.text else {
        return
      }
      setLabelPasswordConfirm(password, passwordConfirm)
    case txfPasswordConfirm:
      guard let password = txfPassword.text, let passwordConfirm = textField.text else {
        return
      }
      setLabelPasswordConfirm(password, passwordConfirm)
    default:
      break
    }
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    
    switch textField {
    case txfUserEmail:
      txfPassword.becomeFirstResponder()
    case txfPassword:
      txfPasswordConfirm.becomeFirstResponder()
    default:
      textField.resignFirstResponder()
    }
    
    return false
  }
}

extension SignUpTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  /*
   var imagePickerController = UIImagePickerController()
   var userProfileThumbnail: UIImage!
   
   // 사진: 이미지 피커에 딜리게이트 생성
   imagePickerController.delegate = self
   */
  
  func takePhoto() {
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      self.imagePickerController.sourceType = .camera
      if authDeviceCamera(self) {
        present(self.imagePickerController, animated: true, completion: nil)
      }
    } else {
      simpleAlert(self, message: "Camera cannot be used.")
    }
  }
  
  func getPhotoFromLibrary() {
    self.imagePickerController.sourceType = .photoLibrary
    if authPhotoLibrary(self) {
      present(self.imagePickerController, animated: true, completion: nil)
    }
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
      imgProfilePicture.image = image
    }
    isImageChanged = true
    dismiss(animated: true, completion: nil)
  }
}

extension SignUpTableViewController: BannerViewDelegate {
  
  func bannerViewDidReceiveAd(_ bannerView: BannerView) {
    print(#function, "received ad.")
  }
  
  func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
    print(#function, "received ad. Error:", error)
  }
}
