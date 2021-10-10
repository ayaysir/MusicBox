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
    
    var selectedDocument: PaperDocument!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "SelectAFileSegue" {
            let controller = segue.destination as? SelectAFileViewController
            controller?.delegate = self
        }
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
        SwiftSpinner.show("uploading...")
        ref.setValue(post.dictionary) { error, ref in
            if let error = error {
                simpleAlert(self, message: error.localizedDescription)
                return
            }
            
            FirebaseFileManager.shared.setChild("musicbox/\(postIdStr)")
            do {
                let fileData = try Data(contentsOf: self.selectedDocument.fileURL)
                FirebaseFileManager.shared.upload(data: fileData, withName: "\(originalFileNameWithoutExt).musicbox") { url in
                    SwiftSpinner.hide(nil)
                    if url != nil {
                        simpleAlert(self, message: "업로드가 완료되었습니다.", title: "업로드 완료") { action in
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
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
    }
    
    
}
