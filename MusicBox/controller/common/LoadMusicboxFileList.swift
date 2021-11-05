//
//  LoadMusicboxFileList.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/09.
//

import UIKit

func loadMusicboxFileList() throws -> [PaperDocument]? {
    let filemgr = FileManager.default
    guard let documentDirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return nil
    }
    
    print("document directory path:", documentDirPaths.absoluteString.replacingOccurrences(of: "file://", with: ""))
    
    // Get the directory contents urls (including subfolders urls)
    let files = try filemgr.contentsOfDirectory(at: documentDirPaths, includingPropertiesForKeys: nil)
    let musicboxFiles = files.filter { (url: URL) in
        return url.pathExtension == "musicbox"
    }

    // if you want to filter the directory contents you can do like this:
    return musicboxFiles.map { url in
        let document = PaperDocument(fileURL: url)
        return document
    }
}
