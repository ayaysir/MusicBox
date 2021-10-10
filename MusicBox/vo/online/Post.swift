//
//  Post.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/10.
//

import Foundation

struct Post: Codable {
    
    // 파일 위치 저장소 겸용
    var postId: UUID = UUID()
    var postTitle: String
    var postComment: String
    
    var paperTitle: String
    var paperArtist: String
    var paperMaker: String
    
    var allowPaperEdit: Bool
    var uploadDate: Date
    var writerUID: String
    
    var originaFileNameWithoutExt: String
    var preplayArr: [PaperCoord]
    var bpm: Int
    
    // UID 배열
    var likes: [String]
}
