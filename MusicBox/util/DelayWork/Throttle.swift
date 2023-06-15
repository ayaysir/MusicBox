//
//  Throttle.swift
//  MusicBox
//
//  Created by yoonbumtae on 2022/12/10.
//

import Foundation

class Throttle {
    
    private var workItem: DispatchWorkItem?
    private var handler: ((Date) -> Void)? = nil
    private var delay: Int!
    
    init(milliseconds delay: Int, handler: ((Date) -> Void)?) {
        self.delay = delay
        self.handler = handler
    }
    
    func run() {
        if workItem == nil {
            handler?(Date())
            let workItem = DispatchWorkItem { [weak self] in
                self?.workItem?.cancel()
                self?.workItem = nil
            }
            
            self.workItem = workItem
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .milliseconds(delay), execute: workItem)
        }
    }
}
