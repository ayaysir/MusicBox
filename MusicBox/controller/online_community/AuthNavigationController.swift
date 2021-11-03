//
//  AuthNavigationController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/03.
//

import UIKit
import Firebase

class AuthNavigationController: UINavigationController {
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)

    override func viewDidLoad() {
        super.viewDidLoad()
 
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if Auth.auth().currentUser != nil {
            let memberVC = mainStoryboard.instantiateViewController(withIdentifier: "MemberProfileViewController")
            setViewControllers([memberVC], animated: false)
        } else {
            let loginVC = mainStoryboard.instantiateViewController(withIdentifier: "SignInViewController")
            setViewControllers([loginVC], animated: false)
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
