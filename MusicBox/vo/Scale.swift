//
//  Scale.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/13.
//

import Foundation

enum Scale: Int, CaseIterable, Codable {
    case C, C_sharp, D, D_sharp, E, F, F_sharp, G, G_sharp, A, A_sharp, B
    
    var textValueForSharp: String {
        switch self {
        case .C: return "C"
        case .C_sharp: return "C#"
        case .D: return "D"
        case .D_sharp: return "D♯"
        case .E: return "E"
        case .F: return "F"
        case .F_sharp: return "F♯"
        case .G: return "G"
        case .G_sharp: return "G♯"
        case .A: return "A"
        case .A_sharp: return "A♯"
        case .B: return "B"
        }
    }
    
    var textValueForFlat: String {
        switch self {
        case .C: return "C"
        case .C_sharp: return "D♭"
        case .D: return "D"
        case .D_sharp: return "E♭"
        case .E: return "E"
        case .F: return "F"
        case .F_sharp: return "G♭"
        case .G: return "G"
        case .G_sharp: return "A♭"
        case .A: return "A"
        case .A_sharp: return "B♭"
        case .B: return "B"
        }
    }
    
    var textValueMixed: String {
        switch self {
        case .C: return "C"
        case .C_sharp: return "C# / D♭"
        case .D: return "D"
        case .D_sharp: return "D♯ / E♭"
        case .E: return "E"
        case .F: return "F"
        case .F_sharp: return "F♯ / G♭"
        case .G: return "G"
        case .G_sharp: return "G♯ / A♭"
        case .A: return "A"
        case .A_sharp: return "A♯ / B♭"
        case .B: return "B"
        }
    }
    
    var justIntonationRatio: [Float] {
        switch self {
        case .C: return [1, 25/24, 9/8, 6/5, 5/4, 4/3, 45/32, 3/2, 8/5, 5/3, 9/5, 15/8]
        case .C_sharp: return [15/8/2, 1, 25/24, 9/8, 6/5, 5/4, 4/3, 45/32, 3/2, 8/5, 5/3, 9/5]
        case .D: return [9/5/2, 15/8/2, 1, 25/24, 9/8, 6/5, 5/4, 4/3, 45/32, 3/2, 8/5, 5/3]
        case .D_sharp: return [5/3/2, 9/5/2, 15/8/2, 1, 25/24, 9/8, 6/5, 5/4, 4/3, 45/32, 3/2, 8/5]
        case .E: return [8/5/2, 5/3/2, 9/5/2, 15/8/2, 1, 25/24, 9/8, 6/5, 5/4, 4/3, 45/32, 3/2]
        case .F: return [3/2/2, 8/5/2, 5/3/2, 9/5/2, 15/8/2, 1, 25/24, 9/8, 6/5, 5/4, 4/3, 45/32]
        case .F_sharp: return [45/32/2, 3/2/2, 8/5/2, 5/3/2, 9/5/2, 15/8/2, 1, 25/24, 9/8, 6/5, 5/4, 4/3]
        case .G: return [4/3/2, 45/32/2, 3/2/2, 8/5/2, 5/3/2, 9/5/2, 15/8/2, 1, 25/24, 9/8, 6/5, 5/4]
        case .G_sharp: return [5/4/2, 4/3/2, 45/32/2, 3/2/2, 8/5/2, 5/3/2, 9/5/2, 15/8/2, 1, 25/24, 9/8, 6/5]
        case .A: return [6/5/2, 5/4/2, 4/3/2, 45/32/2, 3/2/2, 8/5/2, 5/3/2, 9/5/2, 15/8/2, 1, 25/24, 9/8]
        case .A_sharp: return [9/8/2, 6/5/2, 5/4/2, 4/3/2, 45/32/2, 3/2/2, 8/5/2, 5/3/2, 9/5/2, 15/8/2, 1, (25/24)]
        case .B: return [25/24/2, 9/8/2, 6/5/2, 5/4/2, 4/3/2, 45/32/2, 3/2/2, 8/5/2, 5/3/2, 9/5/2, 15/8/2, 1]
        }
    }
}
