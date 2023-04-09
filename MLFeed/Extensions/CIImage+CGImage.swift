import CoreImage
import UIKit

extension CIImage {
    
    func cgImage() -> CGImage? {
        let context = CIContext(options: nil)
        return context.createCGImage(self,
                                     from: extent)
    }
}
