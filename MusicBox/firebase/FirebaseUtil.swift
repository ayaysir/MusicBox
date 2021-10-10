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
