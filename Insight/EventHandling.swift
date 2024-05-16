//
//  EventHandling.swift
//  Insight
//
//  Created by Theo Kramer on 11.05.24.
//

import Foundation
import UIKit


extension ViewController {
    
    //Handle user swipe to select multiple Text Boxes in Edit Mode. TODO: Improve the recognition of the swipe
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
    
    
    //Is called, when the user presses the edit button. Calls saveEdits()
    @IBAction func editClicked(_ sender: Any) {
        
        if editMode {
            saveEdits()
        }
        
        editMode = !editMode
        editButton.backgroundColor = editMode ? UIColor.red : UIColor.white
        
    }
    
    //Switches between the Images
    @IBAction func rightClicked(_ sender: Any) {
        if selectedImages.count > imageIndex + 1 {
            imageIndex += 1
            handleCompletion(object: selectedImages[imageIndex].image)
        }
    }
    
    @IBAction func leftClicked(_ sender: Any) {
        if imageIndex > 0 {
            imageIndex -= 1
            handleCompletion(object: selectedImages[imageIndex].image)
        }
        
    }
    
    @IBAction func cropClicked(_ sender: Any) {
        if imageView.image != nil {
            presentCropViewController(image: imageView.image!)
        }
        
    }
    
    
    @IBAction func cancelClicked(_ sender: Any) {
        performSegue(withIdentifier: "showOverviewController2", sender: cellId)
    }
    
    
    @IBAction func saveAll(_ sender: Any) {
        //Call Database Function
        
        prepareImageForSaving(images: selectedImages)
        performSegue(withIdentifier: "showOverviewController2", sender: cellId)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       if (segue.identifier == "showOverviewController2") {
           let secondView = segue.destination as! OverviewController
           let object = sender as? String ?? ""
           print("OBJECT: \(object)")
           secondView.cellId = object
       }
    }
    
    
    
}
