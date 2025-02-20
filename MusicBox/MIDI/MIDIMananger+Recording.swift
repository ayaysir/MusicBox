//
//  MIDIMananger+Recording.swift
//  MusicBox
//
//  Created by 윤범태 on 2/20/25.
//

import AVFoundation

extension MIDIManager {
  func startRecording(outputURL: URL, completion: @escaping (Bool) -> Void) {
    do {
      let format = engine.mainMixerNode.outputFormat(forBus: 0)
      let file = try AVAudioFile(forWriting: outputURL, settings: format.settings)

      engine.mainMixerNode.installTap(onBus: 0, bufferSize: 4096, format: format) { (buffer, _) in
        do {
          try file.write(from: buffer)
        } catch {
          print("Error writing audio buffer: \(error)")
        }
      }

      try engine.start()
      midiPlayer?.play {
        self.engine.mainMixerNode.removeTap(onBus: 0)
        self.engine.stop()
        completion(true)
      }
    } catch {
      print("Error starting recording: \(error)")
      completion(false)
    }
  }
}
