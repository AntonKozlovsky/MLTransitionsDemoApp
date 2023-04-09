import UIKit
import CoreImage
import CoreImage.CIFilter
import Accelerate
import CoreGraphics

class ImageProcessor {}

extension ImageProcessor {
    
    enum Error: Swift.Error {
        case filterError
        case resizeImageError(String?)
        case commonError
    }
}

// MARK: - Resize routine
extension ImageProcessor {
    
    func size(image: UIImage,
              toFit size: CGSize) throws -> CVPixelBuffer {
        
        guard let cgSourceImage = image.cgImage else {
            throw Error.commonError
        }
        
        guard let sourceImageformat = vImage_CGImageFormat(cgImage: cgSourceImage) else {
            throw Error.commonError
        }
        
        let sourceImageBuffer = try vImage_Buffer(cgImage: cgSourceImage,
                                                  format: sourceImageformat)
        
        let resizedImageBuffer = try resize(image: sourceImageBuffer,
                                            format: sourceImageformat,
                                            to: size)
        
        defer {
            sourceImageBuffer.free()
            resizedImageBuffer.free()
        }
        
        let cvBuffer = try cvPixelBuffer(from: resizedImageBuffer,
                                         withSize: size)
        
        return cvBuffer
    }
    
    func sizeUp(image cgSourceImage: CGImage,
                toFit size: CGSize) throws -> UIImage {
        
        guard let sourceImageformat = vImage_CGImageFormat(cgImage: cgSourceImage) else {
            throw Error.commonError
        }
        
        let sourceImageBuffer = try vImage_Buffer(cgImage: cgSourceImage,
                                                  format: sourceImageformat)
            
        
        var destinationBuffer = try vImage_Buffer(width: Int(size.width),
                                                  height: Int(size.height),
                                                  bitsPerPixel: sourceImageformat.bitsPerPixel)
        
        defer {
            sourceImageBuffer.free()
            destinationBuffer.free()
        }
        
        try scaleUp(sourceImageBuffer: sourceImageBuffer, to: &destinationBuffer)
        
        let cvBuffer = try cvPixelBuffer(from: destinationBuffer,
                                         withSize: size)
        
        let ciImage = CIImage(cvImageBuffer: cvBuffer)
        guard let resultImage = ciImage.uiImage() else {
            throw Error.commonError
        }
        return resultImage
    }
    
    func slices(from image: CVPixelBuffer,
                with mask: CVPixelBuffer) throws -> [CGImage] {
        
        let ciImage = CIImage(cvPixelBuffer: image)
        let ciMaskImage = CIImage(cvPixelBuffer: mask)
        
        guard let sharpFilter = CIFilter(name: "CIColorMonochrome") else {
            throw Error.filterError
        }
        sharpFilter.setValue(CIColor(color: .white),
                             forKey: kCIInputColorKey)
        sharpFilter.setValue(1.0,
                             forKey: kCIInputIntensityKey)
        sharpFilter.setValue(ciMaskImage,
                             forKey: kCIInputImageKey)
        let sharpMask = sharpFilter.outputImage!
        
        guard let invertFilter = CIFilter(name: "CIColorInvert") else {
            throw Error.filterError
        }
        
        invertFilter.setValue(sharpMask, forKey: kCIInputImageKey)
        guard let invertedMask = invertFilter.outputImage else {
            throw Error.filterError
        }
        
        let foreground = try slice(image: ciImage, with: invertedMask)
        let background = try slice(image: ciImage, with: sharpMask)
        
        guard let foregroundCGImage = foreground.cgImage(),
              let backgroundCGImage = background.cgImage() else {
            
            throw Error.filterError
        }
        
        return [foregroundCGImage,
                backgroundCGImage]
    }
}

// MARK: - CIFilter routine
private extension ImageProcessor {
    
    func slice(image: CIImage,
               with mask: CIImage) throws -> CIImage {
        
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else {
            throw Error.filterError
        }
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(mask, forKey: kCIInputMaskImageKey)
        
        guard let outputImage = blendFilter.outputImage else {
            throw Error.commonError
        }
        
        return outputImage
    }
}

// MARK: - Image modification
private extension ImageProcessor {
    
    func resize(image: vImage_Buffer,
                format: vImage_CGImageFormat,
                to size: CGSize) throws -> vImage_Buffer {
        
        
        var destinationBuffer = try vImage_Buffer(width: Int(size.width),
                                                  height: Int(size.height),
                                                  bitsPerPixel: format.bitsPerPixel)
        try center(sourceImageBuffer: image,
                   in: &destinationBuffer)
        
        return destinationBuffer
    }
    
    private func center(sourceImageBuffer: vImage_Buffer,
                        in destination: inout vImage_Buffer) throws {
        
        let sourceSize = withUnsafePointer(to: sourceImageBuffer) { sourcePointer in
            vImageBuffer_GetSize(sourcePointer)
        }
        
        let destinationSize = withUnsafePointer(to: destination) { destinationPointer in
            vImageBuffer_GetSize(destinationPointer)
        }
        
        let scale = maxScale(from: sourceSize,
                             to: destinationSize)
        
        let cgTransform: CGAffineTransform =
            .identity
            .translatedBy(x: (destinationSize.width - sourceSize.width * scale) / 2,
                          y: 0)
            .scaledBy(x: scale,
                      y: scale)

        var vImageTransform = vImage_CGAffineTransform(affineTransform: cgTransform)
        
        let error = withUnsafePointer(to: sourceImageBuffer) { srcPointer in
            vImageAffineWarpCG_ARGB8888(srcPointer,
                                        &destination,
                                        nil,
                                        &vImageTransform,
                                        Constants.blackColor8888,
                                        vImage_Flags(kvImageBackgroundColorFill))
        }
        
        if error != kvImageNoError {
            throw Error.resizeImageError("Error code \(error)")
        }
    }
    
    private func removeAlpha(from sourceBuffer: vImage_Buffer,
                             destination: inout vImage_Buffer) throws {
        
        let error = withUnsafePointer(to: sourceBuffer) { srcPointer in
            
            var backgroundColor = Constants.blackColor888
            return vImageFlatten_RGBA8888ToRGB888(srcPointer,
                                                  &destination,
                                                  &backgroundColor,
                                                  false,
                                                  vImage_Flags(kvImageNoFlags))
        }
        
        if error != kvImageNoError {
            throw Error.resizeImageError("Error code \(error)")
        }
    }
    
    private func scaleUp(sourceImageBuffer: vImage_Buffer,
                         to destination: inout vImage_Buffer) throws {
        
        let sourceSize = withUnsafePointer(to: sourceImageBuffer) { sourcePointer in
            vImageBuffer_GetSize(sourcePointer)
        }
        
        let destinationSize = withUnsafePointer(to: destination) { destinationPointer in
            vImageBuffer_GetSize(destinationPointer)
        }
        
        let scale = minScale(from: sourceSize,
                             to: destinationSize)
        
        let cgTransform: CGAffineTransform =
            .identity
            .translatedBy(x: (destinationSize.width - sourceSize.width * scale) / 2,
                          y: 0)
            .scaledBy(x: scale,
                      y: scale)

        var vImageTransform = vImage_CGAffineTransform(affineTransform: cgTransform)
        
        let error = withUnsafePointer(to: sourceImageBuffer) { srcPointer in
            vImageAffineWarpCG_ARGB8888(srcPointer,
                                        &destination,
                                        nil,
                                        &vImageTransform,
                                        Constants.blackColor8888,
                                        vImage_Flags(kvImageBackgroundColorFill))
        }
        
        if error != kvImageNoError {
            throw Error.resizeImageError("Error code \(error)")
        }
    }
}

// MARK: - Image converting
private extension ImageProcessor {
    
    func cvPixelBuffer(from buffer: vImage_Buffer, withSize size: CGSize) throws -> CVPixelBuffer {
        
        var destinationBuffer: CVPixelBuffer?
        
        let cvPixelBufferCreationInfo = [kCVPixelBufferCGImageCompatibilityKey : kCFBooleanTrue,
                                 kCVPixelBufferCGBitmapContextCompatibilityKey : kCFBooleanTrue] as CFDictionary
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(size.width),
                                         Int(size.height),
                                         kCVPixelFormatType_32ARGB,
                                         cvPixelBufferCreationInfo,
                                         &destinationBuffer)
        
        guard status == kCVReturnSuccess,
              let destinationBuffer else {
            
            throw Error.commonError
        }
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard var rgbaCGImageFormat = vImage_CGImageFormat(bitsPerComponent: 8,
                                                           bitsPerPixel: 32,
                                                           colorSpace: rgbColorSpace,
                                                           bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                                                           renderingIntent: .defaultIntent) else {
            throw Error.commonError
        }
        
        let cvImageFormat = vImageCVImageFormat_CreateWithCVPixelBuffer(destinationBuffer).takeRetainedValue()
        vImageCVImageFormat_SetColorSpace(cvImageFormat,
                                          rgbColorSpace)
        
        let error = withUnsafePointer(to: buffer) { srcPointer in
            
            vImageBuffer_CopyToCVPixelBuffer(srcPointer,
                                             &rgbaCGImageFormat,
                                             destinationBuffer,
                                             cvImageFormat,
                                             nil,
                                             vImage_Flags(kvImageNoFlags))
        }
        
        guard error == kvImageNoError else {
            throw Error.commonError
        }
        
        return destinationBuffer
    }
}

// MARK: - Utils
private extension ImageProcessor {
    
    func maxScale(from sourceSize: CGSize,
                  to destinationSize: CGSize) -> CGFloat {
        
        let scaleWidth = destinationSize.width / sourceSize.width
        let scaleHeight = destinationSize.height / sourceSize.height
        
        return min(scaleWidth, scaleHeight)
    }
    
    func minScale(from sourceSize: CGSize,
                  to destinationSize: CGSize) -> CGFloat {
        
        let scaleWidth = destinationSize.width / sourceSize.width
        let scaleHeight = destinationSize.height / sourceSize.height
        
        return max(scaleWidth, scaleHeight)
    }
}

private extension ImageProcessor {
    
    enum Constants {
        
        static let blackColor888: [Pixel_8] = [0, 0, 0]
        static let blackColor8888: [Pixel_8] = [0, 0, 0, 0]//100]
    }
}




public extension CGBitmapInfo {

    enum ComponentLayout {

        case bgra
        case abgr
        case argb
        case rgba
        case bgr
        case rgb

        var count: Int {
            switch self {
            case .bgr, .rgb: return 3
            default: return 4
            }
        }

    }

    var componentLayout: ComponentLayout? {
        guard let alphaInfo = CGImageAlphaInfo(rawValue: rawValue & Self.alphaInfoMask.rawValue) else { return nil }
        let isLittleEndian = contains(.byteOrder32Little)

        if alphaInfo == .none {
            return isLittleEndian ? .bgr : .rgb
        }
        let alphaIsFirst = alphaInfo == .premultipliedFirst || alphaInfo == .first || alphaInfo == .noneSkipFirst

        if isLittleEndian {
            return alphaIsFirst ? .bgra : .abgr
        } else {
            return alphaIsFirst ? .argb : .rgba
        }
    }

    var chromaIsPremultipliedByAlpha: Bool {
        let alphaInfo = CGImageAlphaInfo(rawValue: rawValue & Self.alphaInfoMask.rawValue)
        return alphaInfo == .premultipliedFirst || alphaInfo == .premultipliedLast
    }

}
