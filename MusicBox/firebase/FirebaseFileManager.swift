//
//  FirebaseFileManager.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/19.
//  https://stackoverflow.com/questions/49934195

import UIKit
import Firebase

class FirebaseFileManager: NSObject {
    
    /// Singleton instance
    static let shared: FirebaseFileManager = FirebaseFileManager()
    
    /// Path
    var kFirFileStorageRef = Storage.storage().reference().child("Files")
    
    /// Current uploading task
    var currentUploadTask: StorageUploadTask?
    
    func setChild(_ pathString: String) {
        kFirFileStorageRef = Storage.storage().reference().child(pathString)
    }
    
    func upload(data: Data,
                withName fileName: String,
                block: @escaping (_ url: URL?) -> Void) {
        
        // Create a reference to the file you want to upload
        let fileRef = kFirFileStorageRef.child(fileName)
        
        /// Start uploading
        upload(data: data, withName: fileName, atPath: fileRef) { (url) in
            block(url)
        }
    }
    
    func upload(data: Data,
                withName fileName: String,
                atPath path: StorageReference,
                block: @escaping (_ url: URL?) -> Void) {
        
        let metadata = StorageMetadata()
        let fileExt = fileName[fileName.count - 3 ..< fileName.count]
        metadata.contentType = fileExt == "jpg" ? "image/jpeg"
            : fileExt == "png" ? "image/png" : "application/octet-stream"
        
        // Upload the file to the path
        self.currentUploadTask = path.putData(data, metadata: metadata) { (metadata, error) in
            guard metadata != nil else {
                // Uh-oh, an error occurred!
                block(nil)
                return
            }
            // Metadata contains file metadata such as size, content-type.
            // let size = metadata.size
            
            // You can also access to download URL after upload.
            path.downloadURL { (url, error) in
                guard url != nil else {
                    // Uh-oh, an error occurred!
                    block(nil)
                    return
                }
                block(url)
            }
        }
    }
    
    func cancel() {
        self.currentUploadTask?.cancel()
    }
}
