import Foundation
import Vision
import ImageIO
import CoreImage

// Shared by the Expo module and the image regression harness.
enum InsightTextDetection {
  static func recognize(url: URL) throws -> [[String: Any]] {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
      throw NSError(domain: "InsightOCR", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not open the image for text detection. Reimport it and try again."])
    }
    let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
    let orientation = CGImagePropertyOrientation(rawValue: (properties?[kCGImagePropertyOrientation] as? UInt32) ?? 1) ?? .up
    // Imported JPEGs are upright. Preserve EXIF for other callers as well.
    let upright = try uprightImage(image, orientation: orientation)
    var output: [[String: Any]] = []
    // Vision recognizes mixed text orientations in a single pass.
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.minimumTextHeight = 0.002
    request.usesLanguageCorrection = false // Preserve technical names and symbols.
    request.automaticallyDetectsLanguage = true
    try VNImageRequestHandler(cgImage: upright, orientation: .up).perform([request])
    let regex = try NSRegularExpression(pattern: "\\S+")
    for observation in request.results ?? [] {
      guard let text = observation.topCandidates(1).first, !text.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
      let box = map(observation.boundingBox)
      var words: [[String: Any]] = []
      // Whitespace ranges retain punctuation (e.g. Na+, 5′) in the measured label.
      let string = text.string
      for match in regex.matches(in: string, range: NSRange(string.startIndex..., in: string)) {
        guard let range = Range(match.range, in: string), let measured = try text.boundingBox(for: range) else { continue }
        words.append(fields(String(string[range]), map(measured.boundingBox)))
      }
      var result = fields(string, box)
      result["confidence"] = text.confidence
      result["words"] = words
      output.append(result)
    }
    return output
  }

  private static func uprightImage(_ image: CGImage, orientation: CGImagePropertyOrientation) throws -> CGImage {
    if orientation == .up { return image }
    // Vision applies EXIF consistently; CIImage makes the physical image upright for recognition.
    let oriented = CIImage(cgImage: image).oriented(orientation)
    guard let result = CIContext().createCGImage(oriented, from: oriented.extent) else {
      throw NSError(domain: "InsightOCR", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not read the image orientation."])
    }
    return result
  }

  private static func map(_ b: CGRect) -> CGRect {
    // Vision coordinates are bottom-left; the app uses the upright image's top-left.
    let r = CGRect(x: b.minX, y: 1 - b.maxY, width: b.width, height: b.height)
    return r
  }

  private static func fields(_ label: String, _ box: CGRect) -> [String: Any] {
    let b = box.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
    return ["label": label, "x": b.minX, "y": b.minY, "width": b.width, "height": b.height]
  }
}
