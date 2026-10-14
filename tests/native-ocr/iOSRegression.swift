import UIKit
import Foundation

@main final class OCRTestApp: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey:Any]?) -> Bool {
    window = UIWindow(frame: CGRect(x:0,y:0,width:400,height:800))
    window?.rootViewController = UIViewController(); window?.makeKeyAndVisible()
    DispatchQueue.global(qos: .userInitiated).async {
      let directory = FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0]
      do {
        let expected = try JSONSerialization.jsonObject(with:Data(contentsOf:Bundle.main.url(forResource:"expected",withExtension:"json")!)) as! [[String:Any]]
        for fixture in ["diagram.png", "rotated-exif.jpg"] {
          let started = Date()
          let result = try InsightTextDetection.recognize(url:Bundle.main.bundleURL.appendingPathComponent(fixture))
          for box in expected {
            let matches = result.contains { line in
              (line["label"] as? String)?.lowercased() == (box["label"] as? String)?.lowercased() &&
              abs(Double(line["x"] as! CGFloat)-(box["x"] as! Double)) < 0.005 &&
              abs(Double(line["y"] as! CGFloat)-(box["y"] as! Double)) < 0.005
            }
            if !matches { throw NSError(domain:"OCRRegression",code:1,userInfo:[NSLocalizedDescriptionKey:"Missing or misplaced label: \(box["label"]!) in \(fixture)"]) }
          }
          let data: [String:Any] = ["detected":result,"seconds":Date().timeIntervalSince(started)]
          try JSONSerialization.data(withJSONObject:data,options:[.prettyPrinted,.sortedKeys]).write(to:directory.appendingPathComponent("ocr-\(fixture).json"))
        }
      } catch { try? String(describing:error).write(to:directory.appendingPathComponent("ocr-error.txt"),atomically:true,encoding:.utf8) }
    }
    return true
  }
}
