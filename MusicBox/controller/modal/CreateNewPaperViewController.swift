//
//  CreateNewPaperViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/01.
//

import UIKit
import Photos
import PanModal

protocol CreateNewPaperVCDelegate: AnyObject {
    
    func didNewPaperCreated(_ controller: CreateNewPaperViewController, newPaper: Paper, fileNameWithoutExt: String)
}

class CreateNewPaperViewController: UIViewController {
    
    weak var delegate: CreateNewPaperVCDelegate?
    
    @IBOutlet weak var txfFileName: UITextField!
    @IBOutlet weak var txfTitle: UITextField!
    @IBOutlet weak var txfBpm: UITextField!
    @IBOutlet weak var txfIncompleteMeasureBeat: UITextField!
    @IBOutlet weak var txfOriginalArtist: UITextField!
    @IBOutlet weak var txfPaperMaker: UITextField!
    
    @IBOutlet weak var imgAlbumart: UIImageView!
    var thumbnailImage: UIImage?
    
    @IBOutlet weak var pkvTimeSignature: UIPickerView!
    
    let upperListTS = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 15, 16]
    let lowerListTS = [2, 4, 8, 16]
    
    var selectedUpperTS: Int = 4
    var selectedLowerTS: Int = 4
    
    var imagePickerController = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pkvTimeSignature.delegate = self
        pkvTimeSignature.dataSource = self
        pkvTimeSignature.selectRow(2, inComponent: 0, animated: false)
        pkvTimeSignature.selectRow(1, inComponent: 2, animated: false)

        imagePickerController.delegate = self
        thumbnailImage = resizeImage(image: imgAlbumart.image!, maxSize: 200) ?? imgAlbumart.image!
    }
    
    @IBAction func btnActCreateNewPaper(_ sender: Any) {
        if delegate != nil {
            guard let bpmStr = txfBpm.text,
                  let title = txfTitle.text,
                  let fileName = txfFileName.text,
                  
                  let originalArtist = txfOriginalArtist.text,
                  let paperMaker = txfPaperMaker.text else {
                      print("string is nil")
                      return
                  }
            
            guard let bpm = Int(bpmStr) else {
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
                paper.albumartImageData = albumartImage.jpegData(compressionQuality: 1)
            }
            
            if let thumbnailImage = thumbnailImage {
                paper.thumbnailImageData = thumbnailImage.jpegData(compressionQuality: 1)
            }
             
            delegate?.didNewPaperCreated(self, newPaper: paper, fileNameWithoutExt: fileName)
            
            self.dismiss(animated: true, completion: nil)
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
    
    
    @IBAction func btnActDismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension CreateNewPaperViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        3
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
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
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0:
            return "\(upperListTS[row])"
        case 1:
            return "/"
        case 2:
            return "\(lowerListTS[row])"
        default:
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
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

extension CreateNewPaperViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
            thumbnailImage = resizeImage(image: image, maxSize: 200) ?? image
        }
        
        dismiss(animated: true, completion: nil)
    }
}


extension CreateNewPaperViewController: PanModalPresentable {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    var panScrollable: UIScrollView? {
        return nil
    }

    var longFormHeight: PanModalHeight {
        return .maxHeightWithTopInset(200)
    }

    var anchorModalToLongForm: Bool {
        return false
    }
}


