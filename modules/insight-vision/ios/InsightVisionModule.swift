import ExpoModulesCore
import PDFKit
import Vision
import UIKit

public class InsightVisionModule: Module {
  public func definition() -> ModuleDefinition {
    Name("InsightVision")
    AsyncFunction("renderPDF") { (uri: String) -> [[String: Any]] in
      guard let url = URL(string: uri), let doc = PDFDocument(url: url) else { throw NSError(domain: "Insight", code: 1, userInfo: [NSLocalizedDescriptionKey: "This PDF could not be opened."]) }
      guard doc.pageCount <= 50, !doc.isLocked else { throw NSError(domain: "Insight", code: 2, userInfo: [NSLocalizedDescriptionKey: "Choose an unlocked PDF with 50 pages or fewer."]) }
      var pages: [[String: Any]] = []
      do {
        for i in 0..<doc.pageCount {
          guard let page = doc.page(at: i) else { continue }
          let bounds = page.bounds(for: .mediaBox)
          let scale = min(4, 3000 / max(bounds.width, bounds.height))
          let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
          let image = page.thumbnail(of: size, for: .mediaBox)
          guard let bytes = image.jpegData(compressionQuality: 0.92) else { continue }
          let target = FileManager.default.temporaryDirectory.appendingPathComponent("insight-pdf-\(UUID().uuidString).jpg")
          try bytes.write(to: target)
          pages.append(["uri": target.absoluteString, "width": image.size.width * image.scale, "height": image.size.height * image.scale])
        }
        return pages
      } catch {
        for p in pages { if let u = p["uri"] as? String, let url = URL(string: u) { try? FileManager.default.removeItem(at: url) } }
        throw error
      }
    }
    AsyncFunction("recognize") { (uri: String) -> [[String: Any]] in
      guard let url = URL(string: uri) else { throw NSError(domain: "InsightOCR", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image location."]) }
      return try InsightTextDetection.recognize(url: url)
    }
  }
}
