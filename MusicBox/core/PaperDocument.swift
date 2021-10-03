//
//  PaperDocument.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/30.
//

import UIKit
import AVFoundation

class PaperDocument: UIDocument {
    
    var paper: Paper?
    var error: Error?
    
    override func contents(forType typeName: String) throws -> Any {
        guard let paper = paper else { return Data() }
        
        // This method is invoked whenever a document needs to be saved.
        // Particles documents are basically blobs of encoded particle systems.
        
        return try NSKeyedArchiver.archivedData(withRootObject: paper, requiringSecureCoding: true)
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        
        // This method is invoked when loading a document from previously saved data.
        // Therefore, unarchive the stored data and use it as the particle system.
        
        guard let data = contents as? Data else {
            paper = Paper()
            return
        }
        
        guard let paper = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [Paper.self, PaperCoord.self, Note.self, NSArray.self, NSString.self, NSNumber.self], from: data) as? Paper else {
            print("PaperDocument: Failed paper decoding")
            return
        }

        self.paper = paper
        
    }
}
