//
//  FileCollectionViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/30.
//

import UIKit
import PanModal

class FileCollectionViewController: UICollectionViewController {
    
    let filemgr = FileManager.default
    
    let sectionInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    
    var documents: [PaperDocument] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        do {
            // Get the directory contents urls (including subfolders urls)
            let files = try filemgr.contentsOfDirectory(at: dirPaths, includingPropertiesForKeys: nil)

            // if you want to filter the directory contents you can do like this:
            print("document file list:", files)
            
            documents = files.map { url in
                let document = PaperDocument(fileURL: url)
                return document
            }

        } catch {
            print(error)
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

extension FileCollectionViewController: UICollectionViewDelegateFlowLayout  {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        documents.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "newCell", for: indexPath)
            
            return cell
        }
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileCell", for: indexPath) as?
                FileCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        print(documents)
        documents[indexPath.row].open { _ in
            cell.update(paper: self.documents[indexPath.row].paper)
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        if indexPath.row == 0 {
            let modalVC = storyBoard.instantiateViewController(withIdentifier: "CreateNewPaperViewController") as! CreateNewPaperViewController
            modalVC.delegate = self
            self.dismiss(animated: true, completion: nil)
            presentPanModal(modalVC)
        } else {
            let musicPaperVC = storyBoard.instantiateViewController(withIdentifier: "MusicPaperViewController") as! MusicPaperViewController
            
            documents[indexPath.row].open { success in
                if success {
                    musicPaperVC.document = self.documents[indexPath.row]
                    self.present(musicPaperVC, animated: true, completion: nil)
                }
            }
            
        }
    }
    
    // 사이즈 결정
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // 140 : 200 = 1.43
        let width = collectionView.frame.width
        
        let itemsPerRow: CGFloat = 2
        let widthPadding = sectionInsets.left * (itemsPerRow + 1)
        
        let cellWidth = (width - widthPadding) / itemsPerRow
        let cellHeight = cellWidth * 1.43
        
        print("cellSize:", cellWidth, cellHeight)
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

extension FileCollectionViewController: CreateNewPaperVCDelegate {
    func didNewPaperCreated(_ controller: CreateNewPaperViewController, newPaper: Paper, fileNameWithoutExt: String) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let paperViewController = storyBoard.instantiateViewController(withIdentifier: "MusicPaperViewController") as! MusicPaperViewController

        paperViewController.modalPresentationStyle = .fullScreen
        
        let paperURL = FileUtil.getDocumentsDirectory().appendingPathComponent(fileNameWithoutExt).appendingPathExtension("musicbox")
        
        let paperDocument = PaperDocument(fileURL: paperURL)
        paperDocument.paper = newPaper
        paperViewController.document = paperDocument
        paperViewController.currentFileName = fileNameWithoutExt
        
        dismiss(animated: true, completion: nil)
        present(paperViewController, animated: true, completion: nil)
    }
    
}

class FileCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imgAlbumart: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblArtist: UILabel!
    @IBOutlet weak var lblPaperMaker: UILabel!
    
    func update(paper: Paper?) {
        guard let paper = paper else { return }
        lblTitle.text = paper.title
        lblArtist.text = paper.originalArtist
        lblPaperMaker.text = paper.paperMaker
        print(paper.originalArtist)
    }
    
}

class fileViewModel {
    
}
