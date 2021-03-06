//
//  MusicPaperViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/13.
//

import UIKit
import AVFoundation
import SwiftSpinner
import GoogleMobileAds

protocol MusicPaperVCDelegate: AnyObject {
    func didPaperEditFinished(_ controller: MusicPaperViewController)
}

enum MusicPaperMode {
    case edit, view
}

class MusicPaperViewController: UIViewController {
    
    private var bannerView: GADBannerView!
    
    var previousScale: CGFloat = 1.0
    
    var mode: MusicPaperMode = .edit
    weak var delegate: MusicPaperVCDelegate?

    var player: AVAudioPlayer?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var constraintScrollViewBottom: NSLayoutConstraint!
    @IBOutlet weak var musicPaperView: MusicBoxPaperView!
    @IBOutlet weak var constraintMusicPaperWidth: NSLayoutConstraint!
    @IBOutlet weak var constraintMusicPaperHeight: NSLayoutConstraint!
    
    @IBOutlet weak var paperViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var paperViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var paperViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var paperViewTrailingConstraint: NSLayoutConstraint!
    
    // Hide home indicator(아이폰 밑에 있는 막대기)
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    var panelView: PaperOptionPanelView!
    var viewModePanelView: PaperViewModePanelView!
    
    var allowEdit: Bool = true
    var eraserMode: Bool! {
        didSet {
            if eraserMode {
                panelView.btnEraser.setBackgroundImage(UIImage(named: "button border pushed sunset"), for: .normal)
            } else {
                panelView.btnEraser.setBackgroundImage(UIImage(named: "button border space"), for: .normal)
            }
        }
    }
    var snapToGridMode: Bool! {
        didSet {
            if snapToGridMode {
                panelView.btnSnapToGrid.setBackgroundImage(UIImage(named: "button border pushed sunset"), for: .normal)
            } else {
                panelView.btnSnapToGrid.setBackgroundImage(UIImage(named: "button border space"), for: .normal)
            }
        }
    }
    
    var util: MusicBoxUtil!
    var noteRange: [Note]!
    
    let cst = PaperConstant.shared
    
    var midiManager: MIDIManager!
    
    var bpm: Double = 100
    var colNum: Int = 80
    var imBeatCount: Int = 0
    var currentFileName: String = "paper"
    
    var document: PaperDocument?
    
    var lastTouchedTime: Date?
    var touchTimeCheckMode: Bool!
    var timer: Timer?
    var isNowPlaying: Bool = false
    
    var isPanelCollapsed: Bool = true {
        didSet {
            if isPanelCollapsed {
                panelView.btnCollapsePanel.setImage(UIImage(named: "hand pull"), for: .normal)
            } else {
                panelView.btnCollapsePanel.setImage(UIImage(named: "hand push"), for: .normal)
            }
        }
    }
    var panelMoveX: CGFloat = 316
    var panelTrailingConstraint: NSLayoutConstraint!
    
    var lastScrollViewOffset: CGPoint!
    var lastScrollViewZoomScale: CGFloat!
    
    var propertyAnimator: UIViewPropertyAnimator!
    
    let availablePunchSounds = [
        "zapsplat_office_stapler_single_staple_into_paper_001_66589",
        "zapsplat_office_stapler_single_staple_into_paper_002_66590",
        "zapsplat_office_stapler_single_staple_into_paper_003_66591"
    ]
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SwiftSpinner.show("load")
        
        guard let paper = document?.paper else {
            return
        }
        
        self.bpm = paper.bpm
        print("set bpm: \(bpm)")
        
        self.colNum = paper.colNum
        print("set colNum: \(colNum)")
        
        self.imBeatCount = paper.incompleteMeasureBeat
        musicPaperView.imBeatCount = self.imBeatCount
        print("set colNum: \(imBeatCount)")

        musicPaperView.data = paper.coords
        print("set coords array: \(musicPaperView.data.count) notes")
        
        self.allowEdit = paper.isAllowOthersToEdit
        print("EditMode", allowEdit, paper.isAllowOthersToEdit)
        
        util = MusicBoxUtil(highestNote: Note(note: .E, octave: 6), cellWidth: cst.cellWidth, cellHeight: cst.cellHeight, topMargin: cst.topMargin, leftMargin: cst.leftMargin)
        let rowNum = util.noteRange.count

        musicPaperView.configure(rowNum: rowNum, colNum: colNum, util: util, gridInfo:  document?.paper?.timeSignature.gridInfo ?? GridInfo())
        
        constraintMusicPaperWidth.constant = cst.leftMargin * 2 + musicPaperView.boxOutline.width
        constraintMusicPaperHeight.constant = cst.topMargin * 2 + musicPaperView.boxOutline.height
        
        let title = document?.paper?.title ?? "Unknown Title"
        let originalArtist = document?.paper?.originalArtist ?? "Unknown Artist"
        let paperMaker = document?.paper?.paperMaker ?? "Unknown"
        musicPaperView.setTexts(title: title, originalArtist: originalArtist, paperMaker: paperMaker)
        
        switch mode {
        case .edit:
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
            
            if allowEdit {
                self.musicPaperView.addGestureRecognizer(tapGesture)
            }
            
            initPanel()
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
                
                guard let lastTouchedTimeInterval = self.lastTouchedTime?.timeIntervalSince1970 else {
                    return
                }
                
                let currentTimeInterval = Date().timeIntervalSince1970
                
                // 저장된 자동저장 간격 불러오기
                let autosaveInterval = UserDefaults.standard.integer(forKey: .cfgAutosaveInterval)
                if self.touchTimeCheckMode && floor(currentTimeInterval) - floor(lastTouchedTimeInterval) >= autosaveInterval.cgFloat {
                    print("터치되지 않은지 \(autosaveInterval)초 경과")
                    self.saveDocument()
                    self.touchTimeCheckMode = false
                }
            })
            
            saveDocument()
            
            eraserMode = false
            snapToGridMode = true
            
        case .view:
            initViewModePanel()
            
            // ====== 광고 ====== //
            TrackingTransparencyPermissionRequest()
            if AdManager.productMode {
                bannerView = setupBannerAds(self, adUnitID: AdInfo.shared.fileBrowser)
                bannerView.delegate = self
            }
        }
        
        // PaperView 배경화면 설정
        let patternName = UserDefaults.standard.string(forKey: .cfgPaperTextureName) ?? "Paper: White paper with fibers"
        
        if let patternImage = UIImage(named: patternName) {
            let pattern = UIColor(patternImage: patternImage)
            musicPaperView.backgroundColor = pattern
        }
        
        // scrollView 배경화면 설정
        let bgPatternName = UserDefaults.standard.string(forKey: .cfgBackgroundTextureName) ?? "Background: Melamine-wood-2"
        
        if let bgPatternImage = UIImage(named: bgPatternName) {
            let pattern = UIColor(patternImage: bgPatternImage)
            scrollView.backgroundColor = pattern
        }
        
        scrollView.delegate = self
        
        midiManager = MIDIManager(soundbank: Bundle.main.url(forResource: "GeneralUser GS MuseScore v1.442", withExtension: "sf2"))
        midiManager.currentBPM = bpm
        
        // 초기 세로 위치 가운데로
        let size = view.bounds.size
        let yOffset = max(0, (size.height - constraintMusicPaperHeight.constant) / 2)
        paperViewTopConstraint.constant = yOffset
        paperViewBottomConstraint.constant = yOffset
        
        let xOffset = max(0, (size.width - constraintMusicPaperWidth.constant) / 2)
        paperViewLeadingConstraint.constant = xOffset
        paperViewTrailingConstraint.constant = xOffset
        
        view.layoutIfNeeded()
        
        if mode == .view {
            SwiftSpinner.show("Ready to play...")
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                SwiftSpinner.hide(nil)
                self.playSequence()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    override func viewDidAppear(_ animated: Bool) {
        SwiftSpinner.hide(nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        saveDocument()
        midiManager.midiPlayer?.stop()
    }
    
    @objc func tapAction(_ sender: UITapGestureRecognizer) {
        
        guard allowEdit else {
            print("edit not allowed")
            return
        }
        
        guard mode == .edit else {
            print("View mode")
            return
        }
        
        let touchedPoint = sender.location(in: musicPaperView)
        
        if !eraserMode {
            
            guard let note = util.getNoteFromGridBox(touchedPoint: touchedPoint) else {
                print("not found note.")
                return
            }
            let gridX = util.getGridXFromGridBox(touchedPoint: touchedPoint, snapToGridMode: snapToGridMode)
            guard gridX >= 0 else {
                return
            }
            let gridY = util.getGridYFromGridBox(touchedPoint: touchedPoint)
            let coord = PaperCoord(musicNote: note, absoluteTouchedPoint: touchedPoint, gridX: gridX, gridY: gridY)

            playPunchSound()
            
            // 중복된 노트 제거
            for another in musicPaperView.data {
                if another.musicNote == coord.musicNote && another.gridX == gridX {
                    return
                }
            }
            
            musicPaperView.addNote(appendCoord: coord)
            
        } else {
            
            guard let note = util.getNoteFromGridBox(touchedPoint: touchedPoint) else { return }
            
            var deletedCoord: PaperCoord?
            let filtered = musicPaperView.data.filter { coord in
                let absoulteCircleBounds = CGRect(x: cst.leftMargin + coord.gridX * cst.cellWidth - cst.circleRadius,
                                          y: cst.topMargin + coord.gridY.cgFloat * cst.cellHeight - cst.circleRadius,
                                          width: cst.circleRadius * 2,
                                          height: cst.circleRadius * 2)
                if coord.musicNote.equalTo(rhs: note) && absoulteCircleBounds.contains(touchedPoint) {
                    deletedCoord = coord
                    return false
                }
                return true
            }
            if filtered.count != musicPaperView.data.count {
                playEraserSound()
            }

            if let deletedCoord = deletedCoord {
                musicPaperView.eraseSpecificNote(deletedCoord: deletedCoord, fullData: filtered)
            }
            
        }
        
        // 마지막 터치된 시점으로부터
        lastTouchedTime = Date()
        touchTimeCheckMode = true
    }
    
    private func initPanel() {
        
        panelView = PaperOptionPanelView()
        panelView.setEditMode(allowEdit)
        panelView.delegate = self
        panelView.clipsToBounds = true
        view.addSubview(panelView)
        
        panelView.translatesAutoresizingMaskIntoConstraints = false
        panelView.centerYAnchor.constraint(equalTo:view.centerYAnchor).isActive = true
        
        panelTrailingConstraint = panelView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: panelMoveX)
        panelTrailingConstraint.isActive = true
        
        panelView.widthAnchor.constraint(equalToConstant: 380).isActive = true
        panelView.heightAnchor.constraint(equalToConstant: 320).isActive = true
        
        panelView.layer.borderWidth = 1
        /// 테두리 밖으로 contents가 있을 때, 마스킹(true)하여 표출안되게 할것인지 마스킹을 off(false)하여 보일것인지 설정
        panelView.layer.masksToBounds = false
        /// shadow 색상
        panelView.layer.shadowColor = UIColor.black.cgColor
        /// 현재 shadow는 view의 layer 테두리와 동일한 위치로 있는 상태이므로 offset을 통해 그림자를 이동시켜야 표출
        panelView.layer.shadowOffset = CGSize(width: 4, height: 10)
        /// shadow의 투명도 (0 ~ 1)
        panelView.layer.shadowOpacity = 0.8
        /// shadow의 corner radius
        panelView.layer.shadowRadius = 5.0
        
        if let bpm = document?.paper?.bpm {
            panelView.txtBpm.text = String(bpm)
        }
        if let imBeat = document?.paper?.incompleteMeasureBeat {
            panelView.txtIncompleteMeasure.text = String(imBeat)
        }
        
    }
    
    private func initViewModePanel() {
        
        viewModePanelView = PaperViewModePanelView()
        viewModePanelView.clipsToBounds = true
        viewModePanelView.delegate = self
        view.addSubview(viewModePanelView)
        
        viewModePanelView.translatesAutoresizingMaskIntoConstraints = false
        
        viewModePanelView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -120).isActive = true
        viewModePanelView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50).isActive = true
        
        viewModePanelView.widthAnchor.constraint(equalToConstant: 68).isActive = true
        viewModePanelView.heightAnchor.constraint(equalToConstant: 99).isActive = true
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(touchedScreen))
        view.addGestureRecognizer(gestureRecognizer)
        touchedScreen(gestureRecognizer)
        viewModePanelView.layer.cornerRadius = 10
        
    }
    
    @objc func touchedScreen(_ sender: UITapGestureRecognizer) {
        
        print(#function)
        
        viewModePanelView.isHidden = false
        UIView.animate(withDuration: 0.4) {
            self.viewModePanelView.alpha = 0.5
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            UIView.animate(withDuration: 0.4) {
                self.viewModePanelView.alpha = 0
            } completion: { success in
                self.viewModePanelView.isHidden = true
            }
        }
    }
    
    func pullPanel() {
        panelTrailingConstraint.isActive = false
        UIView.animate(withDuration: 0.5) { [unowned self] in
            panelView.frame = panelView.frame.offsetBy(dx: -panelMoveX, dy: 0)
        }
        panelTrailingConstraint.constant = 0
        panelTrailingConstraint.isActive = true
    }
    
    func pushPanel() {
        panelTrailingConstraint.isActive = false
        UIView.animate(withDuration: 0.5) { [unowned self] in
            panelView.frame = panelView.frame.offsetBy(dx: +panelMoveX, dy: 0)
        }
        panelTrailingConstraint.constant = panelMoveX
        panelTrailingConstraint.isActive = true
    }
    
    func playPunchSound() {
        let selectedSoundIndex = Int.random(in: 0...2)
        
        guard let url = Bundle.main.url(forResource: availablePunchSounds[selectedSoundIndex], withExtension: "mp3") else {
            return
        }
        
        do {
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let player = player else { return }
            
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func playEraserSound() {
        // zapsplat_foley_paper_sheets_x3_construction_sugar_set_down_on_surface_003_42009
        
        let soundName = "zapsplat_foley_paper_sheets_x3_construction_sugar_set_down_on_surface_003_42009"
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            return
        }
        
        do {
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let player = player else { return }
            
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
}

extension MusicPaperViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        return musicPaperView
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        scrollView.minimumZoomScale = 0.4
        scrollView.maximumZoomScale = 3
    }
    
    // 확대/축소하면 가운데로 위치하게
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForSize(view.bounds.size)
    }
    
    func updateConstraintsForSize(_ size: CGSize) {
        
        let yOffset = max(0, (size.height - musicPaperView.frame.height) / 2)
        paperViewTopConstraint.constant = yOffset
        paperViewBottomConstraint.constant = yOffset
        
        let xOffset = max(0, (size.width - musicPaperView.frame.width) / 2)
        paperViewLeadingConstraint.constant = xOffset
        paperViewTrailingConstraint.constant = xOffset
        
        view.layoutIfNeeded()
        print("musicPaperView.frame.height", musicPaperView.frame)
    }
}

extension MusicPaperViewController: PaperOptionPanelViewDelegate {
    func didClickedShrinkPaper(_ view: UIView) {
        
        if self.colNum > cst.defaultColNum {
            simpleDestructiveYesAndNo(self, message: "Do you really want to shrink the paper? This operation is not recoverable.".localized, title: "Shrink Paper") { [self] action in
                SwiftSpinner.show("processing...")
                self.colNum -= cst.defaultColNum
                document?.paper?.colNum = colNum
                musicPaperView.configure(rowNum: util.noteRange.count, colNum: colNum, util: util, gridInfo:  document?.paper?.timeSignature.gridInfo ?? GridInfo())
                constraintMusicPaperWidth.constant = cst.leftMargin * 2 + musicPaperView.boxOutline.width
                
                // 자른 부분 날리기
                let threshold = Double(self.colNum)
                musicPaperView.data = musicPaperView.data.filter { coord in
                    return coord.gridX! < threshold
                }

                SwiftSpinner.hide(nil)
            }
        } else {
            simpleAlert(self, message: "It cannot be shrinked any further.".localized, title: "Not Collapsible".localized, handler: nil)
        }
    }
    
    func didClickedToggleSnapToGrid(_ view: UIView) {
        snapToGridMode = !snapToGridMode
    }
    
    func didClickedExtendPaper(_ view: UIView) {
        self.colNum += cst.defaultColNum
        document?.paper?.colNum = colNum
        
        musicPaperView.expandPaper(expandedColNum: colNum)
        constraintMusicPaperWidth.constant = cst.leftMargin * 2 + musicPaperView.boxOutline.width
    }
    
    func didClickedBpmChange(_ view: UIView, bpm: Double) {
        midiManager.currentBPM = bpm
        self.bpm = bpm
        document?.paper?.bpm = bpm
    }
    
    func didIncompleteMeasureChange(_ view: UIView, numOf16beat: Int) {
        musicPaperView.imBeatCount = numOf16beat
        self.imBeatCount = numOf16beat
        document?.paper?.incompleteMeasureBeat = numOf16beat
        musicPaperView.reloadPaper()
    }
    
    func didClickedBackToMain(_ view: UIView) {
        backToMain()
    }
    
    func didClickedSetting(_ view: UIView) {
        if isPanelCollapsed {
            pullPanel()
        } else {
            pushPanel()
        }
        
        isPanelCollapsed.toggle()
    }
    
    func didClickedEraser(_ view: UIView) {
        eraserMode = !eraserMode
    }
    
    func didClickedSnapToGrid(_ view: UIView) {
        snapToGridMode = !snapToGridMode
    }
    
    func didClickedPlaySequence(_ view: UIView) {
        playSequence()
    }
    
    func didClickedResetPaper(_ view: UIView) {
        if allowEdit {
            simpleDestructiveYesAndNo(self, message: "Are you sure you want to remove all notes? This operation is not recoverable.".localized, title: "Remove All Notes".localized) { action in
                self.musicPaperView.data = []
                
                // ??
                self.musicPaperView.setNeedsDisplay()
            }
        }
    }
    
    func didClickedUndo(_ view: UIView) {
        if allowEdit && musicPaperView.data.count >= 1 {
            let lastCoord = musicPaperView.data.removeLast()
            musicPaperView.eraseSpecificNote(deletedCoord: lastCoord)
        }
    }
    
    func didClickedSave(_ view: UIView) {
        saveDocument()
    }
    
    private func saveDocument() {
        let filemgr = FileManager.default
    
        guard let document = document else { return }
        document.paper?.coords = musicPaperView.data
        
        let saveOption: UIDocument.SaveOperation = filemgr.fileExists(atPath: document.fileURL.path)
                        ? .forOverwriting : .forCreating
        
        document.save(to: document.fileURL, for: saveOption) { (success: Bool) -> Void in
            if success {
                print("File save OK")
            } else {
                print("Failed to save file ")
            }
        }
        
    }
    
    private func backToMain() {
        saveDocument()
        if delegate != nil {
            delegate!.didPaperEditFinished(self)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    private func playSequence() {
        if midiManager.midiPlayer!.isPlaying || isNowPlaying {
            if propertyAnimator.isRunning {
                propertyAnimator.stopAnimation(true)
                scrollView.zoomScale = lastScrollViewZoomScale
                scrollView.setContentOffset(lastScrollViewOffset, animated: false)
            }
            midiManager.midiPlayer?.stop()
            isNowPlaying = false
            
            switch mode {
            case .edit:
                self.panelView.btnPlay.setImage(UIImage(systemName: "play.fill"), for: .normal)
                self.panelView.btnPlay.setBackgroundImage(UIImage(named: "button border space"), for: .normal)
            case .view:
                self.viewModePanelView.btnPlay.setImage(UIImage(systemName: "play.fill"), for: .normal)
            }
            
        } else {
            
            let sequence = midiManager.convertPaperToMIDI(paperCoords: musicPaperView.data)
            midiManager.musicSequence = sequence
            isNowPlaying = true
            midiManager.midiPlayer?.play({
                print("midi play finished")
                DispatchQueue.main.async {
                    switch self.mode {
                    case .edit:
                        self.panelView.btnPlay.setImage(UIImage(systemName: "play.fill"), for: .normal)
                        self.panelView.btnPlay.setBackgroundImage(UIImage(named: "button border space"), for: .normal)
                    case .view:
                        self.viewModePanelView.btnPlay.setImage(UIImage(systemName: "play.fill"), for: .normal)
                    }
                }
            })
            
            switch mode {
            case .edit:
                self.panelView.btnPlay.setImage(UIImage(systemName: "stop.fill"), for: .normal)
                self.panelView.btnPlay.setBackgroundImage(UIImage(named: "button border pushed sunset"), for: .normal)
            case .view:
                self.viewModePanelView.btnPlay.setImage(UIImage(systemName: "stop.fill"), for: .normal)
            }
            
            DispatchQueue.main.async { [self] in
                
                guard let duration = midiManager.midiPlayer?.duration else {
                    return
                }
                
                let maxGridX = musicPaperView.data.reduce(0.0) { partialResult, coord in
                    max(partialResult, coord.gridX)
                }
                
                let endGridX = maxGridX * cst.cellWidth + cst.leftMargin
                
                lastScrollViewOffset = scrollView.contentOffset
                lastScrollViewZoomScale = scrollView.zoomScale
                
                guard let coords = document?.paper?.coords else {
                    return
                }
                var playbackData = coords
                
                playbackData.sort(by: { p1, p2 in
                    p1.gridX < p2.gridX
                })
                
                self.scrollView.contentOffset.x = 0
                let newZoomScale = self.scrollView.bounds.size.height / self.musicPaperView.bounds.size.height
                if self.scrollView.zoomScale >= newZoomScale {
                    self.scrollView.zoomScale = newZoomScale
                }
                
                self.propertyAnimator = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: duration, delay: 0, options: [.curveLinear, .allowUserInteraction], animations: { [unowned self] in
                    self.scrollView.contentOffset.x = endGridX * self.scrollView.zoomScale
                }, completion: { [unowned self]  position in
                    scrollView.zoomScale = lastScrollViewZoomScale
                    scrollView.setContentOffset(lastScrollViewOffset, animated: false)
                })
            }
        }
    }
}

extension MusicPaperViewController: PaperViewModePanelViewDelegate {
    func didPlayButtonClicked(_ view: PaperViewModePanelView) {
        playSequence()
    }
    
    func didBackToMainClicked(_ view: PaperViewModePanelView) {
        backToMain()
    }
    
    
}

extension MusicPaperViewController: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        constraintScrollViewBottom.constant += bannerView.adSize.size.height
    }
}
