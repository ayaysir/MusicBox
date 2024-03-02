//
//  Document.swift
//  documentBased
//
//  Created by yoonbumtae on 2021/09/27.
//

import UIKit

class Document: UIDocument {
    
    var content: Data? = nil
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        print("content: ", typeName)
        return Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
        self.content = contents as? Data
    }
    
    func getMessage() -> String? {
        guard let data = content else {
            return nil
        }
        guard let message = String(bytes: data, encoding: .utf8) else {
            return nil
        }
        return message
    }
    
    
}

