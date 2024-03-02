//
//  SelectAFileViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/09.
//

import UIKit

protocol SelectAFileVCDelegate: AnyObject {
    
    func didSelectedAFile(_ controller: SelectAFileViewController, selectedDocument: PaperDocument)
}

class SelectAFileViewController: UITableViewController {
    
    var documents: [PaperDocument] = []
    
    var delegate: SelectAFileVCDelegate?
    
    override func viewDidLoad() {
        
        do {
            documents = try loadMusicboxFileList() ?? []
        } catch {
            print(error.localizedDescription)
        }
        
    }
}

extension SelectAFileViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return documents.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FileTableViewCell", for: indexPath) as? FileTableViewCell else {
            return UITableViewCell()
        }
        
        cell.reset()
        documents[indexPath.row].open { _ in
            cell.update(document: self.documents[indexPath.row])
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let delegate = delegate {
            delegate.didSelectedAFile(self, selectedDocument: documents[indexPath.row])
        }
        self.navigationController?.popViewController(animated: true)
    }
}

class FileTableViewCell: UITableViewCell {
    
    @IBOutlet weak var imgAlbumart: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblPaperInfo: UILabel!
    @IBOutlet weak var lblOriginalArtist: UILabel!
    @IBOutlet weak var lblLastModified: UILabel!
    
    var document: PaperDocument?
    
    func reset() {
        
        imgAlbumart.image = nil
        lblTitle.text = ""
        lblPaperInfo.text = ""
        lblOriginalArtist.text = ""
        lblLastModified.text = ""
    }
    
    func update(document: PaperDocument) {
        
        self.document = document
        
        guard let paper = document.paper else {
            return
        }
        
        let bpm = "\(paper.bpm)"
        let timeSignatureText = paper.timeSignature.textValue
        
        if let data = paper.albumartImageData {
            imgAlbumart.image = UIImage(data: data)
        } else {
            imgAlbumart.image = UIImage(named: "sample")
        }
        
        lblTitle.text = paper.title
        lblPaperInfo.text = "BPM \(bpm), \(timeSignatureText)"
        lblOriginalArtist.text = paper.originalArtist
        
        if #available(iOS 15.0, *) {
            lblLastModified.text = document.fileModificationDate?.formatted()
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            if let date = document.fileModificationDate {
                let dateString = dateFormatter.string(from: date)
                lblLastModified.text = dateString
            }
        }
    }
}
