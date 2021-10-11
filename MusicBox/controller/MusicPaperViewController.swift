//
//  MusicPaperViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/13.
//

import UIKit

protocol MusicPaperVCDelegate: AnyObject {
    func didPaperEditFinished(_ controller: MusicPaperViewController)
}

class MusicPaperViewController: UIViewController {
    
    var previousScale: CGFloat = 1.0
    
    weak var delegate: MusicPaperVCDelegate?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var musicPaperView: MusicBoxPaperView!
    @IBOutlet weak var constraintMusicPaperWidth: NSLayoutConstraint!
    @IBOutlet weak var constraintMusicPaperHeight: NSLayoutConstraint!
    
    @IBOutlet weak var paperViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var paperViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var paperViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var paperViewTrailingConstraint: NSLayoutConstraint!
    
    var panelView: PaperOptionPanelView!
    
    var eraserMode: Bool = false
    var snapToGridMode: Bool = true
    
    var util: MusicBoxUtil!
    var noteRange: [Note]!
    
    let cst = PaperConstant.shared
    
    var midiManager: MIDIManager!
    
    var bpm: Int = 100
    var colNum: Int = 80
    var imBeatCount: Int = 0
    var currentFileName: String = "paper"
    
    var document: PaperDocument?
    
    var lastTouchedTime: Date?
    var touchTimeCheckMode: Bool!
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let bpm = document?.paper?.bpm {
            self.bpm = bpm
            print("set bpm: \(bpm)")
        }
        
        if let colNum = document?.paper?.colNum {
            self.colNum = colNum
            print("set colNum: \(colNum)")
        } else {
            self.colNum = cst.defaultColNum
        }
        
        if let imBeatCount = document?.paper?.incompleteMeasureBeat {
            self.imBeatCount = imBeatCount
            print("set colNum: \(imBeatCount)")
        }
        
        if let paperCoords = document?.paper?.coords {
            musicPaperView.data = paperCoords
            print("set coords array: \(paperCoords.count) notes")
        }
        
        util = MusicBoxUtil(highestNote: Note(note: .E, octave: 6), cellWidth: cst.cellWidth, cellHeight: cst.cellHeight, topMargin: cst.topMargin, leftMargin: cst.leftMargin)
        let rowNum = util.noteRange.count

        musicPaperView.configure(rowNum: rowNum, colNum: colNum, util: util, gridInfo:  document?.paper?.timeSignature.gridInfo ?? GridInfo())
        
        constraintMusicPaperWidth.constant = cst.leftMargin * 2 + musicPaperView.boxOutline.width
        constraintMusicPaperHeight.constant = cst.topMargin * 2 + musicPaperView.boxOutline.height
        
        let title = document?.paper?.title ?? "Unknown Title"
        let originalArtist = document?.paper?.originalArtist ?? "Unknown Artist"
        let paperMaker = document?.paper?.paperMaker ?? "Unknown"
        musicPaperView.setTexts(title: title, originalArtist: originalArtist, paperMaker: paperMaker)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        self.musicPaperView.addGestureRecognizer(tapGesture)
        
        // PaperView 배경화면 설정
        if let patternImage = UIImage(named: "1. White paper with fibers") {
            let pattern = UIColor(patternImage: patternImage)
            musicPaperView.backgroundColor = pattern
        }
        
        // scrollView 배경화면 설정
        if let backgroundPatternImage = UIImage(named: "Melamine-wood-2") {
            let pattern = UIColor(patternImage: backgroundPatternImage)
            scrollView.backgroundColor = pattern
        }
        
        scrollView.delegate = self
        
        midiManager = MIDIManager(soundbank: Bundle.main.url(forResource: "GeneralUser GS MuseScore v1.442", withExtension: "sf2"))
        midiManager.currentBPM = bpm
        
        panelView = PaperOptionPanelView()
        panelView.delegate = self
        panelView.clipsToBounds = true
        view.addSubview(panelView)
        
        panelView.translatesAutoresizingMaskIntoConstraints = false
        panelView.centerXAnchor.constraint(equalTo:view.centerXAnchor).isActive = true
        panelView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 100).isActive = true
        
        panelView.widthAnchor.constraint(equalToConstant: 320).isActive = true
        panelView.heightAnchor.constraint(equalToConstant: 320).isActive = true
        
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        saveDocument()
    }
    
    @objc func tapAction(_ sender: UITapGestureRecognizer) {
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
    
    func didClickedBpmChange(_ view: UIView, bpm: Int) {
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
        
        saveDocument()
        if delegate != nil {
            delegate!.didPaperEditFinished(self)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func didClickedSetting(_ view: UIView) {
        
    }
    
    func didClickedEraser(_ view: UIView) {
        eraserMode = !eraserMode
    }
    
    func didClickedSnapToGrid(_ view: UIView) {
        snapToGridMode = !snapToGridMode
    }
    
    func didClickedPlaySequence(_ view: UIView) {
        
        if midiManager.midiPlayer!.isPlaying {
            midiManager.midiPlayer?.stop()
        } else {
            let sequence = midiManager.convertPaperToMIDI(paperCoords: musicPaperView.data)
            midiManager.musicSequence = sequence
            midiManager.midiPlayer?.play({
                print("midi play finished")
            })
        }
    }
    
    func didClickedResetPaper(_ view: UIView) {
        musicPaperView.data = []
    }
    
    func didClickedUndo(_ view: UIView) {
        if musicPaperView.data.count >= 1 {
            musicPaperView.data.removeLast()
        }
        
    }
    
    func didClickedSave(_ view: UIView) {
        saveDocument()
    }
    
    func saveDocument() {
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
}
