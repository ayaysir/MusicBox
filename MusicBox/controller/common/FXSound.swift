//
//  FXSound.swift
//  MusicBox
//
//  Created by yoonbumtae on 2022/12/10.
//

import AVFoundation

enum FXSound: String {
    case punch
    case eraser
    case block
    case undo
    
    static var player: AVAudioPlayer?

    var name: String {
        switch self {
        case .punch:
            let availablePunchSounds = [
                "zapsplat_office_stapler_single_staple_into_paper_001_66589",
                "zapsplat_office_stapler_single_staple_into_paper_002_66590",
                "zapsplat_office_stapler_single_staple_into_paper_003_66591"
            ]
            let index = Int.random(in: 0...2)
            return availablePunchSounds[index]
        case .eraser:
            return "zapsplat_foley_paper_sheets_x3_construction_sugar_set_down_on_surface_003_42009"
        case .block:
            return "zapsplat_foley_wood_block_dense_heavy_small_set_down_ion_concrete_002_59957"
        case .undo:
            return "toy_musical_shaker_005"
        }
    }

    var url: URL? {
        return Bundle.main.url(forResource: self.name, withExtension: "mp3")
    }

    func play() {
        playSound(self.url!)
    }

    private func playSound(_ url: URL) {
        do {
            FXSound.player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            FXSound.player?.play()
        } catch {
            print(#function, error.localizedDescription)
        }
    }

}
