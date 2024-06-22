//
//  FindTextBoxes.swift
//  Insight
//
//  Created by Theo Kramer on 12.05.24.
//

import Foundation
import UIKit
import Vision


extension OverviewController {
    
    // MARK: - Vision
    
    func presentAlert(_ title: String, error: NSError) {
        // Always present alert on main thread.
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title,
                                                    message: error.localizedDescription,
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK",
                                         style: .default) { _ in
                // Do nothing -- simply dismiss alert.
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    
    /// - Tag: PerformRequests
    func performVisionRequest(image: UIImage, orientation: CGImagePropertyOrientation) {
           guard let cgImage = image.cgImage else { return }
           
           print("Executed Vision Request")
           
           let textDetectionHandler = TextDetectionHandler(additionalVariable: image)
           let textDetectionRequest = VNDetectTextRectanglesRequest { (request, error) in
               textDetectionHandler.handleDetectedText(request: request, error: error)
           }
           textDetectionRequest.reportCharacterBoxes = true
           
           let requests: [VNRequest] = [textDetectionRequest]
           
           let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
           
           DispatchQueue.global(qos: .userInitiated).async {
               do {
                   try imageRequestHandler.perform(requests)
                   
               } catch let error as NSError {
                   print("Failed to perform image request: \(error)")
                   self.presentAlert("Image Request Failed", error: error)
                   return
               }
           }
       }
    
    /// - Tag: CreateRequests
    func createVisionRequests(activeImage: UIImage) -> [VNRequest] {
        
        
        // Create an array to collect all desired requests.
        var requests: [VNRequest] = []
        
        
        
        // Create & include a request if and only if switch is ON.
        
            //requests.append(self.rectangleDetectionRequest)
        
        textDetectionHandler.additionalVariable = activeImage
        requests.append(self.textDetectionRequest)
        
        
        // Return grouped requests as a single array.
        return requests
    }

}



// Wrapper-Klasse, die die zusätzliche Variable und den Request-Handler enthält
class TextDetectionHandler {
    var additionalVariable: UIImage
    
    init(additionalVariable: UIImage) {
        self.additionalVariable = additionalVariable
    }
    
    func handleDetectedText(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            print("Additional Variable: \(self.additionalVariable)")
            return
        }
        
        DispatchQueue.main.async {
            guard let results = request?.results as? [VNTextObservation] else {
                print("Fehler")
                return
            }
            
            print("handle!!")
            var newImageBoxArray: [ImageBox] = []
            
            for observation in results {
                let newImageBox = ImageBox(frame: observation, tag: Int.random(in: 1...100000000))
                newImageBoxArray.append(newImageBox)
            }
            
            self.saveBoxes(results: newImageBoxArray)
            
        }
    }
    
    func saveBoxes(results: [ImageBox]) {
        var thisImageEdit = selectedImage.init(image: additionalVariable, index: UUID().uuidString, cropped: false, boxes: results)
        editImages.append(thisImageEdit)
    }
}
