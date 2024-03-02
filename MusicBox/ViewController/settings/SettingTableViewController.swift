//
//  SettingTableViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/11.
//

import UIKit
import MessageUI
import StoreKit
import GoogleMobileAds
import SwiftSpinner

class SettingTableViewController: UITableViewController {
    private var bannerView: GADBannerView!

    private var SECTION_CONFIG = 0
    private var SECTION_IAP = 1
    private var SECTION_INFOS = 2
    private var SECTION_LINKS = 3
    private let SECTION_BANNER = 4
    
    private var iapProducts: [SKProduct]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // ====== 광고 ====== //
        TrackingTransparencyPermissionRequest()
        if AdManager.isReallyShowAd {
            bannerView = setupBannerAds(self, adUnitID: AdInfo.shared.setting)
        }
        
        initIAP()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        bannerView?.fitInView(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "TextureSegue":
            let category = sender as! String
            let vc = segue.destination as! TextureCollectionViewController
            vc.category = category == "paper" ? .paper : .background
        case "GoToWebViewSegue":
            let pageCategory = sender as! WebPageCategory
            let vc = segue.destination as! WebkitViewController
            vc.category = pageCategory
        default:
            break
        }
    }
}

extension SettingTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
        if indexPath.section == SECTION_CONFIG {
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "TextureSegue", sender: "paper")
            case 1:
                performSegue(withIdentifier: "TextureSegue", sender: "background")
            case 2:
                performSegue(withIdentifier: "MIDISegue", sender: nil)
            default:
                break
            }
        } else if indexPath.section == SECTION_INFOS {
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "GoToWebViewSegue", sender: WebPageCategory.help)
            case 1:
                performSegue(withIdentifier: "GoToWebViewSegue", sender: WebPageCategory.license)
            default:
                break
            }
        } else if indexPath.section == SECTION_LINKS {
            switch indexPath.row {
            case 0:
                launchEmail()
            case 1:
                if let url = URL(string: "https://github.com/ayaysir/MusicBox"), !url.absoluteString.isEmpty {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            default:
                break
            }
            
            tableView.deselectRow(at: indexPath, animated: false)
        } else if indexPath.section == SECTION_IAP {
            switch indexPath.row {
            case 1...:
                if let iapProducts {
                    purchaseIAP(productID: iapProducts[indexPath.row - 1].productIdentifier)
                }
            case 0:
                restoreIAP()
            default:
                break
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == SECTION_BANNER && AdManager.isReallyShowAd {
            return 50
        }
        
        return super.tableView(tableView, heightForFooterInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SECTION_BANNER {
            return 0
        } else if section == SECTION_IAP {
            return 1 + InAppProducts.productIDs.count
        }
        
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == SECTION_BANNER {
            return "APP VERSION: \(AppInfoUtil.appVersionAndBuild())"
        }
        
        return super.tableView(tableView, titleForHeaderInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
            if indexPath.section == SECTION_IAP,
               let firstLabel = cell.contentView.subviews[0] as? UILabel,
               let iapProducts, !iapProducts.isEmpty, indexPath.row != 0 {
                let index = indexPath.row - 1
                let currentProduct = iapProducts[index]
                let isPurchased = InAppProducts.helper.isProductPurchased(currentProduct.productIdentifier)
                firstLabel.text = isPurchased ? "[구입 완료] " : ""
                firstLabel.text! += iapProducts[index].localizedTitle
                
                if let localizedPrice = iapProducts[index].localizedPrice {
                    firstLabel.text! += " (\(localizedPrice))"
                }
                
                firstLabel.textColor = isPurchased ? .lightGray : nil
            }
            
            return cell
        }
}

extension SettingTableViewController: MFMailComposeViewControllerDelegate {
    
    func launchEmail() {
        guard MFMailComposeViewController.canSendMail() else {
            // 사용자의 메일 계정이 설정되어 있지 않아 메일을 보낼 수 없다는 경고 메시지 추가
            simpleAlert(self, message: "The mail cannot be sent because the mail account has not been set up on the device.".localized)
            return
        }
        
        let emailTitle = "Make My MusicBox: Feedback".localized // 메일 제목
        let messageBody =
        """
        OS Version: \(UIDevice.current.systemVersion)
        Device: \(UIDevice().type)
        App Version: \(AppInfoUtil.appVersionAndBuild())
        
        """
        
        let toRecipents = [AdInfo.shared.developerMail]
        let mc: MFMailComposeViewController = MFMailComposeViewController()
        mc.mailComposeDelegate = self
        mc.setSubject(emailTitle)
        mc.setMessageBody(messageBody, isHTML: false)
        mc.setToRecipients(toRecipents)
        
        self.present(mc, animated: true, completion: nil)
    }
    
    @objc(mailComposeController:didFinishWithResult:error:)
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult,error: Error?) {
        controller.dismiss(animated: true)
    }
    
}

/*
 ===> 인앱 결제로 광고 제거
 */
extension SettingTableViewController {
    private func initIAP() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleIAPPurchase(_:)), name: .IAPHelperPurchaseNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hadnleIAPError(_:)), name: .IAPHelperErrorNotification, object: nil)
        
        // IAP 불러오기
        InAppProducts.helper.inquireProductsRequest { [weak self] (success, products) in
            guard let self, success else { return }
            self.iapProducts = products
            
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      let products else {
                    return
                }
                
                // 불러오기 후 할 UI 작업
                tableView.reloadSections([SECTION_IAP], with: .none)
                
                products.forEach {
                    if !InAppProducts.helper.isProductPurchased($0.productIdentifier) {
                        print("\($0.localizedTitle) (\($0.price))")
                    }
                }
            }
        }
        
        if InAppProducts.helper.isProductPurchased(InAppProducts.productIDs[0]) || UserDefaults.standard.bool(forKey: InAppProducts.productIDs[0]) {
            // 이미 구입한 경우 UI 업데이트 작업
        }
    }
    
    /// 구매: 인앱 결제 버튼 눌렀을 때
    private func purchaseIAP(productID: String) {
        if let product = iapProducts?.first(where: {productID == $0.productIdentifier}),
           !InAppProducts.helper.isProductPurchased(productID) {
            InAppProducts.helper.buyProduct(product)
            SwiftSpinner.show("Processing in-app purchase operation.\nPlease wait...".localized)
        } else {
            simpleAlert(self, message: "Your purchase has been completed. You will no longer see ads in the app. If ads are not removed from some screens, force quit the app and relaunch it.".localized, title: "Purchase completed".localized, handler: nil)
        }
    }
    
    /// 복원: 인앱 복원 버튼 눌렀을 때
    private func restoreIAP() {
        InAppProducts.helper.restorePurchases()
    }
    
    /// 결제 후 Notification을 받아 처리
    @objc func handleIAPPurchase(_ notification: Notification) {
        guard notification.object is String else {
            simpleAlert(self, message: "Purchase failed: Please try again.".localized)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            simpleAlert(self, message: "Your purchase has been completed. You will no longer see ads in the app. If ads are not removed from some screens, force quit the app and relaunch it.".localized, title: "Purchase completed".localized) { [weak self] action in
                guard let self else { return }
                // 결제 성공하면 해야할 작업...
                // 1. 로딩 인디케이터 숨기기
                SwiftSpinner.hide()
                
                // 2. 세팅VC 광고 제거 (나머지 뷰는 다시 들어가면 제거되어 있음)
                if let bannerView {
                    bannerView.removeFromSuperview()
                }
                                
                // 3. 버튼 UI 업데이트
                tableView.reloadData()
            }
        }
    }
    
    // 에러 발생시(결제 취소 포함) 작업
    @objc func hadnleIAPError(_ notification: Notification) {
        SwiftSpinner.hide()
    }
}
