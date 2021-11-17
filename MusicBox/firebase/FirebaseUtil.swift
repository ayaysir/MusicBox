//
//  FirebaseUtil.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/09.
//

import Firebase

func getCurrentUser() -> User? {
    return Auth.auth().currentUser
}

func getCurrentUserUID() -> String? {
    return Auth.auth().currentUser?.uid
}

func getFileURL(childRefStr: String, completeHandler: @escaping FileURLBlock, failedHandler: @escaping ErrorBlock) {
    let storage = Storage.storage()
    let storageRef = storage.reference()
    let fileRef = storageRef.child(childRefStr)
    
    fileRef.downloadURL { url, error in
        
        if let error = error {
            failedHandler(error)
            return
        }
        
        completeHandler(url)
    }
}

func getFileAndSave(childRefSTr: String, fileSaveURL: URL, completeHandler: @escaping FileURLBlock) {
    let storage = Storage.storage()
    let storageRef = storage.reference()
    let fileRef = storageRef.child(childRefSTr)
    
    fileRef.write(toFile: fileSaveURL) { fileSaveURL, error in
        
        if let error = error {
            print("An error has occured: \(error.localizedDescription)")
            return
        }
        
        completeHandler(fileSaveURL)
    }
}

func getDatabaseRef() -> DatabaseReference {
    return Database.database().reference()
}

func getNickname(of uid: String, completeHandler: @escaping StringBlock) {
    let ref = Database.database().reference()
    ref.child("users").child(uid).child("nickname").getData { error, snapshot in
        if let error = error {
            print("get nickname failed:", error.localizedDescription)
            return
        }
        
        if snapshot.exists() {
//            self.lblUserNickname.text = snapshot.value as? String
            let snapshotText = snapshot.value as? String
            completeHandler(snapshotText)
        }
    }
}
