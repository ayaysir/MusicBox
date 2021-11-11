//
//  MusicPaperViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/13.
//

import UIKit
import AVFoundation
import SwiftSpinner

protocol MusicPaperVCDelegate: AnyObject {
    func didPaperEditFinished(_ controller: MusicPaperViewController)
}

enum MusicPaperMode {
    case edit, view
}

class MusicPaperViewController: UIViewController {
    
    var previousScale: CGFloat = 1.0
    
    var mode: MusicPaperMode = .edit
    weak var delegate: MusicPaperVCDelegate?

    var player: AVAudioPlayer?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var musicPaperView: MusicBoxPaperView!
    @IBOutlet weak var constraintMusicPaperWidth: NSLayoutConstraint!
    @IBOutlet weak var constraintMusicPaperHeight: NSLayoutConstraint!
    
    @IBOutlet weak var paperViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var paperViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var paperViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var paperViewTrailingConstraint: NSLayoutConstraint!
    
    var panelView: PaperOptionPanelView!
    var viewModePanelView: PaperViewModePanelView!
    
    var allowEdit: Bool = true
    var eraserMode: Bool = false
    var snapToGridMode: Bool = true
    
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
    
    var isPanelCollapsed: Bool = true
    var panelMoveX: CGFloat = 324
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
        
        guard let paper = document?.paper else {
            return
        }
        
        self.bpm = paper.bpm
        print("set bpm: \(bpm)")
        
        self.colNum = paper.colNum
        print("set colNum: \(colNum)")
        
        self.imBeatCount = paper.incompleteMeasureBeat
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
                if self.touchTimeCheckMode && floor(currentTimeInterval) - floor(lastTouchedTimeInterval) >= 5 {
                    print("터치되지 않은지 5초 경과")
                    self.saveDocument()
                    self.touchTimeCheckMode = false
                }
            })
            
            saveDocument()
        case .view:
            initViewModePanel()
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
            SwiftSpinner.show("재생 준비중입니다.")
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                SwiftSpinner.hide(nil)
                self.playSequence()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        saveDocument()
        midiManager.midiPlayer?.stop()
        midiManager.midiPlayer.
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

            
            // 중복된 노트 제거
            for another in musicPaperView.data {
                if another.musicNote == coord.musicNote && another.gridX == gridX {
                    return
                }
            }
            
            musicPaperView.data.append(coord)
            
            playSound()
            
        } else {
            
            guard let note = util.getNoteFromGridBox(touchedPoint: touchedPoint) else { return }
            let filtered = musicPaperView.data.filter { coord in
                let absoulteCircleBounds = CGRect(x: cst.leftMargin + coord.gridX * cst.cellWidth - cst.circleRadius,
                                          y: cst.topMargin + coord.gridY.cgFloat * cst.cellHeight - cst.circleRadius,
                                          width: cst.circleRadius * 2,
                                          height: cst.circleRadius * 2)
                if coord.musicNote.equalTo(rhs: note) && absoulteCircleBounds.contains(touchedPoint) {
                    return false
                }
                return true
            }
            musicPaperView.data = filtered
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
    
    func playSound() {
        let selectedSoundIndex = Int.random(in: 0...2)
        
        guard let url = Bundle.main.url(forResource: availablePunchSounds[selectedSoundIndex], withExtension: "mp3") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
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
    func didClickedToggleSnapToGrid(_ view: UIView) {
        snapToGridMode = !snapToGridMode
    }
    
    func didClickedExtendPaper(_ view: UIView) {
        self.colNum += cst.defaultColNum
        document?.paper?.colNum = colNum
        musicPaperView.configure(rowNum: util.noteRange.count, colNum: colNum, util: util, gridInfo:  document?.paper?.timeSignature.gridInfo ?? GridInfo())
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
            musicPaperView.data = []
        }
        
    }
    
    func didClickedUndo(_ view: UIView) {
        if allowEdit && musicPaperView.data.count >= 1 {
            musicPaperView.data.removeLast()
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
        if midiManager.midiPlayer!.isPlaying {
            if propertyAnimator.isRunning {
                propertyAnimator.stopAnimation(true)
                scrollView.zoomScale = lastScrollViewZoomScale
                scrollView.setContentOffset(lastScrollViewOffset, animated: false)
            }
            midiManager.midiPlayer?.stop()
        } else {
            let sequence = midiManager.convertPaperToMIDI(paperCoords: musicPaperView.data)
            midiManager.musicSequence = sequence
            midiManager.midiPlayer?.play({
                print("midi play finished")
            })
            
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
