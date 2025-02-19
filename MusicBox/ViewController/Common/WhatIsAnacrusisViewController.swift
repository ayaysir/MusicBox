//
//  WhatIsAnacrusisViewController.swift
//  MusicBox
//
//  Created by 윤범태 on 2/20/25.
//

import UIKit

class WhatIsAnacrusisViewController: UIViewController {
  @IBOutlet weak var txvContent: UITextView!
  @IBOutlet weak var cnstTxvContentHeight: NSLayoutConstraint!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    txvContent.text = "what_is_anacrusis_content".localized
  }
  
  override func viewDidAppear(_ animated: Bool) {
    fitTxvHeight()
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    
    coordinator.animate(alongsideTransition: nil) { _ in
      self.fitTxvHeight()
    }
  }
  
  // 텍스트의 양에 따라 높이를 자동 조절
  func fitTxvHeight() {
    let size = txvContent.sizeThatFits(CGSize(width: txvContent.bounds.width, height: .greatestFiniteMagnitude))
    cnstTxvContentHeight.constant = size.height
  }
}
