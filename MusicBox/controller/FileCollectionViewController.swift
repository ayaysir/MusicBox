//
//  FileCollectionViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/30.
//

import UIKit
import PanModal
import DropDown
import Photos

class FileCollectionViewController: UICollectionViewController {

    let btnAdd = UIButton()
    let sectionInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    
    let filemgr = FileManager.default
    var documents: [PaperDocument] = []
    
    let menuDropDown = DropDown()
    let menuDataSource = ["곡 정보 변경", "게시판에 공유", "삭제"]
    
    var selectedCellIndexPath: IndexPath?
    
    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
    
    var midiManager: MIDIManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        askPhotoAuth()
        
        setMenuDropDown()
        setGestures()
        loadFileList()
        addButton()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadAndRefresh), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        collectionView.performBatchUpdates(nil) { result in
            print(Date(), "loadcomplete")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        reloadAndRefresh()
    }
    
    @objc func reloadAndRefresh() {
        loadFileList(reloadCollectionView: true)
    }
    
    private func addButton(){
        btnAdd.translatesAutoresizingMaskIntoConstraints = false
        
        btnAdd.setTitleColor(.white, for: .normal)
        btnAdd.tintColor = .white
        if let plus = UIImage(systemName: "plus") {
            btnAdd.setImage(plus, for: .normal)
        } else {
            btnAdd.setTitle("+", for: .normal)
        }
        btnAdd.backgroundColor = .systemPink
        
        let buttonWidth: CGFloat = 67
        
        self.view.addSubview(btnAdd)
        let guide = self.view.safeAreaLayoutGuide
        btnAdd.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20).isActive = true
        btnAdd.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -20).isActive = true
        btnAdd.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        btnAdd.heightAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        
        btnAdd.contentVerticalAlignment = .fill
        btnAdd.contentHorizontalAlignment = .fill
        let insetValue: CGFloat = 10
        
        btnAdd.layer.cornerRadius = buttonWidth * 0.5
        btnAdd.clipsToBounds = true
        
        btnAdd.imageEdgeInsets = UIEdgeInsets(top: insetValue, left: insetValue, bottom: insetValue * 2, right: insetValue * 2)
        
        print(btnAdd.bounds) // (0.0, 0.0, 0.0, 0.0)
        btnAdd.addTarget(self, action: #selector(touchedAddButton), for: .touchUpInside)
    }
    
    @objc private func touchedAddButton() {
        
//        let modalVC = storyBoard.instantiateViewController(withIdentifier: "CreateNewPaperViewController") as! CreateNewPaperViewController
//        modalVC.delegate = self
//        presentPanModal(modalVC)
        self.dismiss(animated: true, completion: nil)
        performSegue(withIdentifier: "PaperCreateWindowSegue", sender: nil)
    }
    
    private func setGestures() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.delaysTouchesBegan = true
        longPressGesture.delegate = self
        self.collectionView.addGestureRecognizer(longPressGesture)
    }
    
    private func loadFileList(reloadCollectionView: Bool = false) {
        
        do {
            documents = try loadMusicboxFileList() ?? []

            if reloadCollectionView {
                collectionView.reloadSections(NSIndexSet(index: 0) as IndexSet)
            }
            
        } catch {
            print(error)
        }
    }
    
    private func askPhotoAuth() {
        PHPhotoLibrary.requestAuthorization { status in
            return
        }
        
        AVCaptureDevice.requestAccess(for: .video) { granted in

        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PaperCreateWindowSegue" {
            let vc = segue.destination as? CreateNewPaperTableViewController
            vc?.delegate = self
        }
    }
}

extension FileCollectionViewController: UIGestureRecognizerDelegate {
    
    @objc func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state != UIGestureRecognizer.State.ended {
            return
        }
        
        let p = gestureReconizer.location(in: self.collectionView)
        let indexPath = self.collectionView.indexPathForItem(at: p)
        
        if let index = indexPath {
            if index.row == 0 {
                return
            }
            
            let cell = self.collectionView.cellForItem(at: index)
            // do stuff with your cell, for example print the indexPath
            
            selectedCellIndexPath = index
            menuDropDown.anchorView = cell
            menuDropDown.show()
                
            print(index.row)
        } else {
            print("Could not find index path")
        }
    }
}

extension FileCollectionViewController: UICollectionViewDelegateFlowLayout  {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        documents.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileCell", for: indexPath) as?
                FileCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.reset()
        
        documents[indexPath.row].open { _ in
            cell.update(document: self.documents[indexPath.row])
            
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
            let musicPaperVC = storyBoard.instantiateViewController(withIdentifier: "MusicPaperViewController") as! MusicPaperViewController
            
            documents[indexPath.row].open { success in
                if success {
                    musicPaperVC.document = self.documents[indexPath.row]
                    musicPaperVC.delegate = self
                    self.present(musicPaperVC, animated: true, completion: nil)
                } else {
                    simpleAlert(self, message: "파일이 없거나 손상되었습니다.", title: "파일을 열 수 없음", handler: nil)
                }
            }
            
//        }
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
    func didNewPaperCreated(_ controller: CreateNewPaperTableViewController, newPaper: Paper, fileNameWithoutExt: String) {
        
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

extension FileCollectionViewController {
    func setMenuDropDown() {
        menuDropDown.dataSource = menuDataSource
        menuDropDown.cornerRadius = 15
        menuDropDown.bottomOffset = CGPoint(x: 0, y: 20)
        menuDropDown.width = 120
        
        menuDropDown.selectionAction = { [unowned self] (index: Int, item: String) in

            print(index, item)
            switch index {
            case 0:
                break
            case 1:
                break
            case 2:
                print("delete")
                simpleDestructiveYesAndNo(self, message: "이 파일을 삭제하시겠습니까?", title: "파일 삭제") { action in
                    guard let index = selectedCellIndexPath else {
                        return
                    }
                    
                    let target = collectionView.cellForItem(at: index) as? FileCollectionViewCell
                    guard let document = target?.document else {
                        return
                    }
                    
                    do {
                        try filemgr.removeItem(at: document.fileURL)
                        loadFileList()
                        reloadAndRefresh()
                        simpleAlert(self, message: "삭제되었습니다.", title: "삭제 완료", handler: nil)
                    } catch  {
                        print(error.localizedDescription)
                    }
                }
            default:
                break
            }

        }
    }
}

extension FileCollectionViewController: MusicPaperVCDelegate {
    
    func didPaperEditFinished(_ controller: MusicPaperViewController) {
        reloadAndRefresh()
    }
    
}

class FileCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imgAlbumart: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblArtist: UILabel!
    @IBOutlet weak var lblPaperMaker: UILabel!
    
    var document: PaperDocument?
    
    func reset() {
        imgAlbumart.image = nil
        lblTitle.text = ""
        lblArtist.text = ""
        lblPaperMaker.text = ""
    }
    
    func update(document: PaperDocument?) {
        
        self.document = document
        guard document != nil, let paper = document!.paper else { return }
        
        lblTitle.text = paper.title
        lblArtist.text = paper.originalArtist
        lblPaperMaker.text = paper.paperMaker
        
        if let data = paper.albumartImageData {
            imgAlbumart.image = UIImage(data: data)
        } else {
            imgAlbumart.image = UIImage(named: "sample")
        }
    }
    
}

class fileViewModel {
    
}
