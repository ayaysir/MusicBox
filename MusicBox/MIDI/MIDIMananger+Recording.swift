//
//  MIDIMananger+Recording.swift
//  MusicBox
//
//  Created by 윤범태 on 2/20/25.
//

import AVFoundation

extension MIDIManager {
  func exportToWAV(outputURL: URL) async -> Bool {
    /*
     var engine = AVAudioEngine()
     var sampler = AVAudioUnitSampler()
     var sequencer: AVAudioSequencer!
     */
    
    engine.attach(sampler)
    engine.connect(sampler, to: engine.mainMixerNode, format: nil)
    
    guard let soundbankURL, let data = musicSequenceToData(sequence: musicSequence) else {
      return false
    }
    
    do {
      try sampler.loadInstrument(at: soundbankURL)
      sequencer = .init(audioEngine: engine)
      try sequencer.load(from: data, options: .smf_ChannelsToTracks)
    } catch {
      print(#function, "Sequencer init error:", error)
    }
    
    guard let sequencer else {
      return false
    }
    
   // do {
   //   let audioSession = AVAudioSession.sharedInstance()
   //   try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
   //   try audioSession.setActive(true)
   // } catch {
   //   print(#function, "AudioSession error:", error)
   // }
    
    do {
      engine.prepare()
      // try engine.start()
      let format = engine.outputNode.outputFormat(forBus: 0)
      let audioFile = try AVAudioFile(forWriting: outputURL, settings: format.settings)
      
      let bufferSize: AVAudioFrameCount = 4096
      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize)!
      
      // try sequencer.start()/\
      sequencer.currentPositionInBeats = 0
      
      while sequencer.currentPositionInBeats < sequencer.tracks.reduce(0, { max($0, $1.lengthInBeats) }) {
        try engine.renderOffline(bufferSize, to: buffer)
        try audioFile.write(from: buffer)
      }
      
      // sequencer.stop()
      engine.stop()
      
      return true
    } catch {
      print(#function, "convert error:", error)
    }
    
    return false
  }
}
