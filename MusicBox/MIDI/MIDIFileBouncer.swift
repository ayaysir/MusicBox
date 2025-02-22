//
//  MIDIFileBouncer.swift
//  MusicBox
//
//  Created by 윤범태 on 2/21/25.
//

import AVFoundation

protocol MIDIFileBouncerDelegate: AnyObject {
  func bounceProgress(progress: Double, currentTime: TimeInterval)
  func bounceError(error: MIDIBounceError)
  func bounceCompleted()
}

struct MIDIBounceError: Error {
  enum ErrorKind {
    case initializationFailure
    case invalidSequenceLength
    case avAudioFileCreationFailure
    case conversionFailure
    case engineStartFailure
    case sequencerStartFailure
    case ioError
  }

  let kind: ErrorKind
  let localizedMessage: String
  let innerError: Error?

  init(kind: ErrorKind, message: String, innerError: Error? = nil) {
    self.kind = kind

    let localizedMessage = NSLocalizedString(message, comment: "Make sure all error messages are fully localized")
    self.localizedMessage = localizedMessage

    self.innerError = innerError
  }
}

class MIDIFileBouncer {
  private var engine: AVAudioEngine!
  private var sampler: AVAudioUnitMIDISynth!
  private var sequencer: AVAudioSequencer!
  
  private var cancelProcessing = false
  
  var midiData: Data?
  var soundfontURL: URL?
  var outputFileURL: URL?
  
  var isCancelled: Bool {
    cancelProcessing
  }
  
  var rate: Float {
    get {
      return sequencer.rate
    } set {
      sequencer.rate = newValue
    }
  }
  
  weak var delegate: MIDIFileBouncerDelegate?
  
  deinit {
    engine.disconnectNodeInput(sampler, bus: 0)
    engine.detach(sampler)
    sequencer = nil
    sampler = nil
    engine = nil
  }

  init(midiFileData: Data, soundfontURL: URL) throws {
    self.engine = AVAudioEngine()
    self.sampler = try AVAudioUnitMIDISynth(soundBankURL: soundfontURL)

    self.engine.attach(self.sampler)
    
    let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
    let mixer = self.engine.mainMixerNode
    mixer.outputVolume = 10.0
    self.engine.connect(self.sampler, to: mixer, format: audioFormat)

    self.sequencer = AVAudioSequencer(audioEngine: self.engine)
    try self.sequencer.load(from: midiFileData, options: [])
    self.sequencer.prepareToPlay()
    
    self.midiData = midiFileData
    self.soundfontURL = soundfontURL
  }
  
  func cancel() {
    self.cancelProcessing = true
  }
  
  // MARK: - Delegate methods

  private func delegateProgress(progress: Double, currentTime: TimeInterval) {
    DispatchQueue.main.async {
      self.delegate?.bounceProgress(progress: progress, currentTime: currentTime)
    }
  }

  private func delegateError(error: MIDIBounceError) {
    DispatchQueue.main.async {
      self.delegate?.bounceError(error: error)
    }
  }

  private func delegateCompleted() {
    DispatchQueue.main.async {
      self.delegate?.bounceCompleted()
    }
  }
  
  func getAudioSession() -> AVAudioSession? {
    let audioSession = AVAudioSession.sharedInstance()
      do {
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
        
        try audioSession.setActive(true)
        
        return audioSession
      } catch {
        print("오디오 세션 설정 실패: \(error)")
        return nil
      }
  }
}

extension MIDIFileBouncer {
  func bounce(to fileURL: URL) throws {
    var writeError: NSError?
    
    self.outputFileURL = fileURL
    
    let outputNode = self.sampler!
    let outputFormat = outputNode.outputFormat(forBus: 0)
    
    guard let sequenceLength = sequencer.tracks.map({ $0.lengthInSeconds + self.sequencer.seconds(forBeats: $0.offsetTime) }).max() else {
      throw MIDIBounceError(
        kind: .invalidSequenceLength,
        message: "Can't determine sequence length."
      )
    }
    
    let converter = getConverter(from: outputFormat)
    
    let outputFile: AVAudioFile
    do {
      outputFile = try AVAudioFile(
        forWriting: fileURL,
        settings: converter.outputFormat.settings,
        commonFormat: converter.outputFormat.commonFormat,
        interleaved: true
      )
    } catch {
      throw MIDIBounceError(kind: .avAudioFileCreationFailure, message: "AVAudioFile creation failed.", innerError: error)
    }
    
    // Install tap
    outputNode.installTap(onBus: 0, bufferSize: 1024 * 4, format: nil) { buffer, _ in
      do {
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
          outStatus.pointee = AVAudioConverterInputStatus.haveData
          return buffer
        }
        
        // necessary because otherwise the converter will stretch/squeeze samples to fit the buffer, resulting in corruption
        let sampleRateRatio = outputFormat.sampleRate / converter.outputFormat.sampleRate
        let capacity = UInt32(Double(buffer.frameCapacity) / sampleRateRatio)
        
        let convertedBuffer = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: capacity)!
        convertedBuffer.frameLength = convertedBuffer.frameCapacity
        
        let status = converter.convert(
          to: convertedBuffer,
          error: &writeError,
          withInputFrom: inputBlock
        )
        
        if status == .error {
          throw MIDIBounceError(kind: .conversionFailure, message: "Error occurred while converting file.")
        }
        
        try outputFile.write(from: convertedBuffer)
      } catch {
        writeError = error as NSError
      }
    }
    
    // guard let audioSession = getAudioSession() else {
    //   return
    // }
    
    // try audioSession.setActive(true)
    engine.prepare()
    
    do {
      try engine.start()
    } catch {
      throw MIDIBounceError(
        kind: .sequencerStartFailure,
        message: "Can't start sequencer.",
        innerError: error
      )
    }
    
    // get sequncer ready
    // sequencer.rate = 100.0
    sequencer.currentPositionInSeconds = 0
    sequencer.prepareToPlay()
    // try sampler.setPreload(enabled: true)
    
    // Add silence to beginning
    usleep(useconds_t(0.2 * 1000 * 1000))
    
    // Start playback.
    do {
      try sequencer.start()
    } catch {
      throw MIDIBounceError(
        kind: .sequencerStartFailure,
        message: "Can't start sequencer.",
        innerError: error
      )
    }
    
    // Continuously check whether the track's finished or if an error occurred while looping
    while self.sequencer.isPlaying
            && !self.cancelProcessing
            && writeError == nil
            && self.sequencer.currentPositionInSeconds < sequenceLength {
      let progress = self.sequencer.currentPositionInSeconds / sequenceLength
      self.delegateProgress(progress: progress * 100, currentTime: self.sequencer.currentPositionInSeconds)

      usleep(10000)
    }
    
    // Ensure playback is stopped
    self.sequencer.stop()
    // try self.sampler.setPreload(enabled: false)
    self.sequencer.rate = 1.0
    
    if writeError == nil {
      // Add x seconds of silence to end to ensure all notes have fully stopped playing
      usleep(useconds_t(1.5 * 1000 * 1000))
      self.delegateProgress(progress: 100, currentTime: self.sequencer.currentPositionInSeconds)
    }
    
    // Stop recording
    outputNode.removeTap(onBus: 0)
    self.engine.stop()
    
    // try audioSession.setActive(false)
    
    // Return error if there was any issue during recording.
    if let writeError {
      throw MIDIBounceError(kind: .ioError, message: "Can't write to file.", innerError: writeError)
    } else {
      self.delegateCompleted()
    }
    
    print(#function, "convert success!")
  }
  
  func getConverter(from format: AVAudioFormat) -> AVAudioConverter {
    let SAMPLE_RATE: Double = 44100
    let CHANNELS: AVAudioChannelCount = 2
    
    guard let destFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: SAMPLE_RATE, channels: CHANNELS, interleaved: true) else {
      fatalError("AVAudioFormat initialization error")
    }

    guard let conv = AVAudioConverter(from: format, to: destFormat) else {
      fatalError("Converter initialization failed")
    }

    conv.downmix = true

    conv.sampleRateConverterAlgorithm = AVSampleRateConverterAlgorithm_MinimumPhase
    conv.sampleRateConverterQuality = AVAudioQuality.max.rawValue

    return conv
  }
}
