//
//  HomeViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/27.
//

import UIKit

class HomeViewController: UIViewController {
    
    override func viewDidLoad() {


    }
    
    @IBAction func btnActOpenFileBrowser(_ sender: Any) {
        
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
