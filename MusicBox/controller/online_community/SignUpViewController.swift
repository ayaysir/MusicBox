//
//  SignUpViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/11.
//

import UIKit
import Firebase
import Photos
import SwiftSpinner
import Kingfisher

protocol SignUpDelegate: AnyObject {
    func didSignUpSuccess (_ controller: SignUpViewController, isSuccess: Bool, uid: String)
    func didUpdateUserInfoSuccess (_ controller: SignUpViewController, isSuccess: Bool)
}

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var lblPageTitle: UILabel!
    
    @IBOutlet weak var txtUserEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtPasswordConfirm: UITextField!
    @IBOutlet weak var lblPasswordConfirmed: UILabel!
    @IBOutlet weak var txfNickname: UITextField!
    @IBOutlet weak var pkvInteresting: UIPickerView!
    @IBOutlet weak var imgProfilePicture: UIImageView!
    
    @IBOutlet weak var btnSubmitInfo: UIButton!
    @IBOutlet weak var btnResetPageInfo: UIButton!
    @IBOutlet weak var btnWithdrawMember: UIButton!
    
    // 회원정보 업데이트의 경우 리셋 기능을 위해 임시 저장
    private var userInterestingIndex: Int?
    private var userInterestingStr: String?
    private var userNickname: String?
    private var userImage: UIImage?
    
    weak var delegate: SignUpDelegate?
    var pageMode: SignUpPageMode = .signUpMode
    
    var ref = Database.database().reference()
    var storageRef = Storage.storage().reference()
    
    let interestingList = ["Pop", "Classical", "Soundtrack", "Rock", "Hiphop", "R&B", "Alternative", "Jazz"]
    var selectedInteresting: String!
    
    var imagePickerController = UIImagePickerController()
    var userProfileThumbnail: UIImage!
    
    var availableImageExtList = ["png", "jpg", "jpeg", "gif"]
    
    /// Here is the completion block
    typealias FileCompletionBlock = () -> Void
    var block: FileCompletionBlock?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 사진, 카메라 권한 (최초 요청)
        PHPhotoLibrary.requestAuthorization { status in
        }
        AVCaptureDevice.requestAccess(for: .video) { granted in
        }
        
        // 모드에 따라 제목 변경
        lblPageTitle.text = pageMode == .signUpMode ? "Sign Up" : "Update User Information"
        
        // 피커뷰 딜리게이트, 데이터소스 연결
        pkvInteresting.delegate = self
        pkvInteresting.dataSource = self
        
        // 사진: 이미지 피커에 딜리게이트 생성
        imagePickerController.delegate = self
        
        txtUserEmail.delegate = self
        txtPassword.delegate = self
        txtPasswordConfirm.delegate = self
        
        lblPasswordConfirmed.text = ""
        
        switch pageMode {
        case .signUpMode:
            
            selectedInteresting = interestingList[0]
            btnWithdrawMember.isHidden = true
            
        case .updateMode:
        
            btnWithdrawMember.isHidden = false
            btnSubmitInfo.setTitle("Update", for: .normal)
            
            loadExistingUserInfo()
        }
    }
    
    func sendVerificationMail(authUser: User?) {
        if authUser != nil && authUser!.isEmailVerified == false {
            SwiftSpinner.show("인증 이메일을 전송하고 있습니다...")
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
        
        SwiftSpinner.show("회원 정보를 전송하고 있습니다...")
        
        // 추가 정보 입력
        let interesting = selectedInteresting ?? "None"
        let nickname = txfNickname.text ?? "None"
        
        do {
            let image = try resizeImage(image: imgProfilePicture.image!, maxSize: 1020)
            try userProfileThumbnail = resizeImage(image: imgProfilePicture.image!, maxSize: 200)
            
            switch pageMode {
            case .signUpMode:
                Auth.auth().createUser(withEmail: userEmail, password: userPassword) { [self] authResult, error in
                    // 이메일, 비밀번호 전송
                    guard let user = authResult?.user, error == nil else {
                        simpleAlert(self, message: error!.localizedDescription)
                        return
                    }
                    
                    // 이메일 인증 요청
                    sendVerificationMail(authUser: user)
                    
                    ref.child("users").child(user.uid).child("interesting").setValue(interesting)
                    ref.child("users").child(user.uid).child("nickname").setValue(nickname)
                    
                    let images = [
                        ImageWithName(name: "\(user.uid)/thumb_\(user.uid)", image: userProfileThumbnail, fileExt: "jpg"),
                        ImageWithName(name: "\(user.uid)/original_\(user.uid)", image: image, fileExt: "jpg")
                    ]
                    
                    // 이미지 업로드
                    SwiftSpinner.show("프로필 이미지를 전송하고 있습니다...")
                    uploadUserProfileImage(images: images, user: user)
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
                    
                    let images = [
                        ImageWithName(name: "\(user.uid)/thumb_\(user.uid)", image: userProfileThumbnail, fileExt: "jpg"),
                        ImageWithName(name: "\(user.uid)/original_\(user.uid)", image: image, fileExt: "jpg")
                    ]
                    
                    // 이미지 업로드
                    SwiftSpinner.show("프로필 이미지를 전송하고 있습니다...")
                    uploadUserProfileImage(images: images, user: user)
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
            
            SwiftSpinner.show("회원 정보를 전송하고 있습니다...")
            
            // 추가 정보 입력
            let interesting = selectedInteresting ?? "None"
            let nickname = txfNickname.text ?? "None"
            
            ref.child("users").child(user.uid).child("interesting").setValue(interesting)
            ref.child("users").child(user.uid).child("nickname").setValue(nickname)
            
            let images = [
                ImageWithName(name: "\(user.uid)/thumb_\(user.uid)", image: userProfileThumbnail, fileExt: "jpg"),
                ImageWithName(name: "\(user.uid)/original_\(user.uid)", image: image, fileExt: "jpg")
            ]
            
            // 이미지 업로드
            SwiftSpinner.show("프로필 이미지를 전송하고 있습니다...")
            uploadUserProfileImage(images: images, user: user)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func loadExistingUserInfo() {
        if pageMode == .updateMode {
            // 회원 정보 불러오기
            guard let userUID = getCurrentUserUID() else {
                return
            }
            guard let user = getCurrentUser() else {
                return
            }
            
            txtUserEmail.text = user.email
            txtUserEmail.isEnabled = false
            
            ref.child("users/\(userUID)").getData { error, snapshot in
                if let error = error {
                    print("get user information failed:", error.localizedDescription)
                    return
                }
                
                if snapshot.exists() {
                    let dict = snapshot.value as? [String: String]
                    
                    if let interesting = dict["interesting"] as? String {
                        let index = self.interestingList.firstIndex(of: interesting) ?? 0
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
                
                SwiftSpinner.show("기존 프로필 이미지를 불러오는 중입니다.")
                guard let url = url else {
                    return
                }
                self.imgProfilePicture.kf.setImage(with: url, placeholder: nil, options: nil) { result in
                    self.userImage = self.imgProfilePicture.image
                    SwiftSpinner.hide(nil)
                }
            } failedHandler: { error in
                SwiftSpinner.show(duration: 1.5, title: "기존 프로필 이미지를 불러오기가 실패했습니다.", animated: false, completion: nil)
            }
        }
    }
    
    func uploadUserProfileImage(images: [ImageWithName], user: User) {
        startUploading(images: images, childRefPath: "images/users") {
            
            SwiftSpinner.hide(nil)
            
            simpleAlert(self, message: "\(user.email!) 님의 \(self.pageMode.rawValue) 완료되었습니다.", title: "완료") { action in
                self.dismiss(animated: true, completion: nil)
                if self.delegate != nil {
                    self.delegate!.didSignUpSuccess(self, isSuccess: true, uid: user.uid)
                }
            }
        }
    }
    
    @IBAction func btnActCancel(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnActReset(_ sender: UIButton) {
        
        txtPassword.text = ""
        txtPasswordConfirm.text = ""
        lblPasswordConfirmed.text = ""
        
        switch pageMode {
        case .signUpMode:
            txtUserEmail.text = ""
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
        
    }
    
    @IBAction func btnActSubmit(_ sender: UIButton) {
        
        switch pageMode {
        case .signUpMode:
            guard let userEmail = txtUserEmail.text,
                  let userPassword = txtPassword.text,
                  let userPasswordConfirm = txtPasswordConfirm.text else {
                return
            }
            
            guard userPassword != ""
                    && userPasswordConfirm != ""
                    && userPassword == userPasswordConfirm else {
                simpleAlert(self, message: "패스워드가 일치하지 않습니다.")
                return
            }
            
            sendInfoToFirebase(withEmail: userEmail, password: userPassword)
        case .updateMode:
            guard let user = getCurrentUser() else {
                return
            }
            guard let newPassword = txtPassword.text,
                  let newPasswordConfirm = txtPasswordConfirm.text else {
                      return
                  }
            
            // 비빌번호를 두 쪽 다 입력한 때
            if newPassword != "" || newPasswordConfirm != "" {
                guard newPassword == newPasswordConfirm else {
                    simpleAlert(self, message: "패스워드가 일치하지 않습니다.")
                    return
                }
                sendInfoToFirebase(withEmail: user.email!, password: newPassword)
            } else {
                // 비밀번호가 입력되지 않은 때
                sendInfoToFirebaseOnlyAdditionalInfo()
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

extension SignUpViewController {
    
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

extension SignUpViewController: UIPickerViewDelegate, UIPickerViewDataSource {
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

extension SignUpViewController: UITextFieldDelegate {
    
    func setLabelPasswordConfirm(_ password: String, _ passwordConfirm: String)  {
        
        guard passwordConfirm != "" else {
            lblPasswordConfirmed.text = ""
            return
        }
        
        if password == passwordConfirm {
            lblPasswordConfirmed.textColor = .green
            lblPasswordConfirmed.text = "패스워드가 일치합니다."
        } else {
            lblPasswordConfirmed.textColor = .red
            lblPasswordConfirmed.text = "패스워드가 일치하지 않습니다."
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        switch textField {
        case txtUserEmail:
            txtPassword.becomeFirstResponder()
        case txtPassword:
            txtPasswordConfirm.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == txtPasswordConfirm {
            guard let password = txtPassword.text,
                  let passwordConfirmBefore = txtPasswordConfirm.text else {
                return true
            }
            let passwordConfirm = string.isEmpty ? passwordConfirmBefore[0..<(passwordConfirmBefore.count - 1)] : passwordConfirmBefore + string
            setLabelPasswordConfirm(password, passwordConfirm)
            
        }
        return true
    }
}

extension SignUpViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    /*
     var imagePickerController = UIImagePickerController()
     var userProfileThumbnail: UIImage!
     
     // 사진: 이미지 피커에 딜리게이트 생성
     imagePickerController.delegate = self
     */
    
    func takePhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            self.imagePickerController.sourceType = .camera
            if doTaskByCameraAuthorization(self) {
                present(self.imagePickerController, animated: true, completion: nil)
            }
        } else {
            simpleAlert(self, message: "카메라 사용이 불가능합니다.")
        }
    }
    
    func getPhotoFromLibrary() {
        self.imagePickerController.sourceType = .photoLibrary
        if doTaskByPhotoAuthorization(self) {
            present(self.imagePickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imgProfilePicture.image = image
        }
        
        dismiss(animated: true, completion: nil)
    }
}
