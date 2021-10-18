//
//  Like.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/18.
//

import Foundation

struct Like: Codable {
    
    var likeUserUID: String
    var postID: String
    var likedDate: Date
}
