//
//  NotConnectedViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/08.
//

import UIKit

class NotConnectedViewController: UIViewController {
    
    var vcName = "SignInViewController"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnActRetryConnect(_ sender: Any) {
        if Reachability.isConnectedToNetwork() {
            let prevVC = mainStoryboard.instantiateViewController(withIdentifier: vcName)
            self.navigationController?.setViewControllers([prevVC], animated: false)
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
