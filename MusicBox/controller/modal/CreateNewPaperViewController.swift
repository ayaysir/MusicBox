//
//  CreateNewPaperViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/01.
//

import UIKit
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
    
    @IBOutlet weak var pkvTimeSignature: UIPickerView!
    
    let upperListTS = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 15, 16]
    let lowerListTS = [2, 4, 8, 16]
    
    var selectedUpperTS: Int = 4
    var selectedLowerTS: Int = 4
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pkvTimeSignature.delegate = self
        pkvTimeSignature.dataSource = self
        pkvTimeSignature.selectRow(2, inComponent: 0, animated: false)
        pkvTimeSignature.selectRow(1, inComponent: 2, animated: false)
//        view.backgroundColor = #colorLiteral(red: 0.1019607843, green: 0.1137254902, blue: 0.1294117647, alpha: 1)
        
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
            
            delegate?.didNewPaperCreated(self, newPaper: paper, fileNameWithoutExt: fileName)
            
            self.dismiss(animated: true, completion: nil)
        } else {
            print("CreateNewPaperVCDelegate is nil.")
        }
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


