//
//  PaperViewModePanelView.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/02.
//

import UIKit

protocol PaperViewModePanelViewDelegate: AnyObject {
    func didPlayButtonClicked(_ view: PaperViewModePanelView)
    func didBackToMainClicked(_ view: PaperViewModePanelView)
}

class PaperViewModePanelView: UIView {

    let nibName = "PaperViewModePanelView"
    
    weak var delegate: PaperViewModePanelViewDelegate?
    
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnBack: UIButton!
    
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
        
        btnPlay.setTitle("", for: .normal)
        btnBack.setTitle("", for: .normal)
    }
    
    func loadViewFromNib() -> UIView? {
        
        let nib = UINib(nibName: nibName, bundle: nil)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    
    @IBAction func btnActPlay(_ sender: UIButton) {
        if let delegate = delegate {
            delegate.didPlayButtonClicked(self)
        }
    }
    
    @IBAction func btnActBack(_ sender: UIButton) {
        if let delegate = delegate {
            delegate.didBackToMainClicked(self)
        }
    }
    
    
}
