//
//  AVAudioUnitMIDISynth.swift
//  MusicBox
//
//  Created by 윤범태 on 2/21/25.
//

import AVFoundation

class AVAudioUnitMIDISynth: AVAudioUnitMIDIInstrument {
  init(soundBankURL: URL) throws {
    let description = AudioComponentDescription(
      componentType: kAudioUnitType_MusicDevice,
      componentSubType: kAudioUnitSubType_MIDISynth,
      componentManufacturer: kAudioUnitManufacturer_Apple,
      componentFlags: 0,
      componentFlagsMask: 0
    )
    super.init(audioComponentDescription: description)

    var bankURL = soundBankURL
    let status = AudioUnitSetProperty(
      self.audioUnit,
      AudioUnitPropertyID(kMusicDeviceProperty_SoundBankURL),
      AudioUnitScope(kAudioUnitScope_Global),
      0,
      &bankURL,
      UInt32(MemoryLayout<URL>.size)
    )
    if status != OSStatus(noErr) {
      throw NSError.app("\(status)")
    }
  }

  func setPreload(enabled: Bool) throws {
    guard let engine = self.engine, engine.isRunning else {
      throw NSError.app("엔진이 실행 중이어야 합니다.")
    }
    
    var enabledBit = enabled ? UInt32(1) : UInt32(0)
    let status = AudioUnitSetProperty(
      self.audioUnit,
      AudioUnitPropertyID(kAUMIDISynthProperty_EnablePreload),
      AudioUnitScope(kAudioUnitScope_Global),
      0,
      &enabledBit,
      UInt32(MemoryLayout<UInt32>.size)
    )
    if status != noErr {
      throw NSError.app("\(status)")
    }
  }
}
