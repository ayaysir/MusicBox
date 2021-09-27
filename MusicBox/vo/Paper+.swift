//
//  PaperCoord.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/13.
//

import UIKit

extension String {
  static let appExtension: String = "ptk"
  static let versionKey: String = "Version"
  static let photoKey: String = "Photo"
  static let thumbnailKey: String = "Thumbnail"
}

private extension String {
  static let dataKey: String = "Data"
  static let metadataFilename: String = "photo.metadata"
  static let dataFilename: String = "photo.data"
}

class PaperDocument: UIDocument {
    
    override var description: String {
      return fileURL.deletingPathExtension().lastPathComponent
    }

    var fileWrapper: FileWrapper?
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        print("load: ", contents, typeName)
    }
    
    override func contents(forType typeName: String) throws -> Any {
        return Data()
    }
}


class PaperData: NSObject, NSCoding {
    var paper: Paper?
    
    init(paper: Paper? = nil) {
        self.paper = paper
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(paper)
        coder.encode(1, forKey: .versionKey)
    }
    
    required init?(coder: NSCoder) {
        coder.decodeInteger(forKey: .versionKey)
        guard let paper = coder.decodeObject() as? Paper else {
            return nil
        }
        self.paper = paper
    }
}

struct Paper: Codable {
    var bpm: Int
    var coords: [PaperCoord]
    var timeSignature: TimeSignature
    
    var albumartURL: URL?
    var paperMaker: String = ""
    var title: String = "My MusicBox Score"
    var comment: String = ""
    
    var fileId: UUID = UUID()
}

struct PaperCoord: Codable {
    var id: UUID = UUID()
    var musicNote: Note
    var cgPoint: CGPoint
    var snappedPoint: CGPoint
    var gridX: Double?

    mutating func setGridX(start: CGFloat, eachCellWidth: CGFloat) {
        let currentX = snappedPoint.x
        let xCGPosFromZero = currentX - start
        self.gridX = Double(xCGPosFromZero / eachCellWidth)
    }
}

