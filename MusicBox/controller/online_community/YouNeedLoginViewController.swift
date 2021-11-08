//
//  YouNeedLoginViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/08.
//

import UIKit
import Firebase

class YouNeedLoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if Auth.auth().currentUser != nil {
            let postListVC = mainStoryboard.instantiateViewController(withIdentifier: "UserCommunityViewController")
            self.navigationController?.setViewControllers([postListVC], animated: false)
        }
    }
    
    @IBAction func btnActGoToLoginPage(_ sender: Any) {
        self.tabBarController?.selectedIndex = 2
    }
    

}
