//
//  DocumentBrowserViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/27.
//

import UIKit

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        allowsDocumentCreation = true
        allowsPickingMultipleItems = false
        
        // Update the style of the UIDocumentBrowserViewController
        // browserUserInterfaceStyle = .dark
        // view.tintColor = .white
        
        // Specify the allowed content types of your application via the Info.plist.
        
        // Do any additional setup after loading the view.
        
        let url = getDocumentsDirectory().appendingPathComponent("dasfadsf").appendingPathExtension("fdfe")
        do {
            try UUID().uuidString.write(to: url, atomically: true, encoding: .utf8)
            print("akasjafjkf: ", Bundle.main.infoDictionary?["UIFileSharingEnabled"] as Any)
        } catch  {
            
        }
    }
    
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        
        simpleDestructiveYesAndNo(self, message: "파일을 만드시겠습니까?", title: "파일") { action in
            let newDocumentURL: URL? = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("musicbox")
                .appendingPathExtension("musicbox")
            
            do {
                try UUID().uuidString.write(to: newDocumentURL!, atomically: true, encoding: .utf8)
            } catch  {
                
            }
            
            // Set the URL for the new document here. Optionally, you can present a template chooser before calling the importHandler.
            // Make sure the importHandler is always called, even if the user cancels the creation request.
            
            print(#function)
            if newDocumentURL != nil {
                importHandler(newDocumentURL, .move)
            } else {
                importHandler(nil, .none)
            }
        }
        
        
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        
        // Present the Document View Controller for the first document that was picked.
        // If you support picking multiple items, make sure you handle them all.
        presentDocument(at: sourceURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }
    
    // MARK: Document Presentation
    
    func presentDocument(at documentURL: URL) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
//        let paperViewController = storyBoard.instantiateViewController(withIdentifier: "MusicPaperViewController") as! MusicPaperViewController
        let document = Document(fileURL: documentURL)
        print("document", document)
        let documentViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentViewController") as! DocumentViewController
        documentViewController.document = Document(fileURL: documentURL)
//        paperViewController.modalPresentationStyle = .fullScreen

//        present(paperViewController, animated: true, completion: nil)
        present(documentViewController, animated: true, completion: nil)
    }
}

