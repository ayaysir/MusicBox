//
//  WebkitViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/22.
//

import UIKit

@preconcurrency import WebKit

enum WebPageCategory {
  case license, help
}

class WebkitViewController: UIViewController {
  
  @IBOutlet weak var webView: WKWebView!
  
  var category: WebPageCategory = .help
  private var pageURL: URL!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    switch category {
    case .license:
      pageURL = Bundle.main.url(forResource: "license", withExtension: "html", subdirectory: "html")
    case .help:
      pageURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "html/help")
    }
    
    loadHTML()
  }
}

extension WebkitViewController:  WKUIDelegate, WKNavigationDelegate {
  func loadHTML() {
    // 웹 파일 로딩
    webView.uiDelegate = self
    webView.navigationDelegate = self
    
    guard let url = pageURL else {
      return
    }
    webView.loadFileURL(url, allowingReadAccessTo: url)
  }
  
  // 링크 클릭시 외부 사파리 브라우저에서 열리게 하기
  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    guard case .linkActivated = navigationAction.navigationType,
          let url = navigationAction.request.url
    else {
      decisionHandler(.allow)
      return
    }
    decisionHandler(.cancel)
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
  }
}
