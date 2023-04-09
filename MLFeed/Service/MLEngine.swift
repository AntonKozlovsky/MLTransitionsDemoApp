import CoreML

class MLEngine {
    
    init?() throws {
        coreML = try segmentation_8bit()
    }
    
    // MARK: Private
    private var coreML: segmentation_8bit
}

extension MLEngine {
    
    func process(image: CVPixelBuffer) throws -> CVPixelBuffer {
        try coreML.prediction(img: image).var_2274
    }
}
