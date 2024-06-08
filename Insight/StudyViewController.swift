//
//  StudyViewController.swift
//  Insight
//
//  Created by Theo Kramer on 27.05.24.
//

import Foundation
import UIKit

class StudyViewController: ViewController {
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var imageViewStudy: UIImageView!
    
    @objc override func onOrientationChange() {
        handleCompletion(object: selectedImages[imageIndex].image, thisImageView: imageViewStudy)
    }
    
    override func viewDidLoad() {
        selectedImages.shuffle()
        nextButton.tag = 3
        if imageIndex == selectedImages.count - 1 {
            nextButton.isHidden = true
        } else {
            nextButton.isHidden = false
        }
        
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
            edgePan.edges = .right

        view.addGestureRecognizer(edgePan)
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.onOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        if selectedImages.count != 0 {
            handleCompletion(object: selectedImages[imageIndex].image, thisImageView: imageViewStudy)
        }
    }
    
    override func handleNextClick() {
        if imageIndex < selectedImages.count - 1 {
            imageIndex += 1
            handleCompletion(object: selectedImages[imageIndex].image, thisImageView: imageViewStudy)
        }
        if imageIndex == selectedImages.count - 1 {
            nextButton.isHidden = true
        } else {
            nextButton.isHidden = false
        }
    }
    
    @IBAction func nextClicked(_ sender: Any) {
        handleNextClick()
    }
}
