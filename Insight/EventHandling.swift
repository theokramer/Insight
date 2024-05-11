//
//  EventHandling.swift
//  Insight
//
//  Created by Theo Kramer on 11.05.24.
//

import Foundation
import UIKit


extension ViewController {
    
    @IBAction func panRecognized(_ sender: Any) {
        guard let panGesture = sender as? UIPanGestureRecognizer else {
            return
        }
        let location = panGesture.location(in: view)
        for case let button as UIButton in view.subviews {
            if button.frame.offsetBy(dx: 0, dy: -(button.frame.minY - button.frame.maxY)).contains(location) {
                    for layer in button.layer.sublayers ?? [] {
                        guard let shapeLayer = layer as? CAShapeLayer else {
                            continue
                        }
                        if editMode  {
                            if shapeLayer.fillColor == UIColor.red.cgColor {
                                
                                shapeLayer.fillColor = UIColor.white.cgColor
                            } else {
                                shapeLayer.fillColor = UIColor.red.cgColor
                            }
                        }
                        
                        
                    }
                }
            }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if selectedImages.count > imageIndex + 1 {
            imageIndex += 1
            handleCompletion(object: selectedImages[imageIndex])
        }
        
    }
    
    @IBAction func cropClicked(_ sender: Any) {
        if imageView.image != nil {
            presentCropViewController(image: imageView.image!)
        }
        
    }
    
    
    
}
