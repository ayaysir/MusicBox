//
//  UploadFormViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/09.
//

import UIKit

class UploadFormViewController: UIViewController {
    
    @IBOutlet weak var lblSelectedPaperMaker: UILabel!
    @IBOutlet weak var lblSelectedArtist: UILabel!
    @IBOutlet weak var lblSelectedTitle: UILabel!
    @IBOutlet weak var imgSelectedAlbumart: UIImageView!

    @IBOutlet weak var selectAFileButtonView: UIView!
    
    var selectedDocument: PaperDocument!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "SelectAFileSegue" {
            let controller = segue.destination as? SelectAFileViewController
            controller?.delegate = self
        }
    }
    
    @IBAction func btnActReselectAFile(_ sender: Any) {
        performSegue(withIdentifier: "SelectAFileSegue", sender: nil)
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

extension UploadFormViewController: SelectAFileVCDelegate {
    
    func didSelectedAFile(_ controller: SelectAFileViewController, selectedDocument: PaperDocument) {
        
        guard let paper = selectedDocument.paper else {
            return
        }
        
        if let data = paper.albumartImageData {
            imgSelectedAlbumart.image = UIImage(data: data)
        } else {
            imgSelectedAlbumart.image = UIImage(named: "sample")
        }
        
        lblSelectedTitle.text = paper.title
        lblSelectedArtist.text = paper.originalArtist
        lblSelectedPaperMaker.text = paper.paperMaker
        
        selectAFileButtonView.isHidden = true
        self.selectedDocument = selectedDocument
    }
    
    
}
