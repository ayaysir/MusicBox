//
//  PaperInfoTableViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/26.
//

import UIKit
import GoogleMobileAds

class PaperInfoTableViewController: UITableViewController {
    
    private var bannerView: GADBannerView!
    
    var selectedDocument: PaperDocument?
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblArtist: UILabel!
    @IBOutlet weak var lblBpmAndTimeSignature: UILabel!
    @IBOutlet weak var lblSequenceTime: UILabel!
    @IBOutlet weak var imgAlbumart: UIImageView!
    
    @IBOutlet weak var btnEditPaper: UIButton!
    @IBOutlet weak var btnUpdateInformation: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var btnViewMode: UIButton!
    
    @IBOutlet weak var btnPreplay: UIButton!
    var midiManager = MIDIManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = selectedDocument?.fileURL.lastPathComponent
        initPaperInfo()
        initButtonsAppearance()
        
        // ====== 광고 ====== //
        if AdManager.productMode {
            bannerView = setupBannerAds(self, adUnitID: AdInfo.shared.fileBrowser)
            bannerView.delegate = self
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        midiManager.midiPlayer?.stop()
    }
    
    private func initButtonsAppearance() {
        
        let leftMargin: CGFloat = 3
        
        if #available(iOS 15.0, *) {
            btnShare.configuration?.imagePadding = leftMargin
            btnUpdateInformation.configuration?.imagePadding = leftMargin
            btnEditPaper.configuration?.imagePadding = leftMargin
            btnViewMode.configuration?.imagePadding = leftMargin
            
        } else {
            // Fallback on earlier versions
            btnShare.titleEdgeInsets.left = leftMargin
            btnUpdateInformation.titleEdgeInsets.left = leftMargin
            btnEditPaper.titleEdgeInsets.left = leftMargin
            btnViewMode.titleEdgeInsets.left = leftMargin
        }
    }
    
    private func initPaperInfo() {
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
        
        if let imageData = paper.albumartImageData {
            imgAlbumart.image = UIImage(data: imageData)
        }
    }
    
    @IBAction func btnActEditPaper(_ sender: Any) {
        openPaper(mode: .edit)
    }
    
    @IBAction func btnActUpdatePaperinfo(_ sender: Any) {
        
        guard let paper = selectedDocument?.paper else {
            return
        }
        
        guard paper.isAllowOthersToEdit else {
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
    
    @IBAction func btnActShare(_ sender: UIButton) {
        
        let activityViewController = UIActivityViewController(activityItems: [/* Items to be shared, */ selectedDocument!.fileURL, ActionExtensionBlockerItem()], applicationActivities: nil)
        
        // so that iPads won't crash
        if UIDevice.current.userInterfaceIdiom == .pad {
                activityViewController.popoverPresentationController?.sourceView = self.view
            activityViewController.popoverPresentationController?.sourceRect = sender.frame
            }
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [
            .postToVimeo,
            .postToWeibo,
            .postToFlickr,
            .postToTwitter,
            .postToFacebook,
            .postToTencentWeibo,
            UIActivity.ActivityType(rawValue: "com.bgsmm.MusicBox")
        ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
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
    
    @IBAction func btnActPreplay(_ sender: UIButton) {
        if midiManager.midiPlayer!.isPlaying {
            midiManager.midiPlayer?.stop()
        } else {
            sender.setImage(UIImage(systemName: "stop.circle.fill"), for: .normal)
            midiManager.midiPlayer?.play({
                print("midi play finished")
                self.midiManager.midiPlayer?.currentPosition = 0
                DispatchQueue.main.async {
                    sender.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
                }
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

extension PaperInfoTableViewController: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        
    }
}
