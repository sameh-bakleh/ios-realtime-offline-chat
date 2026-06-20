import ImageIO
import UIKit

enum ImageDownsampler {
  static func downsample(url: URL, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
    let options: CFDictionary = [
      kCGImageSourceShouldCache: false
    ] as CFDictionary

    guard let source = CGImageSourceCreateWithURL(url as CFURL, options) else { return nil }

    let maxDimension = max(pointSize.width, pointSize.height) * scale
    let downsampleOptions: CFDictionary = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceShouldCacheImmediately: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: maxDimension
    ] as CFDictionary

    guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else { return nil }
    return UIImage(cgImage: cgImage)
  }

  static func imagePixelSize(url: URL) -> CGSize? {
    let options: CFDictionary = [
      kCGImageSourceShouldCache: false
    ] as CFDictionary

    guard let source = CGImageSourceCreateWithURL(url as CFURL, options) else { return nil }
    guard let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return nil }
    guard let w = props[kCGImagePropertyPixelWidth] as? CGFloat,
          let h = props[kCGImagePropertyPixelHeight] as? CGFloat,
          w > 0, h > 0
    else { return nil }
    return CGSize(width: w, height: h)
  }
}

