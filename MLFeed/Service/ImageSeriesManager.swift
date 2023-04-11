import CoreImage
import UIKit

struct ImageSeries {
    let originalImage: UIImage
    let backgroundImage: UIImage
    let silhouetteImage: UIImage
}

class ImageSeriesManager {
 
    init() throws {

        mlEngine = try MLEngine()
    }
    
    // MARK: Private
    private let imageProcessor = ImageProcessor()
    private var mlEngine: MLEngine!
}

// MARK: - Public
extension ImageSeriesManager {
    
    func series(from images: [UIImage]) async -> [ImageSeries] {
        
        await withUnsafeContinuation { continuantion in
            
            var seriesImages: [ImageSeries] = []
            for sourceImage in images {
                
                do {
                    let images = try series(from: sourceImage)
                    let series = ImageSeries(originalImage: sourceImage,
                                             backgroundImage: images[1],
                                             silhouetteImage: images[0])
                    seriesImages.append(series)
                } catch {
                    print("Error \(error.localizedDescription)")
                }
            }
            
            continuantion.resume(with: .success(seriesImages))
        }
    }
}

// MARK: - Processing
private extension ImageSeriesManager {
    
    func series(from image: UIImage) throws -> [UIImage] {
     
        let resizedCVPixelBuffer = try imageProcessor.size(image: image,
                                                           toFit: Constants.imageSize)
        
        let maskCVPixelBuffer = try mlEngine.process(image: resizedCVPixelBuffer)
        let slices = try imageProcessor.slices(from: resizedCVPixelBuffer,
                                               with: maskCVPixelBuffer)
        
        let scaledUpBackground = try imageProcessor.sizeUp(image: slices[0],
                                                           toFit: image.size)
        let scaledUpForeground = try imageProcessor.sizeUp(image: slices[1],
                                                           toFit: image.size)
        
        return [scaledUpBackground,
                scaledUpForeground]
    }
}

// MARK: - Constants
private extension ImageSeriesManager {
    
    enum Constants {
        static let imageSize = CGSize(width: 1024, height: 1024)
    }
}
