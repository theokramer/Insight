//
//  drawBoxes.swift
//  Insight
//
//  Created by Theo Kramer on 12.05.24.
//

import Foundation
import UIKit
import SwiftUI
import Vision


extension ViewController {
    @available(iOS 13.0, *)
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        
        return path
    }
    
    // MARK: - Path-Drawing
    fileprivate func boundingBox(forRegionOfInterest: CGRect, withinImageBounds bounds: CGRect) -> CGRect {
        let imageWidth = bounds.width
        let imageHeight = bounds.height
        
        // Begin with input rect.
        var rect = forRegionOfInterest
        
        // Reposition origin.
        rect.origin.x *= imageWidth
        rect.origin.x += bounds.origin.x
        rect.origin.y = (1 - rect.origin.y) * imageHeight + bounds.origin.y
        
        // Rescale normalized coordinates.
        rect.size.width *= imageWidth
        rect.size.height *= imageHeight
        
        return rect
    }
    
    func removeAllButtonsFromView() {
        for subview in view.subviews {
            if let button = subview as? UIButton {
                if button.tag != 3 {
                    button.removeFromSuperview()
                }
                
            }
        }
    }
    
    //Creates white Boxes above the detected Text Fields
    func draw(text: [VNTextObservation], onImageWithBounds bounds: CGRect) {
        removeAllButtonsFromView()
        var sliderValue = 0.5
        CATransaction.begin()
        
        // Array to hold groups of intersecting text observations
        var textGroups: [[VNTextObservation]] = []
        
        for wordObservation in text {
        var grouped = false
            
            let wordBox = boundingBox(forRegionOfInterest: wordObservation.boundingBox, withinImageBounds: bounds)
            
            // Check if the current word observation intersects with any existing group
            for (index, group) in textGroups.enumerated() {
                for groupObservation in group {
                    let groupBox = boundingBox(forRegionOfInterest: groupObservation.boundingBox, withinImageBounds: bounds)
                    let distanceX = abs(wordBox.midX - groupBox.midX)
                     let distanceY = abs(wordBox.midY - groupBox.midY)
                     let minXDistance = (wordBox.width + groupBox.width) / 2
                     let minYDistance = (wordBox.height + groupBox.height) / 2
                    if wordBox.intersects(groupBox) || distanceX <= CGFloat(sliderValue) + minXDistance && distanceY <=  CGFloat(sliderValue) + minYDistance {
                        // Add the current observation to the existing group
                        textGroups[index].append(wordObservation)
                        grouped = true
                        break
                    }
                }
                if grouped { break }
            }
            
            // If the current observation does not intersect with any existing group, create a new group
            if !grouped {
                textGroups.append([wordObservation])
            }
        }
        
        
        
        // Create buttons for each group of intersecting text observations
        for group in textGroups {
            let id = Int.random(in: 1..<100000000)
            let fillColor = UIColor.white // You may want to change the fill color as needed
            
            // Calculate the bounding box for the group
            
            for observation in group {
                
                var observationBox = boundingBox(forRegionOfInterest: observation.boundingBox, withinImageBounds: bounds)
                
                observationBox = observationBox.offsetBy(dx: 0, dy: (observationBox.minY - observationBox.maxY))
                let shapeButton = createShapeButton(frame: observationBox, fillColor: fillColor, tag: id)
                view.insertSubview(shapeButton, at: 1)
                
            }
            
            
            
            
            
            
        }
        
        CATransaction.commit()
    }
    
    //Makes the Boxes toggable
    func createShapeButton(frame: CGRect, fillColor: UIColor, tag: Int) -> UIButton {
        
        // Create shape layer
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: frame.width, height: frame.height)).cgPath
        
        shapeLayer.fillColor = fillColor.cgColor
        
        
        let button = UIButton()
        button.frame = frame
        button.tag = tag
        
        // Add shape layer to button's layer
        button.layer.addSublayer(shapeLayer)
        
        
        
        // Add action to button
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        
        
        return button
    }
}
