//
//  CreateNewPaperTableViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/22.
//

import UIKit

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
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        let selectedRow = pkvBpmNote.selectedRow(inComponent: 0)
        convertTempoWithLabelChange(tempo: textField.text, noteDivision: noteRatio[selectedRow])
    }

    @IBAction func btnActCreateNewPaper(_ sender: Any) {
        if delegate != nil {
            guard let bpmStr = lblConvertedBPM.text,
                  let title = txfTitle.text,
                  let fileName = txfFileName.text,
                  
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
            
//            self.dismiss(animated: true, completion: nil)
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
    
}
