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
}

class PaperOptionPanelView: UIView {
    
    weak var delegate: PaperOptionPanelViewDelegate?

    let nibName = "PaperOptionPanelView"
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        guard let view = loadViewFromNib() else { return }
        view.frame = self.bounds
        self.addSubview(view)
    }
    
    func loadViewFromNib() -> UIView? {
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
}