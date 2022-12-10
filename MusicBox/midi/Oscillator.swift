//
//  Oscillator.swift
//  MusicBox
//
//  Created by yoonbumtae on 2022/12/10.
//

import Foundation
import AudioKit
import SoundpipeAudioKit

// class GlobalOsc {
//     static let shared = GlobalOsc()
//     let conductor = DynamicOscillatorConductor()
// }

struct DynamicOscillatorData {
    var isPlaying: Bool = false
    var frequency: AUValue = 440
    var amplitude: AUValue = 5
    var rampDuration: AUValue = 1
}

class DynamicOscillatorConductor: ObservableObject {
    
    let engine = AudioEngine()
    var data = DynamicOscillatorData()
    var osc = DynamicOscillator()
    var mixer = Mixer()
    
    func noteOn(note: MIDINoteNumber) {
        data.isPlaying = true
        data.frequency = note.midiNoteToFrequency()
    }
    
    func noteOff(note: MIDINoteNumber) {
        data.isPlaying = false
    }
    
    init() {
        mixer.addInput(osc)
        engine.output = mixer
    }
    
    func start() {
        // osc.amplitude = 1
        mixer.volume = 0.3
        osc.setWaveform(Table(.sine))
        do {
            try engine.start()
        } catch {
            print(error)
        }
    }
    
    func stop() {
        data.isPlaying = false
        osc.stop()
        engine.stop()
    }
    
    func makeSound(note: MIDINoteNumber, duration: Float = 0.5) {
        noteOn(frequency: note.midiNoteToFrequency())
        Timer.scheduledTimer(withTimeInterval: TimeInterval(duration), repeats: false) { timer in
            self.noteOff()
        }
    }
    
    func noteOn(frequency: Float) {
        data.isPlaying = true
        osc.start()
        data.frequency = frequency
        osc.$frequency.ramp(to: data.frequency, duration: 0)
        osc.$amplitude.ramp(to: 0.5, duration: 0.1)
    }
    
    func noteOff() {
        data.isPlaying = false
        data.frequency = 0.0
        osc.$amplitude.ramp(to: 0, duration: 0.5)
    }
}
