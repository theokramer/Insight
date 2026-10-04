// Run with TextDetection.swift on macOS; exercises the same Vision engine used on iPhone.
import Foundation
import AppKit
import CoreText
import ImageIO
import Vision

@main struct VisionRegression {
  static func main() throws {
    let destination = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
    let width = 2000, height = 1500
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.setFillColor(CGColor(gray: 1, alpha: 1)); context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    var expected: [[String: Any]] = []
    func label(_ text: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, vertical: Bool = false, study: Bool = true) {
      let font = CTFontCreateWithName("Helvetica" as CFString, size, nil)
      let string = NSAttributedString(string: text, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font, NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 0.08, alpha: 1)])
      let line = CTLineCreateWithAttributedString(string)
      var ascent: CGFloat = 0, descent: CGFloat = 0
      let length = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil))
      context.saveGState(); context.translateBy(x: x, y: CGFloat(height)-y)
      if vertical { context.rotate(by: .pi/2) }
      context.textPosition = .zero; CTLineDraw(line, context); context.restoreGState()
      if study {
        let box = vertical ? CGRect(x:x-ascent,y:y-length,width:ascent+descent,height:length) : CGRect(x:x,y:y-ascent,width:length,height:ascent+descent)
        expected.append(["label":text,"x":box.minX/CGFloat(width),"y":box.minY/CGFloat(height),"width":box.width/CGFloat(width),"height":box.height/CGFloat(height)])
      }
    }
    label("NERVOUS SYSTEM · Study diagram", 100, 110, 54, study:false)
    // The diagram combines dense small text, distant words on one line, repeated labels, and sideways text.
    let names = ["Dendrites", "Cell body", "Nucleus", "Axon hillock", "Myelin sheath", "Node of Ranvier", "Axon terminals", "Synaptic vesicles", "Schwann cell", "Sodium channel", "Potassium channel", "Neurotransmitter"]
    for (i,name) in names.enumerated() {
      let y = CGFloat(260+i*70)
      label(name, 100, y, CGFloat(18 + (i%3)*3))
      context.setStrokeColor(CGColor(gray:0.7,alpha:1)); context.setLineWidth(2)
      context.move(to:CGPoint(x:420,y:CGFloat(height)-y+7));context.addLine(to:CGPoint(x:850,y:CGFloat(height)-y+7));context.strokePath()
    }
    label("Axon", 1150, 400, 32); label("Dendrite", 1650, 400, 32)
    label("Axon", 1150, 620, 32)
    label("Na+", 1150, 820, 30)
    label("Mitochondria", 1900, 1150, 32, vertical:true)
    let image = context.makeImage()!
    let url = destination.appendingPathComponent("diagram.png")
    let writer = CGImageDestinationCreateWithURL(url as CFURL,"public.png" as CFString,1,nil)!
    CGImageDestinationAddImage(writer,image,nil); guard CGImageDestinationFinalize(writer) else { fatalError("PNG write failed") }
    let baseline = VNRecognizeTextRequest(); baseline.recognitionLevel = .accurate; baseline.usesLanguageCorrection = false
    try VNImageRequestHandler(cgImage:image).perform([baseline])
    let old = (baseline.results ?? []).compactMap { o -> [String: Any]? in
      guard let t = o.topCandidates(1).first else { return nil }; let b=o.boundingBox
      return ["label":t.string,"x":b.minX,"y":1-b.maxY,"width":b.width,"height":b.height]
    }
    let detected = try InsightTextDetection.recognize(url:url)
    let result: [String:Any] = ["expected":expected,"baseline":old,"detected":detected]
    try JSONSerialization.data(withJSONObject:result,options:[.prettyPrinted,.sortedKeys]).write(to:destination.appendingPathComponent("vision.json"))
    // Bad paths must fail rather than returning an empty success.
    do { _ = try InsightTextDetection.recognize(url:destination.appendingPathComponent("missing.png")); fatalError("Missing image accepted") } catch { }
    print("Vision executed: \(expected.count) expected labels; \(old.count) baseline lines; \(detected.count) measured lines")
  }
}
