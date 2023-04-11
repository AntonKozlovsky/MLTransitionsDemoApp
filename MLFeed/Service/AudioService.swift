import Foundation
import AVFoundation

class AudioService {
    
    // MARK: Private
    private var player = AACPlayer()
}

// MARK: - Public interface
extension AudioService {
    
    func play(at url: URL) async throws {

        let asset = AVURLAsset(url: url)
        guard try await asset.load(.isPlayable) else {
            throw Error.unsupportedFormat
        }
        
        do {
            try player.play(itemAt: url)
        } catch {
            throw Error.playError(error)
        }
    }
}

// MARK: - Error
extension AudioService {
    
    enum Error: Swift.Error {
        case unsupportedFormat
        case playError(Swift.Error?)
    }
}
