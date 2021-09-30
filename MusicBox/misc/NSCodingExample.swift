//
//  NSCodingExample.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/28.
//

import Foundation

class CPUCore: NSObject, NSCoding, NSSecureCoding, Codable {
    
    var constant: Int = 1494
    var coreID = UUID().uuidString
    
    static var supportsSecureCoding: Bool = true
    
    override init() {
        super.init()
    }
    
    init(constant: Int, coreID: String) {
        super.init()
        self.constant = constant
        self.coreID = coreID
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(constant, forKey: "constant")
        coder.encode(coreID, forKey: "coreID")
    }
    
    required init?(coder: NSCoder) {
        super.init()
        
        let constant = coder.decodeInteger(forKey: "constant")
        guard let coreID = coder.decodeObject(forKey: "coreID") as? String else {
            return
        }
        
        self.constant = constant
        self.coreID = coreID
    }
}


struct CPU: Codable {
    var clock: Int!
    var constant: Int!
    var cores: [CPUCore]!

    init(clock: Int, cores: [CPUCore]) {
        self.clock = clock
        self.constant = 999
        self.cores = cores
    }
}

extension CPU {
    var encoder: CPUCoder {
        return CPUCoder(cpu: self)
    }
    
    // Nested class 'CPU.CPUCoder' has an unstable name when archiving via 'NSCoding'
    // For compatibility with existing archives, use '@objc' to record the Swift 3 runtime name
    @objc(_TtCV8MusicBox3CPU8CPUCoder) class CPUCoder: NSObject, NSCoding, NSSecureCoding {
        
        var cpu: CPU?
        
        init(cpu: CPU) {
            super.init()
            self.cpu = cpu
        }
        
        static var supportsSecureCoding: Bool = true

        func encode(with coder: NSCoder) {
            coder.encode(cpu?.clock, forKey: "clock")
            coder.encode(cpu?.constant, forKey: "constant")
            coder.encode(cpu?.cores, forKey: "cores")
            print("values", cpu?.cores as Any)
        }

        required init?(coder: NSCoder) {
            let clock = coder.decodeObject(forKey: "clock")
            let constant = coder.decodeObject(forKey: "constant")
            
            guard let cores = coder.decodeObject(forKey: "cores") as? [CPUCore] else {
                return
            }
            
            cpu = CPU(clock: clock as! Int, cores: cores)
            cpu?.constant = constant as? Int
        }
        
    }
}

class Computer: NSObject, NSCoding, NSSecureCoding, Codable {
    
    var name: String?
    var cpu: CPU?
    
    init(name: String? = nil, cpu: CPU? = nil) {
        self.name = name
        self.cpu = cpu
    }
    
    func encode(with coder: NSCoder) {
        guard let name = name else { return }
        guard let cpu = cpu else { return }
        
        let cpuCoder = cpu.encoder
        coder.encode(name, forKey: "cpu_name")
        coder.encode(cpuCoder, forKey: "cpu_coder")
    }
    
    required convenience init?(coder: NSCoder) {
        let decodedName = coder.decodeObject(forKey: "cpu_name")
        let decodedCPUCoder = coder.decodeObject(forKey: "cpu_coder") as? CPU.CPUCoder
        
        self.init(name: (decodedName as? String), cpu: decodedCPUCoder?.cpu )
        
    }
    
    static var supportsSecureCoding: Bool = true
}

