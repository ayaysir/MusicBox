//
//  SettingTableViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/11.
//

import UIKit
import MessageUI
import GoogleMobileAds

class SettingTableViewController: UITableViewController {
    private var bannerView: GADBannerView!

    private let SECTION_BANNER = 4
    private var section_config = 0
    private var section_inapp = 1
    private var section_informations = 2
    private var section_links = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // ====== 광고 ====== //
        TrackingTransparencyPermissionRequest()
        if AdManager.productMode {
            bannerView = setupBannerAds(self, adUnitID: AdInfo.shared.setting)
        }
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
        if indexPath.section == section_config {
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
        } else if indexPath.section == section_informations {
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "GoToWebViewSegue", sender: WebPageCategory.help)
            case 1:
                performSegue(withIdentifier: "GoToWebViewSegue", sender: WebPageCategory.license)
            default:
                break
            }
        } else if indexPath.section == section_links {
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
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == SECTION_BANNER && !AdManager.productMode {
            return 0.1
        }
        
        return super.tableView(tableView, heightForFooterInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SECTION_BANNER {
            return 0
        }
        
        return super.tableView(tableView, numberOfRowsInSection: section)
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
