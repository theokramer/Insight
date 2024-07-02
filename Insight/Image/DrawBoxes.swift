import Foundation
import UIKit
import SwiftUI
import Vision

var toggleColor: UIColor = .purple

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
    
    func removeAllButtonsFromView(thisImageView: UIImageView) {
            for subview in thisImageView.subviews {
                if let button = subview as? UIButton {
                    if button.tag != 3 {
                        button.removeFromSuperview()
                    }
                }
            }
        
        
    }
    
    func draw(text: [ImageBox], onImageWithBounds bounds: CGRect, thisImageView: UIImageView) {
        removeAllButtonsFromView(thisImageView: thisImageView)
        var id = 0
        
        CATransaction.begin()
        
        for wordObservation in text {
            id = wordObservation.tag
            let fillColor = toggleColor
            
            var observationBox = boundingBox(forRegionOfInterest: wordObservation.frame.boundingBox, withinImageBounds: bounds)
            observationBox = observationBox.offsetBy(dx: 0, dy: (observationBox.minY - observationBox.maxY))
            
            
            let shapeButton = createShapeButton(frame: observationBox, fillColor: fillColor, tag: id)
            thisImageView.addSubview(shapeButton)  // <- Buttons zur imageView hinzufügen
        }
        
        CATransaction.commit()
    }

    // Makes the Boxes toggable
    func createShapeButton(frame: CGRect, fillColor: UIColor, tag: Int) -> UIButton {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: frame.width, height: frame.height)).cgPath
        shapeLayer.fillColor = editMode ? fillColor.withAlphaComponent(0.7).cgColor : fillColor.cgColor
        let button = UIButton()
        button.frame = frame
        button.tag = tag
        button.layer.addSublayer(shapeLayer)
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
}
