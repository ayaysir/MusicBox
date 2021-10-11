//
//  SignUpViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/11.
//

import UIKit
import Firebase
import Photos

protocol SignUpDelegate: AnyObject {
    func didSignUpSuccess (_ controller: SignUpViewController, isSuccess: Bool, uid: String)
}

class SignUpViewController: UIViewController {

    @IBOutlet weak var txtUserEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtPasswordConfirm: UITextField!
    @IBOutlet weak var lblPasswordConfirmed: UILabel!
    @IBOutlet weak var pkvInteresting: UIPickerView!
    @IBOutlet weak var imgProfilePicture: UIImageView!
    
    weak var delegate: SignUpDelegate?
    
    var ref: DatabaseReference!
    
    let interestingList = ["치킨", "피자", "탕수육"]
    var selectedInteresting: String!
    
    var imagePickerController = UIImagePickerController()
    var userProfileThumbnail: UIImage!
    
    /// Here is the completion block
    typealias FileCompletionBlock = () -> Void
    var block: FileCompletionBlock?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 피커뷰 딜리게이트, 데이터소스 연결
        pkvInteresting.delegate = self
        pkvInteresting.dataSource = self
        
        txtUserEmail.delegate = self
        txtPassword.delegate = self
        txtPasswordConfirm.delegate = self
        
        // firebase reference 초기화
        ref = Database.database().reference()
        
        selectedInteresting = interestingList[0]
        lblPasswordConfirmed.text = ""
        
        // 사진, 카메라 권한 (최초 요청)
        PHPhotoLibrary.requestAuthorization { status in
        }
        AVCaptureDevice.requestAccess(for: .video) { granted in
        }
        
        // 사진: 이미지 피커에 딜리게이트 생성
        imagePickerController.delegate = self
        
        // 최초 섬네일 생성
        do {
            userProfileThumbnail = try resizeImage(image: #imageLiteral(resourceName: "sample"), maxSize: 200)
        } catch {
            print(error)
        }
        

    }
    
    func sendVerificationMail(authUser: User?) {
        if authUser != nil && authUser!.isEmailVerified == false {
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
        Auth.auth().createUser(withEmail: userEmail, password: userPassword) { [self] authResult, error in
            // 이메일, 비밀번호 전송
            guard let user = authResult?.user, error == nil else {
                simpleAlert(self, message: error!.localizedDescription)
                return
            }
            
            // 이메일 인증 요청
            sendVerificationMail(authUser: user)
            
            // 추가 정보 입력
            ref.child("users").child(user.uid).setValue(["interesting": selectedInteresting])
            
            do {
                let image = try resizeImage(image: imgProfilePicture.image!, maxSize: 1020)
                
                let images = [
                    ImageWithName(name: "\(user.uid)/thumb_\(user.uid)", image: userProfileThumbnail, fileExt: "jpg"),
                    ImageWithName(name: "\(user.uid)/original_\(user.uid)", image: image, fileExt: "png")
                ]
                startUploading(images: images) {
                    simpleAlert(self, message: "\(user.email!) 님의 회원가입이 완료되었습니다.", title: "완료") { action in
                        self.dismiss(animated: true, completion: nil)
                        if delegate != nil {
                            delegate!.didSignUpSuccess(self, isSuccess: true, uid: user.uid)
                        }
                    }
                }
            } catch {
                print(error)
                return
            }
            
            // 이미지 업로드
            
        }
    }
    
    @IBAction func btnActCancel(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnActReset(_ sender: UIButton) {
        txtUserEmail.text = ""
        txtPassword.text = ""
        txtPasswordConfirm.text = ""
        lblPasswordConfirmed.text = ""
        pkvInteresting.selectedRow(inComponent: 0)
        // -- 사진 초기화 --
    }
    
    @IBAction func btnActSubmit(_ sender: UIButton) {
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
    }
    
    @IBAction func btnActTakePhoto(_ sender: UIButton) {
        takePhoto()
    }
    
    @IBAction func btnActFromLoadPhoto(_ sender: UIButton) {
        getPhotoFromLibrary()
    }
    
    
}

extension SignUpViewController {
    
    func startUploading(images: [ImageWithName], completion: @escaping FileCompletionBlock) {
        if images.count == 0 {
            completion()
            return;
        }
        
        block = completion
        uploadImage(forIndex: 0, images: images)
    }
    
    private func uploadImage(forIndex index:Int, images: [ImageWithName]) {
        
        if index < images.count {
            /// Perform uploading
            
            let imageInfo = images[index]
            let name = imageInfo.name
            let image = imageInfo.image
            let fileExt = imageInfo.fileExt
            let quality = imageInfo.compressionQuality
            
            guard let data = fileExt == "jpg"
                    ? image.jpegData(compressionQuality: quality)
                    : image.pngData() else {
                return
            }
            
            let fileName = "\(name).\(fileExt)"
            
            FirebaseFileManager.shared.setChild("images/users")
            FirebaseFileManager.shared.upload(data: data, withName: fileName, block: { (url) in
                /// After successfully uploading call this method again by increment the **index = index + 1**
                print(url ?? "Couldn't not upload. You can either check the error or just skip this.")
                self.uploadImage(forIndex: index + 1, images: images)
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
            do {
                try userProfileThumbnail = resizeImage(image: image, maxSize: 200)
            } catch {
                userProfileThumbnail = image
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
}
