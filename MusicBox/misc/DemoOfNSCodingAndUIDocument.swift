//
//  DemoOfNSCodingAndUIDocument.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/30.
//

import UIKit

extension HomeViewController {
    func documentExample() {
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: dirPaths, includingPropertiesForKeys: nil)
            print(directoryContents)

            // if you want to filter the directory contents you can do like this:
            print("file list:", directoryContents)

        } catch {
            print(error)
        }
        
        var document: PaperDocument?
        var documentURL: URL?

        documentURL = dirPaths.appendingPathComponent("savefile.musicbox")
        document = PaperDocument(fileURL: documentURL!)
        let paper = Paper(bpm: 400, coords: [PaperCoord(musicNote: Note(note: .A, octave: 4), absoluteTouchedPoint: CGPoint(), gridX: 4, gridY: 4)], timeSignature: TimeSignature())
        paper.comment = "dfdafd"
        paper.title = "aaaaa"
        paper.paperMaker = "afdfas"
        
        document?.paper = paper
        
        if filemgr.fileExists(atPath: (documentURL?.path)!) {

            document?.open(completionHandler: {(success: Bool) -> Void in
                if success {
                    print("File open OK")
                    print(document?.paper?.coords as Any)
                } else {
                    print("Failed to open file")
                }
            })
        } else {
            document?.save(to: documentURL!, for: .forCreating,
                     completionHandler: {(success: Bool) -> Void in
                if success {
                    print("File created OK")
                } else {
                    print("Failed to create file ")
                }
            })
        }
    }
    
    func nsCodingPaperExample() {
        
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let paper = Paper(bpm: 400, coords: [PaperCoord(musicNote: Note(note: .A, octave: 4), absoluteTouchedPoint: CGPoint(), gridX: 4, gridY: 4)], timeSignature: TimeSignature())
        paper.comment = "dfdafd"
        paper.title = "aaaaa"
        paper.paperMaker = "afdfas"


        do {
            let url = dirPaths.appendingPathComponent("savefile").appendingPathExtension("musicbox")
            let archived = try NSKeyedArchiver.archivedData(withRootObject: paper, requiringSecureCoding: true)
            try archived.write(to: url)
            print("archived success:", archived)
            
            let dataFromDisk = try Data(contentsOf: url)
            guard let unarchived = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [Paper.self, PaperCoord.self, Note.self, NSArray.self, NSString.self, NSNumber.self], from: dataFromDisk) as? Paper else {
                return
            }
            print(unarchived.coords, unarchived.fileId, unarchived.comment)
            
        } catch {
            print(error)
        }
    }
    
    func nscodingExample() {
        let cpu = CPU(clock: 1, cores: [CPUCore(), CPUCore(), CPUCore(), CPUCore()])
        let computer = Computer(name: "sejin", cpu: cpu)
        print(FileUtil.getDocumentsDirectory())


        do {
            let url = FileUtil.getDocumentsDirectory().appendingPathComponent("ss").appendingPathExtension("ccc")
            let archived = try NSKeyedArchiver.archivedData(withRootObject: computer, requiringSecureCoding: false)
            try archived.write(to: url)
            print("archived success:", archived)
            
            let dataFromDisk = try Data(contentsOf: url)
            guard let unarchived = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [Computer.self, NSString.self, NSNumber.self, CPU.CPUCoder.self, CPUCore.self, NSArray.self], from: dataFromDisk) as? Computer else {
                return
            }
            print(unarchived.cpu!, unarchived.name!, unarchived.cpu!.cores![0].coreID)
            
        } catch {
            print(error)
        }
    }
}
