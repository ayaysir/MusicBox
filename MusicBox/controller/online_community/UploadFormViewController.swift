//
//  UploadFormViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/09.
//

import UIKit
import Firebase
import SwiftSpinner
import GoogleMobileAds

class UploadFormViewController: UIViewController {
    
    private var bannerView: GADBannerView!
    
    @IBOutlet weak var lblSelectedPaperMaker: UILabel!
    @IBOutlet weak var lblSelectedArtist: UILabel!
    @IBOutlet weak var lblSelectedTitle: UILabel!
    @IBOutlet weak var imgSelectedAlbumart: UIImageView!

    @IBOutlet weak var selectAFileButtonView: UIView!
    
    @IBOutlet weak var txfPostTitle: UITextField!
    @IBOutlet weak var txvPostComment: UITextView!
    @IBOutlet weak var swtPostAllowToEdit: UISwitch!
    
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var btnPreplay: UIButton!
    
    var midiManager = MIDIManager()
    
    var selectedDocument: PaperDocument!
    
    typealias FileCompletionBlock = () -> Void
    var block: FileCompletionBlock?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnPreplay.circleButton = true
        btnPreplay.setTitle("", for: .normal)
        
        txfPostTitle.delegate = self

        bannerView = setupBannerAds(self)
        bannerView.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "SelectAFileSegue" {
            let controller = segue.destination as? SelectAFileViewController
            controller?.delegate = self
        }
    }
    
    @IBAction func btnActPreplay(_ sender: Any) {
        if midiManager.midiPlayer!.isPlaying {
            midiManager.midiPlayer?.stop()
        } else {
            midiManager.midiPlayer?.play({
                print("midi play finished")
                self.midiManager.midiPlayer?.currentPosition = 0
            })
        }
    }
    
    @IBAction func btnActSelectAFile(_ sender: Any) {
        performSegue(withIdentifier: "SelectAFileSegue", sender: nil)
    }
    
    
    @IBAction func btnActReselectAFile(_ sender: Any) {
        performSegue(withIdentifier: "SelectAFileSegue", sender: nil)
    }

    @IBAction func btnActUpload(_ sender: Any) {
        upload()
    }
    
    @IBAction func barBtnActSubmit(_ sender: Any) {
        upload()
    }
    
    private func upload() {
        midiManager.midiPlayer?.stop()
        
        guard let document = selectedDocument, let paper = document.paper else {
            return
        }
        
        guard let currentUID = getCurrentUserUID() else {
            simpleAlert(self, message: "로그인되어 있지 않습니다.")
            return
        }
        
        // 자신이 만든 파일만 업로드되도록
        if paper.firebaseUID != nil && paper.firebaseUID! != currentUID {
            simpleAlert(self, message: "다른 사람이 만든 종이는 올릴 수 없습니다.")
            return
        } else {
            paper.firebaseUID = currentUID
        }
        
        let postTitle = txfPostTitle.text!
        let postComment = txvPostComment.text!
        let paperTitle = lblSelectedTitle.text!
        let paperArtist = lblSelectedArtist.text!
        let paperMaker = lblSelectedPaperMaker.text!
        
        let allowPaperEdit = swtPostAllowToEdit.isOn
        print("allowPaperEdit:", allowPaperEdit)
        
        let writerUID = currentUID
        let originalFileNameWithoutExt = (document.fileURL.lastPathComponent as NSString).deletingPathExtension
        
        let preplayArr: [PaperCoord] = paper.coords
        let bpm: Double = paper.bpm
        
        let likes: [String: Like] = [:]
        
        let post = Post(postTitle: postTitle, postComment: postComment, paperTitle: paperTitle, paperArtist: paperArtist, paperMaker: paperMaker, allowPaperEdit: allowPaperEdit, uploadDate: Date(), writerUID: writerUID, originaFileNameWithoutExt: originalFileNameWithoutExt, preplayArr: preplayArr, bpm: bpm, likes: likes
        )
        
        let postIdStr = post.postId.uuidString
        
        let ref = Database.database().reference(withPath: "community/\(postIdStr)")
        SwiftSpinner.show("글을 등록하고 있습니다...")
        
        let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let targetDocCachePath = cachePath.appendingPathComponent(selectedDocument.fileURL.lastPathComponent)
        let cacheDocument = PaperDocument(fileURL: targetDocCachePath)
        
        paper.isUploaded = true
        paper.isAllowOthersToEdit = allowPaperEdit
        cacheDocument.paper = paper
        
        var postDict = post.dictionary
        if postDict["uploadDate"] != nil {
            postDict["uploadDate"] = ServerValue.timestamp
        }
        ref.setValue(post.dictionary) { error, ref in
            if let error = error {
                simpleAlert(self, message: error.localizedDescription)
                return
            }
            
            self.first_uploadPaper(postIdStr: postIdStr, cacheDocument: cacheDocument)
        }
    }

}

extension UploadFormViewController {
    
    private func first_uploadPaper(postIdStr: String, cacheDocument: PaperDocument) {
        
        cacheDocument.open { success in
            
            cacheDocument.save(to: cacheDocument.fileURL, for: .forOverwriting) { success in
                guard success else { return }
                
                FirebaseFileManager.shared.setChild("musicbox/\(postIdStr)")
                SwiftSpinner.show("종이 파일을 업로드하고 있습니다...")
                do {
                    let fileData = try Data(contentsOf: cacheDocument.fileURL)
                    FirebaseFileManager.shared.upload(data: fileData, withName: cacheDocument.fileURL.lastPathComponent) { url in
                        if url != nil {
                            cacheDocument.close { _ in
                                self.second_uploadThumbnail(postIdStr: postIdStr)
                            }
                        } else {
                            SwiftSpinner.show(duration: 3, title: "오류: 종이 파일이 업로드되지 않았습니다.", animated: false, completion: nil)
                        }
                    }
                } catch {
                    SwiftSpinner.show(error.localizedDescription, animated: false)
                    print(error.localizedDescription)
                }
            }
        }
            
        
        
    }
    
    private func second_uploadThumbnail(postIdStr: String) {
        
        SwiftSpinner.show("앨범아트 섬네일을 업로드하고 있습니다...")
        
        FirebaseFileManager.shared.setChild("PostThumbnail/\(postIdStr)")
        
        guard let image = imgSelectedAlbumart.image else {
            SwiftSpinner.show("이미지 오류", animated: false)
            return
        }
        
        do {
            let imageThumbnail = try resizeImage(image: image, maxSize: 180)
            
            guard let thumbData = imageThumbnail.jpegData(compressionQuality: 0.95) else {
                SwiftSpinner.show("섬네일 오류", animated: false)
                return
            }
            
            FirebaseFileManager.shared.upload(data: thumbData, withName: "\(postIdStr).jpg") { url in
                if url != nil {
                    self.third_uploadFullSizeImage(postIdStr: postIdStr)
                } else {
                    SwiftSpinner.show("섬네일 업로드 에러", animated: false)
                }
            }
        } catch {
            print("thumbnail", error)
            if (error as! ResizeImageError) == .sizeIsTooSmall {
                SwiftSpinner.hide(nil)
                simpleAlert(self, message: "글 작성 및 파일 업로드가 완료되었습니다.", title: "글 등록 완료") { action in
                    self.navigationController?.popViewController(animated: true)
                }
            }
            
        }
       
    }
    
    private func third_uploadFullSizeImage(postIdStr: String) {
        SwiftSpinner.show("앨범아트를 업로드하고 있습니다...")
        
        FirebaseFileManager.shared.setChild("PostAlbumart/\(postIdStr)")
        
        guard let imageData = imgSelectedAlbumart.image?.jpegData(compressionQuality: 1) else {
            SwiftSpinner.show("이미지 오류", animated: false)
            return
        }
        

        FirebaseFileManager.shared.upload(data: imageData, withName: "\(postIdStr).jpg") { url in
            if url != nil {
                SwiftSpinner.hide(nil)
                simpleAlert(self, message: "글 작성 및 파일 업로드가 완료되었습니다.", title: "글 등록 완료") { action in
                    self.navigationController?.popViewController(animated: true)
                }
            } else {
                SwiftSpinner.show("이미지 업로드 에러", animated: false)
            }
        }
    }
}

extension UploadFormViewController: SelectAFileVCDelegate {
    
    func didSelectedAFile(_ controller: SelectAFileViewController, selectedDocument: PaperDocument) {
        
        guard let paper = selectedDocument.paper else {
            return
        }
        
        if let data = paper.albumartImageData {
            imgSelectedAlbumart.image = UIImage(data: data)
        } else {
            imgSelectedAlbumart.image = UIImage(named: "sample")
        }
        
        lblSelectedTitle.text = paper.title
        lblSelectedArtist.text = paper.originalArtist
        lblSelectedPaperMaker.text = paper.paperMaker
        
        selectAFileButtonView.isHidden = true
        self.selectedDocument = selectedDocument
        
        txfPostTitle.text = paper.title
        txvPostComment.text = paper.comment
        
        if midiManager.midiPlayer!.isPlaying {
            midiManager.midiPlayer?.stop()
        }
        
        midiManager.currentBPM = paper.bpm
        let sequence = midiManager.convertPaperToMIDI(paperCoords: paper.coords)
        midiManager.musicSequence = sequence
        
    }
}

extension UploadFormViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case txfPostTitle:
            txvPostComment.becomeFirstResponder()
        default:
            break
        }
        
        return true
    }
}

extension UploadFormViewController: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        scrollViewBottomConstraint.constant += bannerView.adSize.size.height
    }
}
