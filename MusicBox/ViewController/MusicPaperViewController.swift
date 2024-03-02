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
import Lottie

protocol MusicPaperVCDelegate: AnyObject {
    func didPaperEditFinished(_ controller: MusicPaperViewController)
}

enum MusicPaperMode {
    case edit, view
}

class MusicPaperViewController: UIViewController {
    private var bannerView: GADBannerView!
    private var interstitial: GADInterstitialAd?
    private var validTapCount: Int = 0 {
        didSet {
            // print("validTapCount:", validTapCount)
        }
    }
    private var isBannerAdEnabled = false
    private var isEndFullScreenAd = false
    
    lazy var lottieView: LottieAnimationView = {
        let animationView = LottieAnimationView(name: "129574-ginger-bread-socks-christmas")
        animationView.frame = CGRect(x: 0, y: 0,
                                     width: 250, height: 250)
        animationView.center = self.view.center
        animationView.contentMode = .scaleAspectFill
        animationView.stop()
        animationView.isHidden = true
        animationView.loopMode = .loop
        
        animationView.layer.shadowColor = UIColor.black.cgColor
        animationView.layer.shadowOpacity = 0.7
        animationView.layer.shadowOffset = .zero
        animationView.layer.shadowRadius = 7
        
        return animationView
    }()
    
    lazy var visualEffectView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .regular)
        let visualEffectView = UIVisualEffectView(effect: blur)
        visualEffectView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        visualEffectView.layer.cornerRadius = visualEffectView.frame.width * 0.5
        visualEffectView.center = self.view.center
        visualEffectView.isHidden = true
        
        return visualEffectView
    }()
    
    var previousScale: CGFloat = 1.0
    
    var mode: MusicPaperMode = .edit
    weak var delegate: MusicPaperVCDelegate?
    
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
                // panelView.btnUndo.isEnabled = false
            } else {
                panelView.btnEraser.setBackgroundImage(UIImage(named: "button border space"), for: .normal)
                // panelView.btnUndo.isEnabled = true
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
    
    var currentSequence: MusicSequence?
    
    // 광고 배너로 height 올리는거 한 번만 실행
    var bottomConstantRaiseOnce = true
    
    let availablePunchSounds = [
        "zapsplat_office_stapler_single_staple_into_paper_001_66589",
        "zapsplat_office_stapler_single_staple_into_paper_002_66590",
        "zapsplat_office_stapler_single_staple_into_paper_003_66591"
    ]
    
    /// 현재 작업중에 실시된 명령들을 스택으로 저장
    private var undoStack: [PaperCoordState] = [] {
        didSet {
            panelView.btnUndo.isEnabled = undoStack.count > 0
        }
    }
    private var isSequenceWriting: Bool = false {
        didSet {
            if mode == .edit {
                DispatchQueue.main.async { [weak self] in
                    self?.panelView.btnPlay.isEnabled = !(self!.isSequenceWriting)
                }
            }
            
            DispatchQueue.main.async { [unowned self] in
                if isSequenceWriting {
                    visualEffectView.isHidden = false
                    lottieView.isHidden = false
                    lottieView.play()
                } else {
                    visualEffectView.isHidden = true
                    lottieView.isHidden = true
                    lottieView.stop()
                }
            }
            
            
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // 온보딩 관련 변수
    private let onboardingKey = "ONBOARDING_ONCE_iS_APPEARED"
    private let onboardingTag = 2109742
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SwiftSpinner.show("Finishing...".localized)
        
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
            print("Ready to play", Date())
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
                SwiftSpinner.hide(nil)
                self.playSequence()
                print("Hide", Date())
            }
        } else {
            // debounce = Debounce(milliseconds: 500, handler: { date in
            //     print("delayWork-debounce:", date)
            //     self.updateSequence()
            // })
            // throttle = Throttle(milliseconds: 1000, handler: { date in
            //     print("delayWork-throttle:", date)
            // })
            panelView.btnUndo.isEnabled = false
            updateSequence()
        }
        
        // 전면 광고
        prepareFullScreenAd()
        
        // 온보딩 일회용
        onboardingOnce()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SwiftSpinner.hide(nil)
        
        // ====== 광고 ====== //
        TrackingTransparencyPermissionRequest()
        DispatchQueue.main.async { [unowned self] in
            // 이거를 하면 view의 사이즈도 조정된다.
            scrollView.layoutIfNeeded()
            if AdManager.isReallyShowAd {
                bannerView = setupBannerAds(self, adUnitID: AdInfo.shared.fileBrowser)
                bannerView.delegate = self
                isBannerAdEnabled = true
            }
            
            view.addSubview(lottieView)
            lottieView.center = view.center
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveDocument()
        midiManager.midiPlayer?.stop()
        GlobalOsc.shared.conductor.stop()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        DispatchQueue.main.async { [unowned self] in
            scrollView.layoutIfNeeded()
            lottieView.center = view.center
            bannerView?.fitInView(self)
        }
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

            if configStore.bool(forKey: .cfgPlayPitchWhenInputNotes) {
                GlobalOsc.shared.conductor.start()
                GlobalOsc.shared.conductor.makeSound(note: UInt8(coord.musicNote.semitone + 12))
            }
            
            // 새로 터치한 위치가 중복이면 추가하지 않고 리턴
            for another in musicPaperView.data {
                let absoulteCircleBounds = CGRect(x: cst.leftMargin + another.gridX * cst.cellWidth - cst.circleRadius,
                                          y: cst.topMargin + another.gridY.cgFloat * cst.cellHeight - cst.circleRadius,
                                          width: cst.circleRadius * 2,
                                          height: cst.circleRadius * 2)
                // print(another.musicNote, coord.musicNote, another.gridX, gridX)
                // print(another.musicNote.equalTo(rhs: coord.musicNote), another.gridX == gridX)
                
                if another.musicNote.equalTo(rhs: coord.musicNote) && (another.gridX == gridX || absoulteCircleBounds.contains(touchedPoint)) {
                    FXSound.block.play()
                    return
                }
            }
            
            FXSound.punch.play()
            musicPaperView.addNote(appendCoord: coord)
            undoStack.append(PaperCoordState(state: .insert, coord: coord))
        } else {
            // eraser mode
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
                FXSound.eraser.play()
            } else {
                FXSound.block.play()
                return
            }

            if let deletedCoord = deletedCoord {
                musicPaperView.eraseSpecificNote(deletedCoord: deletedCoord, fullData: filtered)
                undoStack.append(PaperCoordState(state: .remove, coord: deletedCoord))
            }
        }
        
        // 마지막 터치된 시점으로부터
        lastTouchedTime = Date()
        touchTimeCheckMode = true
        
        increaseValidCount()
        
        // let _ = midiManager.convertPaperToMIDI(paperCoords: musicPaperView.data)
        
        // debounce.run()
        // throttle.run()
        // updateSequence()
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
    
    private func updateSequence(after handler: (() -> ())? = nil) {
        guard !isSequenceWriting else {
            // print("sequence is writing")
            return
        }
        
        isSequenceWriting = true
        DispatchQueue.global(qos: .default).async { [unowned self] in
            currentSequence = midiManager.convertPaperToMIDI(paperCoords: musicPaperView.data)
            midiManager.musicSequence = currentSequence
            isSequenceWriting = false
            handler?()
        }
    }
}

extension MusicPaperViewController {
    private func onboardingOnce() {
        guard mode == .edit else {
            return
        }
        
        if !UserDefaults.standard.bool(forKey: onboardingKey) {
            // Make it appear only once
            UserDefaults.standard.setValue(true, forKey: onboardingKey)
            
            let onboardingView = UIView(frame: view.frame)
            let overlayView = UIView(frame: view.frame)
            overlayView.backgroundColor = .black
            overlayView.alpha = 0.7
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissOnboarding))
            overlayView.addGestureRecognizer(tapGesture)
            
            let imageView = UIImageView(image: .init(named: "Onboarding_EN".localized))
            imageView.frame.size.width = view.frame.size.width
            imageView.frame.size.height = view.frame.size.width * 3 / 4
            imageView.center = view.center
            imageView.contentMode = .scaleAspectFit
            imageView.layoutIfNeeded()
            
            let button = UIButton(frame:
                    .init(x: imageView.frame.midX - 100,
                          y: imageView.frame.maxY + 20,
                          width: 200,
                          height: 50))
            button.setTitle("OK, I got it!".localized, for: .normal)
            button.backgroundColor = .systemBlue
            button.layer.cornerRadius = 10
            button.addTarget(self, action: #selector(dismissOnboarding), for: .touchUpInside)
            
            onboardingView.addSubview(overlayView)
            onboardingView.addSubview(imageView)
            onboardingView.addSubview(button)
            onboardingView.tag = 2109742
            
            view.addSubview(onboardingView)
        }
    }
    
    @objc func dismissOnboarding() {
        view.subviews.forEach {
            if $0.tag == onboardingTag {
                $0.removeFromSuperview()
            }
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
        // print("musicPaperView.frame.height", musicPaperView.frame)
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
        if AdManager.isReallyShowAd {
            isEndFullScreenAd = true
            showFullScreenAd()
        } else {
            backToMain()
        }
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
                self.undoStack = []
                // ??
                self.musicPaperView.setNeedsDisplay()
            }
        }
    }
    
    func didClickedUndo(_ view: UIView) {
        // if allowEdit && musicPaperView.data.count >= 1 {
        //     let lastCoord = musicPaperView.data.removeLast()
        //     musicPaperView.eraseSpecificNote(deletedCoord: lastCoord)
        // }
        
        if allowEdit && undoStack.count > 0 {
            let last = undoStack.last!
            
            switch last.state {
            case .insert:
                // 되돌리기: 삽입 취소
                let lastCoordIndex = musicPaperView.data.lastIndex { coord in
                    // print(coord.paperId, last.coord.paperId, coord.paperId == last.coord.paperId)
                    return coord.paperId == last.coord.paperId
                }
                // print(lastCoordIndex)
                if let lastCoordIndex = lastCoordIndex {
                    musicPaperView.eraseSpecificNote(deletedCoord: last.coord)
                    musicPaperView.data.remove(at: lastCoordIndex)
                }
            case .remove:
                // 되돌리기: 삭제 취소
                musicPaperView.addNote(appendCoord: last.coord)
            }
            
            _ = undoStack.popLast()
            FXSound.undo.play()
            increaseValidCount()
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
        SwiftSpinner.show("Save the document...".localized)
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [unowned self] timer in
            saveDocument()
            if delegate != nil {
                delegate!.didPaperEditFinished(self)
            }
            SwiftSpinner.hide()
            self.dismiss(animated: true, completion: nil)
        }
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
            // 시퀀스 만들고 재생할 때 버벅거림
            // let sequence = midiManager.convertPaperToMIDI(paperCoords: musicPaperView.data)
            // midiManager.musicSequence = sequence
            
            updateSequence { [unowned self] in
                makeMidiPlayerAndScroll()
            }
        }
    }
    
    private func makeMidiPlayerAndScroll() {
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
        
        GlobalOsc.shared.conductor.stop()
        DispatchQueue.main.async { [unowned self] in
            switch mode {
            case .edit:
                self.panelView.btnPlay.setImage(UIImage(systemName: "stop.fill"), for: .normal)
                self.panelView.btnPlay.setBackgroundImage(UIImage(named: "button border pushed sunset"), for: .normal)
            case .view:
                self.viewModePanelView.btnPlay.setImage(UIImage(systemName: "stop.fill"), for: .normal)
            }
            
            guard let duration = midiManager.midiPlayer?.duration else {
                return
            }
            
            let maxGridX = musicPaperView.data.reduce(0.0) { partialResult, coord in
                max(partialResult, coord.gridX)
            }
            
            let endGridX = (maxGridX * cst.cellWidth + cst.leftMargin)
            
            lastScrollViewOffset = scrollView.contentOffset
            lastScrollViewZoomScale = scrollView.zoomScale
            
            guard let coords = document?.paper?.coords else {
                return
            }
            var playbackData = coords
            
            playbackData.sort(by: { p1, p2 in
                p1.gridX < p2.gridX
            })
            
            let newZoomScale = self.scrollView.bounds.size.height / self.musicPaperView.bounds.size.height
            
            if self.scrollView.zoomScale >= newZoomScale {
                self.scrollView.zoomScale = newZoomScale
            }
            
            /* ScrollDelayFix:
             (X)
             configStore.integer(forKey: .cfgDurationOfNoteSound) * 1 bar당 16분음표 개수(=beat)?
             예1) 4분의 x박자에서 8(NoteDuration) * 4(1 bar당 16분음표 개수) = 32
             cst.cellWidth * 32 하면 4분의 x 박자 음악들에서 스크롤 맞음?
             
             x/1 => 16
             x/2 => 8
             x/4 => 4
             x/8 => 2
             x/16 => 1
             
             (O)
             NoteDuration * 4 하면 박자 상관 없이 스크롤 맞음 (이유는 아직 모름)
             
             */
            let noteDuration = configStore.integer(forKey: .cfgDurationOfNoteSound).cgFloat
            let beatsOfOneBar = 16.0 / document!.paper!.timeSignature.lower.cgFloat
            let extraGridXPixels = cst.cellWidth * (noteDuration * 4)
            
            let endPosition = (endGridX + extraGridXPixels) * scrollView.zoomScale
            
            if scrollView.contentOffset.x > endPosition || scrollView.contentOffset.x < 0.0 {
                scrollView.contentOffset.x = 0
                lastScrollViewOffset = scrollView.contentOffset
            }
            let currentProgress = scrollView.contentOffset.x / endPosition
            
            let midiStartPosition = duration * currentProgress
            
            // startPosition이 마이너스인 경우
            // 'com.apple.coreaudio.avfaudio', reason: 'error -50' 발생
            let remainDuration: TimeInterval = {
                guard midiStartPosition > 0.0 else {
                    return duration
                }
                
                return duration - midiStartPosition
            }()
            
            // self.scrollView.contentOffset.x = 0
            print("current paper postion:", currentProgress, scrollView.contentOffset.x, endPosition)
            if let player = midiManager.midiPlayer {
                player.currentPosition = midiStartPosition
            }
            
            print("ScrollDelayFix: Step 1:", bpm, document!.paper!.timeSignature, PaperConstant.shared.cellWidth)
            print("ScrollDelayFix: Step 2:", noteDuration, beatsOfOneBar, extraGridXPixels)
            
            let animatorOptions: UIView.AnimationOptions = {
                switch mode {
                case .edit:
                    return [.curveLinear]
                case .view:
                    return [.curveLinear, .allowUserInteraction]
                }
            }()
            
            self.propertyAnimator = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: remainDuration, delay: 0, options: animatorOptions, animations: { [unowned self] in
                scrollView.contentOffset.x = endPosition
            }, completion: { [unowned self]  position in
                scrollView.zoomScale = lastScrollViewZoomScale
                scrollView.setContentOffset(lastScrollViewOffset, animated: false)
            })
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
        if bottomConstantRaiseOnce {
            print("bottomConst")
            let window = UIApplication.shared.windows.first
            // let topPadding = window?.safeAreaInsets.top
            let bottomPadding = window?.safeAreaInsets.bottom
            // print("bottomPadding:", bottomPadding)
            constraintScrollViewBottom.constant += bannerView.adSize.size.height + (bottomPadding ?? 0)
            bottomConstantRaiseOnce = false
        }
    }
}

extension MusicPaperViewController: GADFullScreenContentDelegate {
    /// 전면 광고 준비
    func prepareFullScreenAd() {
        guard AdManager.isReallyShowAd else {
            return
        }
        
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: AdInfo.shared.paperFullScreen,
                               request: request,
                               completionHandler: { [self] ad, error in
                if let error = error {
                    print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                    return
                }
            
                interstitial = ad
                interstitial?.fullScreenContentDelegate = self
            }
        )
    }
    
    private func increaseValidCount() {
        validTapCount += 1
    
        let step1Count = 10
        let step2Count = 32
        let step3Count = 64
        let validTapCountExcludedStep2Count = validTapCount - step2Count
    
        let isAllowFullScreenAd = mode == .edit ? !isBannerAdEnabled : true
        let triggerCondition1 = validTapCount == step1Count && ChanceUtil.probability(0.5)
        let triggerCondition2 = validTapCount == step2Count
        let triggerCondition3 = validTapCountExcludedStep2Count >= 0 && validTapCountExcludedStep2Count % step3Count == 0
        let triggerConditions = isAllowFullScreenAd && (triggerCondition1 || triggerCondition2 || triggerCondition3)
        if triggerCondition1 {
            print("triggerCondition1: true")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [unowned self] in
            if triggerConditions {
                // showFullScreenAd()
            }
        }
    }
    
    private func showFullScreenAd() {
        guard AdManager.isReallyShowAd else {
            return
        }
        
        view.isUserInteractionEnabled = false
        
        if let interstitial = interstitial {
            interstitial.present(fromRootViewController: self)
        } else {
            print("Ad wasn't ready")
            view.isUserInteractionEnabled = true
        }
    }
    
    /// Tells the delegate that the ad failed to present full screen content.
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content.")
        view.isUserInteractionEnabled = true
    }
    
    /// Tells the delegate that the ad will present full screen content.
    // func adDidPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    //     print("Ad will present full screen content.")
    // }
    
    /// Tells the delegate that the ad dismissed full screen content.
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did dismiss full screen content.")
        if isEndFullScreenAd {
            backToMain()
            return
        }
        
        view.isUserInteractionEnabled = true
        // prepareFullScreenAd()
    }
}
