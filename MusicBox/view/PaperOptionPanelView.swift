//
//  PaperOptionPanelView.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/26.
//

import UIKit

protocol PaperOptionPanelViewDelegate: AnyObject {
    func didClickedBackToMain(_ view: UIView)
    func didClickedSetting(_ view: UIView)
    func didClickedEraser(_ view: UIView)
    func didClickedSnapToGrid(_ view: UIView)
    func didClickedPlaySequence(_ view: UIView)
    func didClickedResetPaper(_ view: UIView)
    func didClickedUndo(_ view: UIView)
    func didClickedSave(_ view: UIView)
    func didClickedBpmChange(_ view: UIView, bpm: Double)
    func didIncompleteMeasureChange(_ view: UIView, numOf16beat: Int)
    func didClickedExtendPaper(_ view: UIView)
    func didClickedShrinkPaper(_ view: UIView)
    func didClickedToggleSnapToGrid(_ view: UIView)
}

class PaperOptionPanelView: UIView {
    
    weak var delegate: PaperOptionPanelViewDelegate?

    let nibName = "PaperOptionPanelView"
    
    var editMode: Bool = true
    
    @IBOutlet weak var txtBpm: UITextField!
    @IBOutlet weak var txtIncompleteMeasure: UITextField!
    
    @IBOutlet weak var btnCollapsePanel: UIButton!
    @IBOutlet weak var btnEraser: UIButton!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnSnapToGrid: UIButton!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        print(#function)
        commonInit()
    }
    
    func commonInit() {
        
        guard let view = loadViewFromNib() else { return }
        view.frame = self.bounds
        if let pattern = UIImage(named: "marble") {
            view.backgroundColor = UIColor(patternImage: pattern)
        }
        self.addSubview(view)
    }
    
    func setEditMode(_ mode: Bool) {
        
        print(#function, mode, txtBpm as Any, txtIncompleteMeasure as Any)
        
        if !mode {
            
        }
    }
    
    func loadViewFromNib() -> UIView? {
        
        print(#function)
        let nib = UINib(nibName: nibName, bundle: nil)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    
    @IBAction func btnActOpenPanel(_ sender: Any) {
        delegate?.didClickedSetting(self)
    }
    
    @IBAction func btnActEraser(_ sender: Any) {
        delegate?.didClickedEraser(self)
    }
    
    @IBAction func btnActUndo(_ sender: Any) {
        delegate?.didClickedUndo(self)
    }
    
    @IBAction func btnActPlaySequence(_ sender: Any) {
        delegate?.didClickedPlaySequence(self)
    }
    
    @IBAction func btnActSave(_ sender: Any) {
        delegate?.didClickedSave(self)
    }
    
    @IBAction func btnActBackToMain(_ sender: Any) {
        delegate?.didClickedBackToMain(self)
    }
    
    @IBAction func btnActReset(_ sender: Any) {
        delegate?.didClickedResetPaper(self)
    }
    
    @IBAction func btnActChangeBPM(_ sender: Any) {
        guard let bpmStr = txtBpm.text else {
            delegate?.didClickedBpmChange(self, bpm: 0)
            return
        }
        guard let bpm = Double(bpmStr) else {
            delegate?.didClickedBpmChange(self, bpm: 0)
            return
        }
        delegate?.didClickedBpmChange(self, bpm: bpm)
    }
    
    @IBAction func btnActChangeIncompleteMeasure(_ sender: Any) {
        guard let imStr = txtIncompleteMeasure.text else {
            delegate?.didIncompleteMeasureChange(self, numOf16beat: 0)
            return
        }
        guard let imInt = Int(imStr) else {
            delegate?.didIncompleteMeasureChange(self, numOf16beat: 0)
            return
        }
        delegate?.didIncompleteMeasureChange(self, numOf16beat: imInt)
    }
    
    @IBAction func btnActExtendPaper(_ sender: Any) {
        delegate?.didClickedExtendPaper(self)
    }
    
    @IBAction func btnActShrinkPaper(_ sender: Any) {
        delegate?.didClickedShrinkPaper(self)
    }
    
    
    @IBAction func btnActToggleSnapToGrid(_ sender: Any) {
        delegate?.didClickedToggleSnapToGrid(self)
    }
    
}
