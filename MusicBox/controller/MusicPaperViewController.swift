//
//  MusicPaperViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/13.
//

import UIKit

class MusicPaperViewController: UIViewController {
    
    var previousScale: CGFloat = 1.0
    
    @IBOutlet weak var musicPaperView: MusicBoxPaperView!
    @IBOutlet weak var constraintMusicPaperWidth: NSLayoutConstraint!
    @IBOutlet weak var constraintMusicPaperHeight: NSLayoutConstraint!
    
    var panelView: PaperOptionPanelView!
    
    var isEraserMode: Bool = false
    var isSnapToGridMode: Bool = true
    
    var util: MusicBoxUtil!
    var noteRange: [Note]!
    var noteRangeWithHeight: [NoteWithHeight] = []
    
    let cst = PaperConstant.shared
    
    var midiManager: MIDIManager!
    var midiManager2: MIDIManager!
    
    var bpm: Int = 100
    var imBeatCount: Int = 0
    var currentFileName: String = "song"
    
    var document: PaperDocument?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let colNum = 80
        let document = document
        print("title:", document?.paper?.title)
        
        util = MusicBoxUtil(highestNote: Note(note: .E, octave: 6), cellWidth: cst.cellWidth, cellHeight: cst.cellHeight)
        noteRange = util.getNoteRange()
        let rowNum = util.noteRange.count

        musicPaperView.configure(rowNum: rowNum, colNum: colNum, util: util)
        
        let tolerance = cst.cellHeight - cst.topMargin
        for (index, note) in noteRange.enumerated() {
            let noteHeight = NoteWithHeight(height: tolerance + cst.topMargin + cst.cellHeight * index.cgFloat, note: note)
            noteRangeWithHeight.append(noteHeight)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        let gesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(sender:)))
        self.musicPaperView.addGestureRecognizer(tapGesture)
        self.musicPaperView.addGestureRecognizer(gesture)
        
        midiManager = MIDIManager(soundbank: Bundle.main.url(forResource: "GeneralUser GS MuseScore v1.442", withExtension: "sf2"))
        midiManager.currentBPM = bpm
        
        midiManager2 = MIDIManager(soundbank: Bundle.main.url(forResource: "gs_instruments", withExtension: "dls"))
        
        
        panelView = PaperOptionPanelView()
        panelView.delegate = self
        panelView.clipsToBounds = true
        view.addSubview(panelView)
        
        panelView.translatesAutoresizingMaskIntoConstraints = false
        panelView.centerXAnchor.constraint(equalTo:view.centerXAnchor).isActive = true
        panelView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 100).isActive = true
        
        panelView.widthAnchor.constraint(equalToConstant: 320).isActive = true
        panelView.heightAnchor.constraint(equalToConstant: 320).isActive = true
        
        
        
        
    }
    
    @objc func tapAction(_ sender: UITapGestureRecognizer) {
        let cgPoint = sender.location(in: musicPaperView)
        if !isEraserMode {
            guard let note = util.getNoteFromCGPointY(range: noteRangeWithHeight, cgPoint: cgPoint) else {
                return
            }
            let snappedX: CGFloat = isSnapToGridMode ? util.snapToGridX(originalX: cgPoint.x) : cgPoint.x
            let snappedY: CGFloat = util.snapToGridY(originalY: cgPoint.y)
            var coord = PaperCoord(musicNote: note, cgPoint: cgPoint, snappedPoint: CGPoint(x: snappedX, y: snappedY))
            
            // 중복된 노트 제거: contains도 o(n)이므로 차이없음
            for another in musicPaperView.data {
                if another.musicNote == coord.musicNote
                    && another.snappedPoint.x == snappedX {
                    print("중복 발견")
                    return
                }
            }
            coord.setGridX(start: cst.leftMargin, eachCellWidth: cst.cellWidth)
            print(coord)
            musicPaperView.data.append(coord)
        } else {
            print(cgPoint, cgPoint.x - cst.circleRadius, cgPoint.y - cst.circleRadius)
            guard let note = util.getNoteFromCGPointY(range: noteRangeWithHeight, cgPoint: cgPoint) else {
                return
            }
            let filtered = musicPaperView.data.filter { coord in
                let circleBounds = CGRect(x: coord.snappedPoint.x - cst.circleRadius, y: coord.snappedPoint.y - cst.circleRadius, width: cst.circleRadius * 2, height: cst.circleRadius * 2)
                if coord.musicNote == note && circleBounds.contains(cgPoint) {
                    return false
                }
                return true
            }
            musicPaperView.data = filtered
        }
    }
    
    @objc func pinchAction(sender:UIPinchGestureRecognizer) {
        let scale: CGFloat = previousScale * sender.scale
        self.musicPaperView.transform = CGAffineTransform(scaleX: scale, y: scale)
//        constraintMusicPaperWidth.constant = constraintMusicPaperWidth.constant * scale
//        constraintMusicPaperHeight.constant = constraintMusicPaperHeight.constant * scale
        
        previousScale = sender.scale
    }
    
    @IBAction func swtActEraserOn(_ sender: UISwitch) {
        if sender.isOn {
            isEraserMode = true
        } else {
            isEraserMode = false
        }
    }
    
    @IBAction func swtActSnapToGridOn(_ sender: UISwitch) {
        if sender.isOn {
            isSnapToGridMode = true
        } else {
            isSnapToGridMode = false
        }
    }
    
    
    
    @IBAction func btnActPlaySampleMIDIFile(_ sender: Any) {
        midiManager2.midiPlayer?.stop()
        midiManager2.stopMusicPlayer()
        guard let sample = Bundle.main.url(forResource: "Allian1", withExtension: "mid") else {
            print("파일이 없습니다.")
            return
        }
        midiManager.createAVMIDIPlayer(midiFile: sample)
        midiManager.midiPlayer?.play(nil)
    }
    
    @IBAction func btnActPlaySampleSequence(_ sender: Any) {
        midiManager.midiPlayer?.stop()
        midiManager2.stopMusicPlayer()
        midiManager2.createAVMIDIPlayer(sequence: midiManager2.musicSequence)
        midiManager2.midiPlayer?.play(nil)
    }
    
    @IBAction func btnActPlayMusicPlayer(_ sender: Any) {
        midiManager.midiPlayer?.stop()
        midiManager2.midiPlayer?.stop()
        midiManager2.playMusicPlayer()
    }
    
    @IBAction func btnActConvertPaperToMIDI(_ sender: Any) {
        
    }
    
    @IBAction func btnActEraseAllNote(_ sender: Any) {
        
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MusicPaperViewController: PaperOptionPanelViewDelegate {
    func didClickedBpmChange(_ view: UIView, bpm: Int) {
        midiManager.currentBPM = bpm
        self.bpm = bpm
    }
    
    func didIncompleteMeasureChange(_ view: UIView, numOf16beat: Int) {
        musicPaperView.imBeatCount = numOf16beat
        self.imBeatCount = numOf16beat
        musicPaperView.reloadPaper()
    }
    
    func didClickedBackToMain(_ view: UIView) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func didClickedSetting(_ view: UIView) {
        
    }
    
    func didClickedEraser(_ view: UIView) {
        isEraserMode = !isEraserMode
    }
    
    func didClickedSnapToGrid(_ view: UIView) {
        isSnapToGridMode = !isSnapToGridMode
    }
    
    func didClickedPlaySequence(_ view: UIView) {
        let sequence = midiManager.convertPaperToMIDI(paperCoords: musicPaperView.data)
        midiManager.musicSequence = sequence
        midiManager.midiPlayer?.play({
            print("finished")
        })
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
        
        let filemgr = FileManager.default
        
        let coords = musicPaperView.data
        let timeSignature = TimeSignature()
        
        let paper = Paper(bpm: bpm, coords: coords, timeSignature: timeSignature)
        
        print(FileUtil.getDocumentsDirectory())
        
        do {
            let fileName = currentFileName
            let docUrl = FileUtil.getDocumentsDirectory().appendingPathComponent(fileName).appendingPathExtension("musicbox")
            let document = PaperDocument(fileURL: docUrl)
            paper.comment = ""
            paper.title = "this is aabbcc"
            paper.paperMaker = "acnmexaz"
            
            document.paper = paper
            
            let saveOption: UIDocument.SaveOperation = filemgr.fileExists(atPath: docUrl.path) ? .forOverwriting : .forCreating
            
            document.save(to: docUrl, for: saveOption) { (success: Bool) -> Void in
                if success {
                    print("File save OK")
                } else {
                    print("Failed to save file ")
                }
            }
        }
        
//        do {
//            let url = FileUtil.getDocumentsDirectory().appendingPathComponent("music").appendingPathExtension("musicbox")
//            let archived = try NSKeyedArchiver.archivedData(withRootObject: paper, requiringSecureCoding: true)
//            try archived.write(to: url)
//            print("archived success:", archived)
//
//            let dataFromDisk = try Data(contentsOf: url)
//            guard let unarchived = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [Paper.self, PaperCoord.self, Note.self, NSArray.self, NSString.self, NSNumber.self], from: dataFromDisk) as? Paper else {
//                print("unarchived failed")
//                return
//            }
//            unarchived.coords.forEach { coord in
//                print(coord.description)
//            }
//
//        } catch {
//            print(error)
//        }
        
    }
    
    
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

let deviceNames: [String] = [
    "iPhone SE",
    "iPad 11 Pro Max",
    "iPad Pro (11-inch)"
]

@available(iOS 13.0, *)
struct MusicPaperViewController_Preview: PreviewProvider {
  static var previews: some View {
    ForEach(deviceNames, id: \.self) { deviceName in
      UIViewControllerPreview {
        UIStoryboard(name: "Main", bundle: nil)
            .instantiateInitialViewController { coder in
            MusicPaperViewController(coder: coder)
        }!
      }.previewDevice(PreviewDevice(rawValue: deviceName))
        .previewDisplayName(deviceName)
    }
  }
}
#endif
