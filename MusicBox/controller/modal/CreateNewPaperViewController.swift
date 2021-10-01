//
//  CreateNewPaperViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/01.
//

import UIKit
import PanModal

protocol CreateNewPaperVCDelegate: AnyObject {
    /*
     var bpm: Int = 120
     var coords: [PaperCoord] = []
     var timeSignature: TimeSignature = TimeSignature()
     
     var incompleteMeasureBeat: Int = 0

     var albumartURL: URL?
     var paperMaker: String = ""
     var title: String = "My MusicBox Sheet"
     var originalArtist: String = "J. S. Bach"
     var comment: String = ""
     */
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
            let paper = Paper(bpm: bpm, coords: [], timeSignature: TimeSignature())
            paper.title = title
            paper.incompleteMeasureBeat = imBeat
            paper.originalArtist = originalArtist
            paper.paperMaker = paperMaker
            
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


