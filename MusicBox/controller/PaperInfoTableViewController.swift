//
//  PaperInfoTableViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/26.
//

import UIKit

class PaperInfoTableViewController: UITableViewController {
    
    var selectedDocument: PaperDocument?
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblArtist: UILabel!
    @IBOutlet weak var lblBpmAndTimeSignature: UILabel!
    @IBOutlet weak var lblSequenceTime: UILabel!
    
    @IBOutlet weak var btnPreplay: UIButton!
    var midiManager = MIDIManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = selectedDocument?.fileURL.lastPathComponent
        initPaperInfo()
    }
    
    func initPaperInfo() {
        guard let paper = selectedDocument?.paper else {
            return
        }
        
        midiManager.currentBPM = paper.bpm
        
        let sequence = midiManager.convertPaperToMIDI(paperCoords: paper.coords)
        midiManager.musicSequence = sequence
        btnPreplay.setTitle("", for: .normal)

        lblTitle.text = paper.title
        lblArtist.text = paper.originalArtist
        
        let bpmAndTSText = "BPM \(paper.bpm), \(paper.timeSignature.upper) / \(paper.timeSignature.lower) "
        lblBpmAndTimeSignature.text = bpmAndTSText
        
        lblSequenceTime.text = convertTimeToFormattedString(timeInterval: midiManager.midiPlayer?.duration ?? 0)
    }
    
    @IBAction func btnActEditPaper(_ sender: Any) {
        openPaper(mode: .edit)
    }
    
    @IBAction func btnActUpdatePaperinfo(_ sender: Any) {
        
        guard let paper = selectedDocument?.paper else {
            return
        }
        
        guard paper.isAllowOthersToEdit && paper.firebaseUID == getCurrentUserUID() else {
            simpleAlert(self, message: "제작자가 편집을 허용하지 않았기 때문에 편집이 불가능합니다.", title: "접근 불가", handler: nil)
            return
        }
        
        guard let updateInfoVC = mainStoryboard.instantiateViewController(withIdentifier: "CreateNewPaperTableViewController") as? CreateNewPaperTableViewController else {
            return
        }
        
        updateInfoVC.pageMode = .update
        updateInfoVC.updateDelegate = self
        updateInfoVC.document = selectedDocument
        self.navigationController?.pushViewController(updateInfoVC, animated: true)
    }
    
    @IBAction func btnActListenPaper(_ sender: Any) {
        openPaper(mode: .view)
    }
    
    @IBAction func btnActDeleteFile(_ sender: Any) {
        simpleDestructiveYesAndNo(self, message: "정말 파일을 삭제하시겠습니까? 삭제된 파일은 복구할 수 없습니다.", title: "파일 삭제") { action in
            guard let selectedDocument = self.selectedDocument else {
                return
            }
            
            do {
                try FileManager.default.removeItem(at: selectedDocument.fileURL)
                simpleAlert(self, message: "삭제되었습니다.", title: "삭제 완료") { action in
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                simpleAlert(self, message: "삭제하지 못했습니다. \(error.localizedDescription)")
                return
            }
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
    
    private func openPaper(mode: MusicPaperMode) {
        guard let document = selectedDocument else {
            return
        }
        
        let musicPaperVC = mainStoryboard.instantiateViewController(withIdentifier: "MusicPaperViewController") as! MusicPaperViewController
        
        document.open { success in
            if success {
                musicPaperVC.document = document
                musicPaperVC.delegate = self
                musicPaperVC.mode = mode
                self.present(musicPaperVC, animated: true, completion: nil)
            } else {
                simpleAlert(self, message: "파일이 없거나 손상되었습니다.", title: "파일을 열 수 없음", handler: nil)
            }
        }
    }
}

extension PaperInfoTableViewController: UpdateDocumentVCDelegate {
    func didDocumentUpdated(_ controller: CreateNewPaperTableViewController, updatedDocument: PaperDocument) {
        selectedDocument = updatedDocument
        initPaperInfo()
    }
}

extension PaperInfoTableViewController: MusicPaperVCDelegate {
    func didPaperEditFinished(_ controller: MusicPaperViewController) {
        selectedDocument = controller.document
        initPaperInfo()
    }
}
