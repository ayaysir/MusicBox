//
//  CreateNewPaperTableViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/22.
//

import UIKit
import SwiftSpinner

let noteNames = [
    "note_sixteenth",
    "note_dotted_sixteenth",
    "note_eighth",
    "note_dotted_eighth",
    "note_quarter",
    "note_dotted_quarter",
    "note_half",
    "note_dotted_half",
    "note_whole"
]

let noteRatio = [
    16,
    12,
    8,
    6,
    4,
    3,
    2,
    1.5,
    1
]

protocol CreateNewPaperVCDelegate: AnyObject {
    func didNewPaperCreated(_ controller: CreateNewPaperTableViewController, newPaper: Paper, fileNameWithoutExt: String)
}

class CreateNewPaperTableViewController: UITableViewController {
    
    weak var delegate: CreateNewPaperVCDelegate?
    
    @IBOutlet weak var txfFileName: UITextField!
    @IBOutlet weak var txfTitle: UITextField!
    @IBOutlet weak var txfBpm: UITextField!
    @IBOutlet weak var txfIncompleteMeasureBeat: UITextField!
    @IBOutlet weak var txfOriginalArtist: UITextField!
    @IBOutlet weak var txfPaperMaker: UITextField!
    @IBOutlet weak var lblConvertedBPM: UILabel!
    @IBOutlet weak var txvComment: UITextView!
    
    @IBOutlet weak var imgAlbumart: UIImageView!
    var thumbnailImage: UIImage?
    
    @IBOutlet weak var pkvBpmNote: UIPickerView!
    @IBOutlet weak var pkvTimeSignature: UIPickerView!
    
    var imagePickerController = UIImagePickerController()
    
    let upperListTS = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 15, 16]
    let lowerListTS = [2, 4, 8, 16]
    
    var selectedUpperTS: Int = 4
    var selectedLowerTS: Int = 4
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        txfBpm.delegate = self
        txfIncompleteMeasureBeat.delegate = self
        
        pkvBpmNote.delegate = self
        pkvBpmNote.dataSource = self
        pkvBpmNote.selectRow(4, inComponent: 0, animated: false)
        convertTempoWithLabelChange(tempo: 120, noteDivision: noteRatio[4])
        
        pkvTimeSignature.delegate = self
        pkvTimeSignature.dataSource = self
        pkvTimeSignature.selectRow(2, inComponent: 0, animated: false)
        pkvTimeSignature.selectRow(1, inComponent: 2, animated: false)

        imagePickerController.delegate = self
        
        txfBpm.delegate = self
        txfBpm.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        do {
            try thumbnailImage = resizeImage(image: imgAlbumart.image!, maxSize: 200)
        } catch  {
            print(error)
            thumbnailImage = imgAlbumart.image!
        }
        
        if getCurrentUser() != nil, let userUID = getCurrentUserUID() {
            SwiftSpinner.show("Load user's nickname...")
            getDatabaseRef().child("users/\(userUID)/nickname").getData { error, snapshot in
                SwiftSpinner.hide(nil)
                
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                self.txfPaperMaker.text = (snapshot.value as? String)
            }
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        let selectedRow = pkvBpmNote.selectedRow(inComponent: 0)
        convertTempoWithLabelChange(tempo: textField.text, noteDivision: noteRatio[selectedRow])
    }

    @IBAction func btnActCreateNewPaper(_ sender: Any) {
        if delegate != nil {
            
            // 유효성 검사
            guard validateFieldValues() else {
                return
            }
            
            guard let bpmStr = lblConvertedBPM.text,
                  let title = txfTitle.text,
                  let fileName = txfFileName.text,
                  let comment = txvComment.text,
                  let originalArtist = txfOriginalArtist.text,
                  let paperMaker = txfPaperMaker.text else {
                      print("string is nil")
                      return
                  }
            
            guard let bpm = Double(bpmStr) else {
                print("cannot convert string to integer.")
                return
            }
            
            let imBeat = Int(txfIncompleteMeasureBeat.text!) ?? 0
            
            let timeSignature = TimeSignature(upper: selectedUpperTS, lower: selectedLowerTS)
        
            let paper = Paper(bpm: bpm, coords: [], timeSignature: TimeSignature())
            
            paper.title = title
            paper.incompleteMeasureBeat = imBeat
            paper.originalArtist = originalArtist
            paper.paperMaker = paperMaker
            paper.timeSignature = timeSignature
            paper.comment = comment
            
            if let albumartImage = imgAlbumart.image {
                do {
                    let resized = try resizeImage(image: albumartImage, maxSize: 1020)
                    paper.albumartImageData = resized.jpegData(compressionQuality: 1)
                } catch {
                    print(error)
                }
            }
            
            if let thumbnailImage = thumbnailImage {
                paper.thumbnailImageData = thumbnailImage.jpegData(compressionQuality: 1)
            }
            
            if let firebaseUID = getCurrentUserUID() {
                paper.firebaseUID = firebaseUID
            }
             
            delegate?.didNewPaperCreated(self, newPaper: paper, fileNameWithoutExt: fileName)
            
            self.navigationController?.popViewController(animated: true)
        } else {
            print("CreateNewPaperVCDelegate is nil.")
        }
    }
    
    @IBAction func btnActCamera(_ sender: Any) {
        takePhoto()
    }
    
    @IBAction func btnActPhotoLibrary(_ sender: Any) {
        getPhotoFromLibrary()
    }
    
    
//    @IBAction func btnActDismiss(_ sender: Any) {
//        self.dismiss(animated: true, completion: nil)
//    }
    
    func convertTempoWithLabelChange(tempo: Double, noteDivision: Double) {
        let bpm = convertTempoToBaseQuarterNoteBPM(tempo: tempo, noteDivision: noteDivision)
        lblConvertedBPM.text = "\(bpm)"
    }
    
    func convertTempoWithLabelChange(tempo: String?, noteDivision: Double) {
        guard let tempoStr = tempo else {
            return
        }
        guard let tempoDouble = Double(tempoStr) else {
            return
        }
        convertTempoWithLabelChange(tempo: tempoDouble, noteDivision: noteDivision)
    }
    
    func validateFieldValues() -> Bool {
        // file name
        guard txfFileName.text != "" else {
            simpleAlert(self, message: "파일 이름을 입력해야 합니다.", title: "만들 수 없음") { action in
                self.txfFileName.becomeFirstResponder()
            }
            
            return false
        }
        
        let regex = "^[^<>:;,?\"*|/]+$"
        guard txfFileName.text?.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil else {
            simpleAlert(self, message: "파일 이름 형식이 잘못되었습니다. 파일명을 다시 작성해주세요.", title: "만들 수 없음") { action in
                self.txfFileName.becomeFirstResponder()
            }
            return false
        }
        
        // title
        guard txfTitle.text! != "" else {
            simpleAlert(self, message: "제목을 입력해야 합니다.", title: "만들 수 없음") { action in
                self.txfTitle.becomeFirstResponder()
            }
            return false
        }
        
        guard txfTitle.text!.count <= 50 else {
            simpleAlert(self, message: "제목은 50자 이내로 작성해야 합니다.", title: "만들 수 없음") { action in
                self.txfTitle.becomeFirstResponder()
            }
            return false
        }
        
        // bpm
        guard let bpm = Double(txfBpm.text!) else {
            return false
        }
        guard bpm >= 10 && bpm <= 400 else {
            simpleAlert(self, message: "BPM은 10 - 400의 범위 내에서만 지정해야 합니다.", title: "만들 수 없음") { action in
                self.txfBpm.becomeFirstResponder()
            }
            return false
        }
        
        // incomplete measure
        guard let imBeat = Int(txfIncompleteMeasureBeat.text!) else {
            return false
        }
        guard imBeat >= 0 && imBeat <= 7 else {
            simpleAlert(self, message: "못갖춘마디는 16분음표에 해당하는 길이의 비트를 0 - 7 범위 내에서 지정해야 합니다.", title: "만들 수 없음") { action in
                self.txfIncompleteMeasureBeat.becomeFirstResponder()
            }
            return false
        }
        
        // original artist, paper maker
        guard txfOriginalArtist.text! != "" else {
            simpleAlert(self, message: "아티스트 이름을 입력해야 합니다.", title: "만들 수 없음") { action in
                self.txfOriginalArtist.becomeFirstResponder()
            }
            return false
        }
        
        guard txfOriginalArtist.text!.count <= 30 else {
            simpleAlert(self, message: "아티스트 이름은 30자 이내로 작성해야 합니다.", title: "만들 수 없음") { action in
                self.txfOriginalArtist.becomeFirstResponder()
            }
            return false
        }
        
        guard txfPaperMaker.text!.count <= 30 else {
            simpleAlert(self, message: "페이퍼 작성자 이름은 30자 이내로 작성해야 합니다.", title: "만들 수 없음") { action in
                self.txfPaperMaker.becomeFirstResponder()
            }
            return false
        }
        
        // comment
        guard txvComment.text!.count <= 5000 else {
            simpleAlert(self, message: "페이퍼 작성자 이름은 5000자 이내로 작성해야 합니다.", title: "만들 수 없음") { action in
                self.txvComment.becomeFirstResponder()
            }
            return false
        }

        return true
    }
}

extension CreateNewPaperTableViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        switch pickerView {
        case pkvBpmNote:
            return 1
        case pkvTimeSignature:
            return 3
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if pickerView == pkvBpmNote {
            return noteNames.count
        } else {
            switch component {
            case 0:
                return upperListTS.count
            case 1:
                return 1
            case 2:
                return lowerListTS.count
            default:
                return 0
            }
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        if pickerView == pkvBpmNote {
            guard let noteImage = UIImage(named: noteNames[row]) else {
                return UIImageView()
            }
            
            let imageView = UIImageView(image: noteImage)
            
            if noteNames[row] != "note_whole" {
                let height: CGFloat = 25
                let width: CGFloat = height * (noteImage.size.width / noteImage.size.height)
                imageView.frame = CGRect(x: 0, y: 0, width: width, height: height)
            } else {
                // h/w = 0.5643
                let width: CGFloat = 12.5
                imageView.frame = CGRect(x: 0, y: 0, width: width, height: width * 0.5643)
            }
            
            return imageView
        } else {
            
            let label = UILabel()
            label.textAlignment = .center
            
            switch component {
            case 0:
                label.text = "\(upperListTS[row])"
            case 1:
                label.text = "/"
            case 2:
                label.text = "\(lowerListTS[row])"
            default:
                break
            }
            
            return label
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if pickerView == pkvBpmNote {
            print(row, component)
            guard let bpmStr = txfBpm.text else {
                return
            }
            guard let tempo = Double(bpmStr) else {
                return
            }
            
            convertTempoWithLabelChange(tempo: tempo, noteDivision: noteRatio[row])
            
        } else {
            switch component {
            case 0:
                selectedUpperTS = upperListTS[row]
            case 2:
                selectedLowerTS = lowerListTS[row]
            default:
                break
            }
        }
    }
    
}

extension CreateNewPaperTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    /*
     import Photos
     
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
            imgAlbumart.image = image
            do {
                try thumbnailImage = resizeImage(image: image, maxSize: 200)
            } catch {
                print(error)
                thumbnailImage = image
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
}

extension CreateNewPaperTableViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        switch textField {
        case txfBpm:
            let allowedCharacters = CharacterSet(charactersIn: "1234567890.")
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        case txfIncompleteMeasureBeat:
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        default:
            break
        }
        
        return true
    }
}
