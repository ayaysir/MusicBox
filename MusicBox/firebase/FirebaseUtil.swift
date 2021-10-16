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

func getFileURL(childRefStr: String, completeHandler: @escaping FileURLBlock) {
    let storage = Storage.storage()
    let storageRef = storage.reference()
    let fileRef = storageRef.child(childRefStr)
//    let sampleImageRef = storageRef.child("PostThumbnail/\(postIdStr)/\(postIdStr).jpg")
    
    fileRef.downloadURL { url, error in
        
        if let error = error {
            print("An error has occured: \(error.localizedDescription)")
            return
        }
        
        completeHandler(url)
    }
}

