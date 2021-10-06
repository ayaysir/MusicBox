//
//  TimeSignature.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/06.
//

import Foundation

struct GridInfo: Equatable {
    /*
     var whenDrawAThickLineEveryBars = 4
     var whenToggleBackgroundColorEveryBars = 8
     */
    
    var boldLineInterval = 4
    var bolderLineInterval = 16
    var toggleBackgroundInterval = 8
    
}

struct TimeSignature: Codable {
    
    var upper: Int
    var lower: Int
    
    init() {
        self.init(upper: 4, lower: 4)
    }
    
    init(upper: Int, lower: Int) {
        self.upper = upper
        self.lower = lower
    }
    
}

extension TimeSignature {
    var gridInfo: GridInfo {
        
        var outGrid = GridInfo()
        
        if lower % 2 == 0 {
            outGrid.boldLineInterval = 16 / lower
            outGrid.bolderLineInterval = outGrid.boldLineInterval * upper
            
            if upper >= 12 {
                outGrid.toggleBackgroundInterval = upper 
            } else if upper % 4 == 0 {
                outGrid.toggleBackgroundInterval = outGrid.boldLineInterval * 2
            } else if upper % 3 == 0 {
                outGrid.toggleBackgroundInterval = outGrid.boldLineInterval * 3
            } else {
                outGrid.toggleBackgroundInterval = outGrid.boldLineInterval
            }
        }
        
        /*
         2 -> 8 = 16 ==> x = 16 / 2
         4 -> 4 = 16
         8 -> 2 = 16
         16 -> 1 = 16
         
         */
        
        return outGrid
    }
}
