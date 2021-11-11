//
//  Midi.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/22.
//

import AVFoundation

class MIDIManager {
    
    var midiPlayer: AVMIDIPlayer?
    var soundbank: URL?
    
    var musicPlayer: MusicPlayer?
    
    var headSilence: Double = 0.1
    
    var musicSequence: MusicSequence! {
        didSet {
            createAVMIDIPlayer(sequence: self.musicSequence)
            self.musicPlayer = createMusicPlayer(musicSequence)
        }
    }
    
    var currentBPM: Double = 100
    
    /// 기본 사운드폰트 사용
    convenience init() {
        let generalSoundbank = Bundle.main.url(forResource: "GeneralUser GS MuseScore v1.442", withExtension: "sf2")
        self.init(soundbank: generalSoundbank)
    }
    
    init(soundbank: URL?) {
        
        self.soundbank = soundbank
        
        self.musicSequence = createMusicSequence_바둑이()
        createAVMIDIPlayer(sequence: self.musicSequence)
        self.musicPlayer = createMusicPlayer(musicSequence)
    }
    
    deinit {
        self.soundbank = nil
        self.musicSequence = nil
        self.musicPlayer = nil
        self.midiPlayer = nil
    }
    
    func createAVMIDIPlayer(sequence musicSequence: MusicSequence) {
        
        guard let bankURL = soundbank else {
            fatalError("sound bank file not found.")
        }
        
        
        var status = noErr
        var data: Unmanaged<CFData>?
        status = MusicSequenceFileCreateData (musicSequence,
                                              MusicSequenceFileTypeID.midiType,
                                              MusicSequenceFileFlags.eraseFile,
                                              480, &data)
        
        if status != noErr {
            print("bad status \(status)")
        }
        
        if let md = data {
            let midiData = md.takeUnretainedValue() as Data
            do {
                try self.midiPlayer = AVMIDIPlayer(data: midiData as Data, soundBankURL: bankURL)
                print("created midi player with sound bank url \(bankURL)")
            } catch let error as NSError {
                print("nil midi player")
                print("Error \(error.localizedDescription)")
            }
            data?.release()
            
            self.midiPlayer?.prepareToPlay()
        }
        
    }
    
    func createAVMIDIPlayer(midiFile midiFileURL: URL?) {
        
        guard let midiFileURL = midiFileURL else {
            fatalError("midi file not found.")
        }
        
        guard let bankURL = soundbank else {
            fatalError("sound bank file not found.")
        }
        
        do {
            try self.midiPlayer = AVMIDIPlayer(contentsOf: midiFileURL, soundBankURL: bankURL)
            print("created midi player with sound bank url \(bankURL)")
        } catch let error {
            print("Error \(error.localizedDescription)")
        }
        
        self.midiPlayer?.prepareToPlay()
    }
    
    func createMusicPlayer(_ musicSequence: MusicSequence) -> MusicPlayer {
        var musicPlayer: MusicPlayer? = nil
        var status = noErr
        
        status = NewMusicPlayer(&musicPlayer)
        if status != noErr {
            print("bad status \(status) creating player")
        }
        
        status = MusicPlayerSetSequence(musicPlayer!, musicSequence)
        if status != noErr {
            print("setting sequence \(status)")
        }
        
        status = MusicPlayerPreroll(musicPlayer!)
        if status != noErr {
            print("prerolling player \(status)")
        }
        
        return musicPlayer!
    }
    
    func playMusicPlayer() {
        var status = noErr
        var playing = DarwinBoolean(false)
        
        status = MusicPlayerIsPlaying(musicPlayer!, &playing)
        if playing != false {
            print("music player is playing. stopping")
            status = MusicPlayerStop(musicPlayer!)
            if status != noErr {
                print("Error stopping \(status)")
                return
            }
        } else {
            print("music player is not playing.")
        }
        
        status = MusicPlayerSetTime(musicPlayer!, 0)
        if status != noErr {
            print("setting time \(status)")
            return
        }
        
        status = MusicPlayerStart(musicPlayer!)
        if status != noErr {
            print("Error starting \(status)")
            return
        }
    }
    
    func stopMusicPlayer() {
        let status = MusicPlayerStop(musicPlayer!)
        if status != noErr {
            print("Error stopping \(status)")
            return
        }
        
    }
}

