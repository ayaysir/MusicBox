//
//  Debounce.swift
//  MusicBox
//
//  Created by yoonbumtae on 2022/12/10.
//

import Foundation

class Debounce {
    
    private var workItem: DispatchWorkItem?
    private var handler: ((Date) -> Void)? = nil
    private var delay: Int!
    
    init(milliseconds delay: Int, handler: ((Date) -> Void)?) {
        self.delay = delay
        self.handler = handler
    }
    
    func run() {
        workItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.handler?(Date())
        }
        self.workItem = workItem
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .milliseconds(delay), execute: workItem)
    }
}
