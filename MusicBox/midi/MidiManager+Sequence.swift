//
//  MidiManager+SequenceSample.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/24.
//

import AVFoundation

extension MIDIManager {
    func convertPaperToMIDI(paperCoords coords: [PaperCoord]) -> MusicSequence? {
        // create the sequence
        var musicSequence: MusicSequence?
        var status = NewMusicSequence(&musicSequence)
        if status != noErr {
            print(" bad status \(status) creating sequence")
        }
        
        var tempoTrack: MusicTrack?
        if MusicSequenceGetTempoTrack(musicSequence!, &tempoTrack) != noErr {
            assert(tempoTrack != nil, "Cannot get tempo track")
        }
        //MusicTrackClear(tempoTrack, 0, 1)
        
        let bpm: Double = currentBPM
        if MusicTrackNewExtendedTempoEvent(tempoTrack!, 0.0, Float64(bpm)) != noErr {
            print("could not set tempo")
        }
        
        // add a track
        var track: MusicTrack?
        status = MusicSequenceNewTrack(musicSequence!, &track)
        if status != noErr {
            print("error creating track \(status)")
        }
        
        // bank select msb
        var chMsg = MIDIChannelMessage(status: 0xB0, data1: 0, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track!, 0, &chMsg)
        if status != noErr {
            print("creating bank select event \(status)")
        }
        
        // bank select lsb
        chMsg = MIDIChannelMessage(status: 0xB0, data1: 32, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track!, 0, &chMsg)
        if status != noErr {
            print("creating bank select event \(status)")
        }
        
        // program change. first data byte is the patch, the second data byte is unused for program change messages.
        let instNumber = UserDefaults.standard.integer(forKey: .cfgInstrumentPatch)
        chMsg = MIDIChannelMessage(status: 0xC0, data1: UInt8(instNumber), data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track!, 0, &chMsg)
        if status != noErr {
            print("creating program change event \(status)")
        }
        
        // now make some notes and put them on the track
        // 60: C4 -> C0 = 0 ~
        var durationInt = UserDefaults.standard.integer(forKey: .cfgDurationOfNoteSound)
        if durationInt <= 0 {
            durationInt = 8
        }
        let duration: Float32 = Float32(durationInt)
        
        for coord in coords {
            var msg = MIDINoteMessage(channel: 0,
                                      note: UInt8(coord.musicNote.semitone + 12),
                                      velocity: 96,
                                       releaseVelocity: 96,
                                       duration: duration )
            guard let beat16 = coord.gridX else { return nil }
            status = MusicTrackNewMIDINoteEvent(track!, headSilence + beat16 / 4, &msg)
            if status != noErr {
                print("error: creating new midi note event \(status)")
            }
        }
        
        CAShow(UnsafeMutablePointer<MusicSequence>(musicSequence!))
        
        return musicSequence!
        
    }
}
