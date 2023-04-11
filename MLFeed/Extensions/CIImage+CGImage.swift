import CoreImage
import UIKit

extension CIImage {
    
    func cgImage(with context: CIContext) -> CGImage? {
        context.createCGImage(self, from: extent)
    }
}
