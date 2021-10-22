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
    var bpm: Double
    
    // UID 배열
    var likes: [String: Like]
    
    internal init(postTitle: String, postComment: String, paperTitle: String, paperArtist: String, paperMaker: String, allowPaperEdit: Bool, uploadDate: Date, writerUID: String, originaFileNameWithoutExt: String, preplayArr: [PaperCoord], bpm: Double, likes: [String: Like]) {
        self.postTitle = postTitle
        self.postComment = postComment
        self.paperTitle = paperTitle
        self.paperArtist = paperArtist
        self.paperMaker = paperMaker
        self.allowPaperEdit = allowPaperEdit
        self.uploadDate = uploadDate
        self.writerUID = writerUID
        self.originaFileNameWithoutExt = originaFileNameWithoutExt
        self.preplayArr = preplayArr
        self.bpm = bpm
        self.likes = likes
    }
    
    init(dictionary: [String: Any]) throws {
        
        var dictionary = dictionary
        
        if dictionary["likes"] == nil {
            dictionary["likes"] = [:]
        }
        if dictionary["preplayArr"] == nil {
            dictionary["preplayArr"] = []
        }
        
        self = try JSONDecoder().decode(Post.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }
    
}
