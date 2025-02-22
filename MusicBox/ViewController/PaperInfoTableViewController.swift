//
//  PaperInfoTableViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/26.
//

import UIKit
import GoogleMobileAds
import SwiftSpinner

class PaperInfoTableViewController: UITableViewController {
  private var bannerView: BannerView!
  private var interstitial: InterstitialAd?
  
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
  @IBOutlet weak var btnExportAsPNG: UIButton!
  @IBOutlet weak var btnExportAsPDF: UIButton!
  @IBOutlet weak var btnExportAsMP3: UIButton!
  
  @IBOutlet weak var btnPreplay: UIButton!
  var midiManager = MIDIManager()
  
  private var exportFileURL: URL?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    print("PaperInfoTableViewController viewdidload start", Date().timeIntervalSince1970)
    self.title = selectedDocument?.fileURL.lastPathComponent
    initPaperInfo()
    initButtonsAppearance()
    
    // ====== 광고 ====== //
    TrackingTransparencyPermissionRequest()
    if AdManager.isReallyShowAd {
      bannerView = setupBannerAds(self, adUnitID: AdInfo.shared.fileBrowser)
      bannerView.delegate = self
    }
    
    SwiftSpinner.hide()
    print("PaperInfoTableViewController viewdidload end", Date().timeIntervalSince1970)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    midiManager.midiPlayer?.stop()
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    bannerView?.fitInView(self)
  }
  
  private func initButtonsAppearance() {
    
    let leftMargin: CGFloat = 3
    
    if #available(iOS 15.0, *) {
      btnShare.configuration?.imagePadding = leftMargin
      btnUpdateInformation.configuration?.imagePadding = leftMargin
      btnEditPaper.configuration?.imagePadding = leftMargin
      btnViewMode.configuration?.imagePadding = leftMargin
      btnExportAsPNG.configuration?.imagePadding = leftMargin
      btnExportAsPDF.configuration?.imagePadding = leftMargin
      btnExportAsMP3.configuration?.imagePadding = leftMargin
    } else {
      // Fallback on earlier versions
      btnShare.titleEdgeInsets.left = leftMargin
      btnUpdateInformation.titleEdgeInsets.left = leftMargin
      btnEditPaper.titleEdgeInsets.left = leftMargin
      btnViewMode.titleEdgeInsets.left = leftMargin
      btnExportAsPNG.titleEdgeInsets.left = leftMargin
      btnExportAsPDF.titleEdgeInsets.left = leftMargin
      btnExportAsMP3.titleEdgeInsets.left = leftMargin
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
      simpleAlert(self, message: "Editing is not possible because the creator did not allow editing.".localized, title: "Cannot Edit".localized, handler: nil)
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
  
  @IBAction func btnActExport(_ sender: UIButton) {
    switch sender.tag {
    case 0:
      exportPaperAsPNG()
    case 1:
      exportPaperAsPDF()
    case 2:
      exportPaperAsAudio()
    default:
      break
    }
  }
  
  
  @IBAction func btnActDeleteFile(_ sender: Any) {
    simpleDestructiveYesAndNo(self, message: "Are you sure you want to delete the file? Deleted files cannot be recovered.".localized, title: "Delete the File".localized
    ) { action in
      guard let selectedDocument = self.selectedDocument else {
        return
      }
      
      do {
        try FileManager.default.removeItem(at: selectedDocument.fileURL)
        simpleAlert(self, message: "The file has been deleted.".localized, title: "Delete Completed".localized) { action in
          self.navigationController?.popViewController(animated: true)
        }
      } catch {
        simpleAlert(self, message: "Failed to delete. \(error.localizedDescription)")
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
    guard let selectedDocument else {
      return
    }
    
    SwiftSpinner.show("Drawing the paper...".localized)
    let musicPaperVC = mainStoryboard.instantiateViewController(withIdentifier: "MusicPaperViewController") as! MusicPaperViewController
    
    selectedDocument.open { success in
      if success {
        musicPaperVC.document = selectedDocument
        musicPaperVC.delegate = self
        musicPaperVC.mode = mode
        self.present(musicPaperVC, animated: true, completion: nil)
      } else {
        simpleAlert(self, message: "The paper file is missing or corrupted.".localized, title: "Cannot Open File".localized, handler: nil)
      }
    }
  }
  
  private func exportPaperAsPNG() {
    
  }
  
  private func exportPaperAsPDF() {
    
  }
  
  private func exportPaperAsAudio() {
    // 1️⃣ WAV 파일을 저장할 임시 경로 설정
    let tempDir = FileManager.default.temporaryDirectory
    exportFileURL = tempDir.appendingPathComponent("exported_audio.wav")
    
    /*
     
     */
    
    guard let data = midiManager.musicSequenceToData(sequence: midiManager.musicSequence) else {
      print("midi data is nil")
      return
    }

    // guard let url = Bundle.main.url(forResource: "Allian1", withExtension: "mid"),
    //       let data = try? Data(contentsOf: url) else {
    //   return
    // }
    
    // // 3️⃣ UIActivityViewController를 통해 공유
    // try? data.write(to: exportFileURL!)
    // let activityVC = UIActivityViewController(activityItems: [exportFileURL!], applicationActivities: nil)
    // 
    // // 4️⃣ iPad에서 팝업이 제대로 뜨도록 설정 (iPad 대응)
    // if let topVC = UIApplication.shared.keyWindow?.rootViewController {
    //   activityVC.popoverPresentationController?.sourceView = topVC.view
    //   activityVC.popoverPresentationController?.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
    //   activityVC.popoverPresentationController?.permittedArrowDirections = []
    //   topVC.present(activityVC, animated: true, completion: nil)
    // }
    
    do {
      let bouncer = try MIDIFileBouncer(
        midiFileData: data,
        soundfontURL: SOUNDBANK_URL!
      )
      
      bouncer.delegate = self
      
      DispatchQueue.global(qos: .background).async {
        try? bouncer.bounce(to: self.exportFileURL!)
      }
    } catch {
      print("bouncer error:", error)
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

extension PaperInfoTableViewController: BannerViewDelegate {
  func bannerViewDidReceiveAd(_ bannerView: BannerView) {}
}

extension PaperInfoTableViewController: MIDIFileBouncerDelegate {
  func bounceProgress(progress: Double, currentTime: TimeInterval) {
    print(#function, progress, currentTime)
    
    SwiftSpinner.show(progress: progress / 100.0, title: "Converting...")
  }
  
  func bounceError(error: MIDIBounceError) {
    print(#function, error)
  }
  
  func bounceCompleted() {
    print(#function)
    SwiftSpinner.hide()
    
    guard let exportFileURL else {
      print("exportFileURL is nil")
      return
    }
    
    // 3️⃣ UIActivityViewController를 통해 공유
    let activityVC = UIActivityViewController(
      activityItems: [exportFileURL],
      applicationActivities: nil
    )
    
    // 4️⃣ iPad에서 팝업이 제대로 뜨도록 설정 (iPad 대응)
    if let topVC = UIApplication.shared.keyWindow?.rootViewController {
      activityVC.popoverPresentationController?.sourceView = topVC.view
      activityVC.popoverPresentationController?.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
      activityVC.popoverPresentationController?.permittedArrowDirections = []
      topVC.present(activityVC, animated: true, completion: nil)
    }
  }
}
