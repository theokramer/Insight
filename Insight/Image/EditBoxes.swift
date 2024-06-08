//
//  EditBoxes.swift
//  Insight
//
//  Created by Theo Kramer on 12.05.24.
//

import Foundation
import UIKit

extension ViewController {
    //Updates the changes of the user in Edit Mode.
    func saveEdits() {
        if editMode {
            let id = Int.random(in: 0..<10000000)
            let id2 = Int.random(in: 0..<10000000)
            for view in view.subviews {
                if let button = view as? UIButton {
                    for layer in button.layer.sublayers ?? [] {
                        print(layer)
                        guard let shapeLayer = layer as? CAShapeLayer else {
                            continue
                        }
                        //Wenn das edit endet, werden alle Buttons, die die gleiche Farbe haben gegrouped -> Das jetzt für unendlich viele Farben machen?
                        if shapeLayer.fillColor == UIColor.red.cgColor {
                            
                            button.tag = id
                            shapeLayer.fillColor = UIColor.white.cgColor
                        }
                        if shapeLayer.fillColor == UIColor.blue.cgColor {
                            
                            button.tag = id2
                            shapeLayer.fillColor = UIColor.white.cgColor
                        }

                    }
                    
                }
                
            }
            
        }
        allWhite()
        
    }
    
    //Makes all Text Boxes white, when changing between editMode and normal Mode
    func allWhite() {
        for view in view.subviews {
            if let button = view as? UIButton {
                for layer in button.layer.sublayers ?? [] {
                    guard let shapeLayer = layer as? CAShapeLayer else {
                        continue
                    }
                    
                        shapeLayer.fillColor = UIColor.white.cgColor

                }
                
            }
            
        }
    }
}
