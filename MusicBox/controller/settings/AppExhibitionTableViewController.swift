//
//  AppExhibitionTableViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2022/09/22.
//

import UIKit
import StoreKit

struct AppInfo {
    var title, description, imgAssetName, appStoreID: String
    
    var localizedTitle: String { title.localized }
    var localizedDescription: String { description.localized }
}

class AppExhibitionTableViewController: UITableViewController {
    
    private let infos: [AppInfo] = [
        // AppInfo(title: "Make My MusicBox", description: "description_MakeMyMusicBox", imgAssetName: "icon-MusicBox", appStoreID: "1596583920"),
        AppInfo(title: "UltimateScale", description: "description_UltimateScale", imgAssetName: "icon-UltimateScale", appStoreID: "1631310626"),
        AppInfo(title: "Tuner XR", description: "description_TunerXR", imgAssetName: "icon-TunerXR", appStoreID: "1581803256"),
        AppInfo(title: "DiffuserStick", description: "description_DiffuserStick", imgAssetName: "icon-DiffuserStick", appStoreID: "1578285458"),
        
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Other apps made by BGSMM".localized
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return infos.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AppInfoCell", for: indexPath) as! AppInfoCell
        
        let info = infos[indexPath.row]
        cell.configure(info)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        popupAppStore(identifier: infos[indexPath.row].appStoreID)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}

extension AppExhibitionTableViewController: SKStoreProductViewControllerDelegate {
    
    func popupAppStore(identifier: Any) {
        // 1631310626
        let parametersDictionary = [SKStoreProductParameterITunesItemIdentifier: identifier]
        let store = SKStoreProductViewController()
        store.delegate = self
        
        /*
         Attempt to load the selected product from the App Store. Display the store product view controller if success and print an error message,
         otherwise.
         */
        store.loadProduct(withParameters: parametersDictionary) { [unowned self] (result: Bool, error: Error?) in
            if result {
                self.present(store, animated: true, completion: {
                    print("The store view controller was presented.")
                })
            } else {
                if let error = error {
                    print(#function, "Error: \(error)")
                }
                
                if let url = URL(string: "https://apps.apple.com/app/tuner-xr/id\(identifier)") {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
}


class AppInfoCell: UITableViewCell {
    
    @IBOutlet weak var imgViewAppIcon: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    
    func configure(_ info: AppInfo) {
        imgViewAppIcon.image = UIImage(named: info.imgAssetName)
        lblTitle.text = info.localizedTitle
        lblDescription.text = info.localizedDescription
        lblDescription.sizeToFit()
    }
}
