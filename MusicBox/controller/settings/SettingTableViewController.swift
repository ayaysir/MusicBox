//
//  SettingTableViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/11.
//

import UIKit
import GoogleMobileAds

class SettingTableViewController: UITableViewController {

    private var bannerView: GADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // ====== 광고 ====== //
        if AdManager.productMode {
            bannerView = setupBannerAds(self, adUnitID: AdInfo.shared.setting)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "TextureSegue":
            let category = sender as! String
            let vc = segue.destination as! TextureCollectionViewController
            vc.category = category == "paper" ? .paper : .background
        case "GoToWebViewSegue":
            let pageName = sender as! String
            let vc = segue.destination as! WebkitViewController
            vc.pageName = pageName
        default:
            break
        }
        
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
        if indexPath.section == 0 {
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
        } else if indexPath.section == 2 {
            switch indexPath.row {
            case 0:
                break
            case 1:
                performSegue(withIdentifier: "GoToWebViewSegue", sender: "license")
            default:
                break
            }
        }
    }
    
}
