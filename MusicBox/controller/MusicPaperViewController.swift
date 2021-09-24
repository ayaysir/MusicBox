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
    
    @IBOutlet weak var swtEraserOn: UISwitch!
    
    var isEraserMode: Bool = false
    
    var util: MusicBoxUtil!
    var noteRange: [Note]!
    var noteRangeWithHeight: [NoteWithHeight] = []
    
    let cst = PaperConstant.shared
    
    var midiManager: MIDIManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let colNum = 80
        
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
        
        isEraserMode = swtEraserOn.isOn
        
        midiManager = MIDIManager(soundbank: Bundle.main.url(forResource: "gs_instruments", withExtension: "dls"))
        
    }
    
    @objc func tapAction(_ sender: UITapGestureRecognizer) {
        let cgPoint = sender.location(in: musicPaperView)
        if !isEraserMode {
            guard let note = util.getNoteFromCGPointY(range: noteRangeWithHeight, cgPoint: cgPoint) else {
                return
            }
            let snapped = CGPoint(x: util.snapToGridX(originalX: cgPoint.x), y: util.snapToGridY(originalY: cgPoint.y))
            let coord = PaperCoord(musicNote: note, cgPoint: cgPoint, snappedPoint: snapped)
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
    
    
    @IBAction func btnActPlaySampleMIDIFile(_ sender: Any) {
        midiManager.createAVMIDIPlayer(midiFile: Bundle.main.url(forResource: "Allian1", withExtension: "mid"))
        midiManager.midiPlayer?.play(nil)
    }
    
    @IBAction func btnActPlaySampleSequence(_ sender: Any) {
        midiManager.createAVMIDIPlayer(sequence: midiManager.musicSequence)
        midiManager.midiPlayer?.play(nil)
    }
    
    @IBAction func btnActPlayMusicPlayer(_ sender: Any) {
        midiManager.playMusicPlayer()
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
