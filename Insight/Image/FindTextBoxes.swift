//
//  FindTextBoxes.swift
//  Insight
//
//  Created by Theo Kramer on 12.05.24.
//

import Foundation
import UIKit
import Vision


extension ViewController {
    
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
    func performVisionRequest(image: CGImage, orientation: CGImagePropertyOrientation) {
        print("Executed Vision Request")
        // Fetch desired requests based on switch status.
        let requests = createVisionRequests()
        // Create a request handler.
        let imageRequestHandler = VNImageRequestHandler(cgImage: image,
                                                        orientation: orientation,
                                                        options: [:])
        
        // Send the requests to the request handler.
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
    func createVisionRequests() -> [VNRequest] {
        
        // Create an array to collect all desired requests.
        var requests: [VNRequest] = []
        
        
        
        // Create & include a request if and only if switch is ON.
        
            //requests.append(self.rectangleDetectionRequest)
        
        
            requests.append(self.textDetectionRequest)
        
        
        // Return grouped requests as a single array.
        return requests
    }
    

    
    func handleDetectedText(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            self.presentAlert("Text Detection Error", error: nsError)
            return
        }
        // Perform drawing on the main thread.
        DispatchQueue.main.async {
            guard let drawLayer = self.pathLayer,
                  let results = request?.results as? [VNTextObservation] else {
                return
            }
            
            
            
            print("handle!!")
            var newImageBoxArray:[ImageBox] = []
            
            for i in results {
                let newImageBox = ImageBox(frame: i, tag: Int.random(in: 1...100000000))
                newImageBoxArray.append(newImageBox)
            }
            
            
            self.saveBoxes(results: newImageBoxArray)
            
            
            //Display Rectangles above the text
            self.draw(text: newImageBoxArray, onImageWithBounds: drawLayer.frame)
            
            
            drawLayer.setNeedsDisplay()
        }
    }
    
    func saveBoxes(results: [ImageBox]) {
        if self.singleMode {
            
            self.singleImage.boxes = results
        } else {
            selectedImages[imageIndex].boxes = results
        }
    }
}
