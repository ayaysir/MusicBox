//
//  UploadFormViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/09.
//

import UIKit
import Firebase
import SwiftSpinner

class UploadFormViewController: UIViewController {
    
    @IBOutlet weak var lblSelectedPaperMaker: UILabel!
    @IBOutlet weak var lblSelectedArtist: UILabel!
    @IBOutlet weak var lblSelectedTitle: UILabel!
    @IBOutlet weak var imgSelectedAlbumart: UIImageView!

    @IBOutlet weak var selectAFileButtonView: UIView!
    
    @IBOutlet weak var txfPostTitle: UITextField!
    @IBOutlet weak var txvPostComment: UITextView!
    @IBOutlet weak var swtPostAllowToEdit: UISwitch!
    
    @IBOutlet weak var btnPreplay: UIButton!
    
    var midiManager = MIDIManager()
    
    var selectedDocument: PaperDocument!
    
    typealias FileCompletionBlock = () -> Void
    var block: FileCompletionBlock?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnPreplay.circleButton = true
        btnPreplay.setTitle("", for: .normal)

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
        let uploadDate = Date()
        
        let writerUID = currentUID
        let originalFileNameWithoutExt = (document.fileURL.lastPathComponent as NSString).deletingPathExtension
        
        var preplayArr: [PaperCoord] {
            if paper.coords.count <= 16 {
                return paper.coords
            } else {
                let coordsCountPercent30 = Int(Double(paper.coords.count) * 0.3)
                return Array(paper.coords[0...coordsCountPercent30])
            }
        }
        let bpm: Int = paper.bpm
        
        let likes: [String] = []
        
        paper.isAllowOthersToEdit = allowPaperEdit
        
        let post = Post(postTitle: postTitle, postComment: postComment, paperTitle: paperTitle, paperArtist: paperArtist, paperMaker: paperMaker, allowPaperEdit: allowPaperEdit, uploadDate: uploadDate, writerUID: writerUID, originaFileNameWithoutExt: originalFileNameWithoutExt, preplayArr: preplayArr, bpm: bpm, likes: likes
        )
        
        let postIdStr = post.postId.uuidString
        
        let ref = Database.database().reference(withPath: "community/\(postIdStr)")
        SwiftSpinner.show("글을 등록하고 있습니다...")
        ref.setValue(post.dictionary) { error, ref in
            if let error = error {
                simpleAlert(self, message: error.localizedDescription)
                return
            }
            
            self.first_uploadPaper(postIdStr: postIdStr, fileName: originalFileNameWithoutExt)
        }
    }

}

extension UploadFormViewController {
    
    private func first_uploadPaper(postIdStr: String, fileName originalFileNameWithoutExt: String) {
        FirebaseFileManager.shared.setChild("musicbox/\(postIdStr)")
        SwiftSpinner.show("종이 파일을 업로드하고 있습니다...")
        do {
            let fileData = try Data(contentsOf: self.selectedDocument.fileURL)
            FirebaseFileManager.shared.upload(data: fileData, withName: "\(originalFileNameWithoutExt).musicbox") { url in
                if url != nil {
                    self.second_uploadThumbnail(postIdStr: postIdStr)
                } else {
                    SwiftSpinner.show("종이 파일 업로드 에러", animated: false)
                }
            }
        } catch {
            SwiftSpinner.show(error.localizedDescription, animated: false)
            print(error.localizedDescription)
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
        
        if paper.title != "" {
            txfPostTitle.text = paper.title
        }
        
        if paper.comment != "" {
            txvPostComment.text = paper.comment
        }
        
        if midiManager.midiPlayer!.isPlaying {
            midiManager.midiPlayer?.stop()
        }
        
        let sequence = midiManager.convertPaperToMIDI(paperCoords: paper.coords)
        midiManager.musicSequence = sequence
        
    }
    
    
}
