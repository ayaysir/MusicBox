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
        
        let bpm: Int = PaperInfoBridge.shared.currentBPM ?? 100
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
        let instNumber = 11
        chMsg = MIDIChannelMessage(status: 0xC0, data1: UInt8(instNumber), data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track!, 0, &chMsg)
        if status != noErr {
            print("creating program change event \(status)")
        }
        
        // now make some notes and put them on the track
        // 60: C4 -> C0 = 0 ~
        let duration: Float32 = 8
        
        for coord in coords {
            var msg = MIDINoteMessage(channel: 0,
                                      note: UInt8(coord.musicNote.semitone + 12),
                                      velocity: 96,
                                       releaseVelocity: 0,
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

// ======================================================================= //

extension MIDIManager {
    func createMusicSequence() -> MusicSequence {
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
        if MusicTrackNewExtendedTempoEvent(tempoTrack!, 0.0, 128.0) != noErr {
            print("could not set tempo")
        }
        if MusicTrackNewExtendedTempoEvent(tempoTrack!, 4.0, 256.0) != noErr {
            print("could not set tempo")
        }
        
        
        // add a track
        var track: MusicTrack?
        status = MusicSequenceNewTrack(musicSequence!, &track)
        if status != noErr {
            print("error creating track \(status)")
        }
        
        // bank select msb
        var chanmess = MIDIChannelMessage(status: 0xB0, data1: 0, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track!, 0, &chanmess)
        if status != noErr {
            print("creating bank select event \(status)")
        }
        
        // bank select lsb
        chanmess = MIDIChannelMessage(status: 0xB0, data1: 32, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track!, 0, &chanmess)
        if status != noErr {
            print("creating bank select event \(status)")
        }
        
        // program change. first data byte is the patch, the second data byte is unused for program change messages.
        chanmess = MIDIChannelMessage(status: 0xC0, data1: 0, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track!, 0, &chanmess)
        if status != noErr {
            print("creating program change event \(status)")
        }
        
        // now make some notes and put them on the track
        var beat: MusicTimeStamp = 0.0
        for i: UInt8 in 60...72 {
            var mess = MIDINoteMessage(channel: 0,
                                       note: i,
                                       velocity: 64,
                                       releaseVelocity: 0,
                                       duration: 1.0 )
            status = MusicTrackNewMIDINoteEvent(track!, beat, &mess)
            if status != noErr {
                print("creating new midi note event \(status)")
            }
            beat += 1
        }
        
        CAShow(UnsafeMutablePointer<MusicSequence>(musicSequence!))
        
        return musicSequence!
    }
    
    func createMusicSequence_바둑이() -> MusicSequence {
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
        if MusicTrackNewExtendedTempoEvent(tempoTrack!, 0.0, 100.0) != noErr {
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
        chMsg = MIDIChannelMessage(status: 0xC0, data1: 11, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track!, 0, &chMsg)
        if status != noErr {
            print("creating program change event \(status)")
        }
        
        // now make some notes and put them on the track
        // 60: C
        var beat: MusicTimeStamp = 0.0
        
        struct Event {
            var note: UInt8
            var velocity: UInt8 = 64
            var duration: Float32
            var beat: MusicTimeStamp
        }
        
        let scoreBaduk = [
            Event(note: 60, duration: 0.5, beat: 0.5),
            Event(note: 64, duration: 0.5, beat: 0.5),
            Event(note: 64, duration: 0.5, beat: 0.5),
            Event(note: 64, duration: 0.5, beat: 0.5),
            Event(note: 64, duration: 1, beat: 1),
            Event(note: 64, duration: 1, beat: 1),
            
            Event(note: 62, duration: 0.5, beat: 0.5),
            Event(note: 65, duration: 0.5, beat: 0.5),
            Event(note: 65, duration: 0.5, beat: 0.5),
            Event(note: 65, duration: 0.5, beat: 0.5),
            Event(note: 65, duration: 1, beat: 1),
            Event(note: 65, duration: 1, beat: 1),
            
            Event(note: 64, duration: 0.5, beat: 0.5),
            Event(note: 67, duration: 0.5, beat: 0.5),
            Event(note: 67, duration: 1, beat: 1),
            Event(note: 67, duration: 1, beat: 1),
            Event(note: 64, duration: 1, beat: 1),
            
            Event(note: 62, duration: 0.5, beat: 0.5),
            Event(note: 65, duration: 0.5, beat: 0.5),
            Event(note: 64, duration: 0.5, beat: 0.5),
            Event(note: 62, duration: 0.5, beat: 0.5),
            Event(note: 60, duration: 1.5, beat: 2),
            
            Event(note: 72, duration: 1, beat: 1),
            Event(note: 72, duration: 1, beat: 1),
            Event(note: 67, duration: 1, beat: 1),
            Event(note: 67, duration: 1, beat: 1),
            
            Event(note: 69, duration: 0.5, beat: 0.5),
            Event(note: 72, duration: 0.5, beat: 0.5),
            Event(note: 71, duration: 0.5, beat: 0.5),
            Event(note: 69, duration: 0.5, beat: 0.5),
            Event(note: 67, duration: 1.5, beat: 2),
            
            Event(note: 72, duration: 1, beat: 1),
            Event(note: 72, duration: 1, beat: 1),
            Event(note: 67, duration: 1, beat: 1),
            Event(note: 67, duration: 1, beat: 1),
            
            Event(note: 69, duration: 0.5, beat: 0.5),
            Event(note: 72, duration: 0.5, beat: 0.5),
            Event(note: 71, duration: 0.5, beat: 0.5),
            Event(note: 69, duration: 0.5, beat: 0.5),
            Event(note: 67, duration: 0.5, beat: 0.5),
            Event(note: 65, duration: 0.5, beat: 0.5),
            Event(note: 64, duration: 0.5, beat: 0.5),
            Event(note: 62, duration: 0.5, beat: 0.5),
            
            Event(note: 60, duration: 0.5, beat: 0.5),
            Event(note: 64, duration: 0.5, beat: 0.5),
            Event(note: 64, duration: 0.5, beat: 0.5),
            Event(note: 64, duration: 0.5, beat: 0.5),
            Event(note: 64, duration: 1, beat: 1),
            Event(note: 64, duration: 1, beat: 1),
            
            Event(note: 62, duration: 0.5, beat: 0.5),
            Event(note: 65, duration: 0.5, beat: 0.5),
            Event(note: 65, duration: 0.5, beat: 0.5),
            Event(note: 65, duration: 0.5, beat: 0.5),
            Event(note: 65, duration: 1, beat: 1),
            Event(note: 65, duration: 1, beat: 1),
            
            Event(note: 64, duration: 0.5, beat: 0.5),
            Event(note: 67, duration: 0.5, beat: 0.5),
            Event(note: 67, duration: 1, beat: 1),
            Event(note: 67, duration: 1, beat: 1),
            Event(note: 64, duration: 1, beat: 1),
            
            Event(note: 62, duration: 0.5, beat: 0.5),
            Event(note: 65, duration: 0.5, beat: 0.5),
            Event(note: 64, duration: 0.5, beat: 0.5),
            Event(note: 62, duration: 0.5, beat: 0.5),
            Event(note: 60, duration: 1.5, beat: 2),
            
        ]
        
        let scoreBadukHarmony = [
            Event(note: 60, duration: 4, beat: 4),
            Event(note: 55, duration: 4, beat: 4),
            Event(note: 60, duration: 4, beat: 4),
            Event(note: 55, duration: 2, beat: 2),
            Event(note: 48, duration: 1.5, beat: 2),
            
            Event(note: 60, duration: 4, beat: 4),
            Event(note: 53, duration: 1, beat: 1),
            Event(note: 54, duration: 1, beat: 1),
            Event(note: 55, duration: 2, beat: 2),
            
            Event(note: 60, duration: 4, beat: 4),
            Event(note: 53, duration: 1, beat: 1),
            Event(note: 54, duration: 1, beat: 1),
            Event(note: 55, duration: 1, beat: 1),
            Event(note: 43, duration: 1, beat: 1),
            
            Event(note: 48, duration: 4, beat: 4),
            Event(note: 55, duration: 4, beat: 4),
            Event(note: 60, duration: 4, beat: 4),
            Event(note: 55, duration: 2, beat: 2),
            Event(note: 48, duration: 1.5, beat: 2),
        ]
        
        for voice in [scoreBaduk, scoreBadukHarmony] {
            beat = 0
            for event in voice {
                var msg = MIDINoteMessage(channel: 0,
                                          note: event.note,
                                          velocity: event.velocity,
                                           releaseVelocity: 0,
                                           duration: event.duration )
                status = MusicTrackNewMIDINoteEvent(track!, beat, &msg)
                if status != noErr {
                    print("creating new midi note event \(status)")
                }
                beat += event.beat
            }
        }
        
        
        CAShow(UnsafeMutablePointer<MusicSequence>(musicSequence!))
        
        return musicSequence!
        
    }
}
