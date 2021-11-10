//
//  SettingTableViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/11.
//

import UIKit

class SettingTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TextureSegue" {
            let category = sender as! String
            let vc = segue.destination as! TextureCollectionViewController
            vc.category = category == "paper" ? .paper : .background
            
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "TextureSegue", sender: "paper")
            case 1:
                performSegue(withIdentifier: "TextureSegue", sender: "background")
            case 2:
                break
            default:
                break
            }
        }
    }
    
}
