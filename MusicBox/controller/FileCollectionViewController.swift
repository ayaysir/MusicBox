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

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try filemgr.contentsOfDirectory(at: dirPaths, includingPropertiesForKeys: nil)

            // if you want to filter the directory contents you can do like this:
            print("document file list:", directoryContents)

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
        5
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == 0 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "newCell", for: indexPath) as?
                    UICollectionViewCell else {
                return UICollectionViewCell()
            }
            
            return cell
        }
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileCell", for: indexPath) as?
                UICollectionViewCell else {
            return UICollectionViewCell()
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath.row)
        if indexPath.row == 0 {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let modalVC = storyBoard.instantiateViewController(withIdentifier: "CreateNewPaperViewController") as! CreateNewPaperViewController
            modalVC.delegate = self
            self.dismiss(animated: true, completion: nil)
            presentPanModal(modalVC)
        } else {
            
        }
    }
    
    // 사이즈 결정
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // 140 : 200 = 1.43
        let width = collectionView.frame.width
        let height = collectionView.frame.height
        
        let itemsPerRow: CGFloat = 2
        let widthPadding = sectionInsets.left * (itemsPerRow + 1)
        let itemsPerColumn: CGFloat = 3
        let heightPadding = sectionInsets.top * (itemsPerColumn + 1)
        
        let cellWidth = (width - widthPadding) / itemsPerRow
        let cellHeight = cellWidth * 1.43
//        let cellHeight = (height - heightPadding) / itemsPerColumn
        
        //
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
        paperViewController.bpm = newPaper.bpm
        paperViewController.imBeatCount = newPaper.incompleteMeasureBeat
        paperViewController.currentFileName = fileNameWithoutExt
        
        dismiss(animated: true, completion: nil)
        present(paperViewController, animated: true, completion: nil)
    }
    
}
