import CoreImage
import UIKit

extension CIImage {
    
    func uiImage(with context: CIContext) -> UIImage? {
        guard let cgImage = context.createCGImage(self,
                                                  from: self.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage,
                       scale: UIScreen.main.scale,
                       orientation: .up)
    }
}
