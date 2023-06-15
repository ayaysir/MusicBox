//
//  FileUtil.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/27.
//

import Foundation

class FileUtil {
    
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func append(toPath path: String,
                        withPathComponent pathComponent: String) -> String? {
        if var pathURL = URL(string: path) {
            pathURL.appendPathComponent(pathComponent)
            
            return pathURL.absoluteString
        }
        
        return nil
    }
    
    func read(fromDocumentsWithFileName fileName: String) {
        guard let filePath = self.append(toPath: FileUtil.getDocumentsDirectory().absoluteString,
                                         withPathComponent: fileName) else {
            return
        }
        
        do {
            let savedString = try String(contentsOfFile: filePath)
            
            print(savedString)
        } catch {
            print("Error reading saved file")
        }
    }
    
    func save(text: String,
                      toDirectory directory: String,
                      withFileName fileName: String) throws {
        guard let filePath = self.append(toPath: directory,
                                         withPathComponent: fileName) else {
            
            return
        }
        
        do {
            try text.write(toFile: filePath,
                           atomically: true,
                           encoding: .utf8)
        } catch {
            print("Error", error)
            throw error
        }
        
    }
}
