import AudioToolbox
import AVFoundation
import Accelerate
import Combine

class AACPlayer {
 
    // MARK: Private
    private let audioEngine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
}

// MARK: - Public interface
extension AACPlayer {
    
    func play(itemAt url: URL) throws {
        
            let audioFile = try AVAudioFile(forReading: url)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                                frameCapacity: .init(audioFile.length)) else { return }
            try audioFile.read(into: buffer)
            audioEngine.attach(player)
            audioEngine.connect(player,
                                to: audioEngine.mainMixerNode,
                                format: buffer.format)
            try audioEngine.start()
            player.play()
            player.scheduleBuffer(buffer,
                                  at: nil,
                                  options: .loops)
    }

}
