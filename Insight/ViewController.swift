//
//  ViewController.swift
//  Insight
//
//  Created by Theo Kramer on 11.05.24.
//

import Photos
import UIKit
import Vision
import SwiftUI
import CropViewController
import PhotosUI
import CoreData

//Tracks the Index of the current Image
var imageIndex = 0




@available(iOS 13.0, *)
class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate {
    
    //All Storyboard Components
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet var panGesture: UIPanGestureRecognizer!
    
    public var editAllClicked = false
    
    let toggleButton = UIButton(type: .custom)
    let nButton = UIButton(type: .custom)
    
    var singleMode = false
    
    //Gets Id of the selected Topic when called by View Controller
    public var cellId:String = ""
    public var singleImage = selectedImage(image: UIImage(), index: "", cropped: false, boxes: [])
    
    //Determines wether or not the User is currently editing the Text Boxes
    var editMode = false
    
    // Layer into which to draw bounding box paths.
    var pathLayer: CALayer?
    
    // Image parameters for reuse throughout app
    var imageWidth: CGFloat = 0
    var imageHeight: CGFloat = 0
    
    //Fetch Request to get all added Topics of the User
    @FetchRequest(sortDescriptors: []) var topics:FetchedResults<Topic>
    
    lazy var textDetectionRequest: VNDetectTextRectanglesRequest = {
        let textDetectRequest = VNDetectTextRectanglesRequest(completionHandler: self.handleDetectedText)
        // Tell Vision to report bounding box around each character.
        textDetectRequest.reportCharacterBoxes = true
        return textDetectRequest
    }()
    
    // Background is black, so display status bar in white.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @objc func onOrientationChange() {
        if singleMode {
            handleCompletion(object: singleImage.image, thisImageView: imageView)
        } else {
            handleCompletion(object: selectedImages[imageIndex].image, thisImageView: imageView)
        }
    }
    
    override func viewDidLoad() {
        navigationController?.navigationBar.isHidden = false
        super.viewDidLoad()
        
        let editButton = UIButton(type: .custom)
        
        editButton.setImage(UIImage(systemName: "pencil"), for: .normal) // Image can be downloaded from here below link
        editButton.setTitleColor(.white, for: .normal) // You can change the TitleColor
        editButton.addTarget(self, action: #selector(editBoxes), for: .touchUpInside)
        
        toggleButton.setImage(UIImage(systemName: "lightswitch.on"), for: .normal) // Image can be downloaded from here below link
        toggleButton.setTitleColor(.white, for: .normal) // You can change the TitleColor
        toggleButton.addTarget(self, action: #selector(toggleBoxes), for: .touchUpInside)
        
        let cropButton = UIButton(type: .custom)
        cropButton.setImage(UIImage(systemName: "crop"), for: .normal) // Image can be downloaded from here below link
        cropButton.setTitleColor(.white, for: .normal) // You can change the TitleColor
        cropButton.addTarget(self, action: #selector(cropBoxes), for: .touchUpInside)
        
        
        let toggle = UIBarButtonItem(customView: toggleButton)
        let edit = UIBarButtonItem(customView: editButton)
        let crop = UIBarButtonItem(customView: cropButton)
        
        
        navigationItem.rightBarButtonItems = [toggle, edit, crop]
        
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
            edgePan.edges = .right

        view.addGestureRecognizer(edgePan)
        
        
        let edgePanL = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwipedL))
            edgePanL.edges = .left

        view.addGestureRecognizer(edgePanL)
        
        
        if imageIndex == 0 || singleMode {
            leftButton.isHidden = true
        } else {
            leftButton.isHidden = false
        }
        if imageIndex == selectedImages.count - 1 || singleMode {
            rightButton.isHidden = true
        } else {
            rightButton.isHidden = false
        }
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.onOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        let backButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(prepareImageForSaving))
        self.navigationItem.leftBarButtonItem = backButton
        if selectedImages.count != 0 {  
            if singleMode {
                handleCompletion(object: singleImage.image, thisImageView: imageView)
            } else {
                handleCompletion(object: selectedImages[imageIndex].image, thisImageView: imageView)
                
            }
        }
        
        
        //Give all Buttons the same Tag, so they doesn't disappear, when removing the Toggle-Buttons
        leftButton.tag = 3
        rightButton.tag = 3
    }
    
    @objc func screenEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .recognized {
            handleNextClick()
        }
    }
    
    @objc func screenEdgeSwipedL(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .recognized {
            handlePrevClick()
        }
    }
    
    
    
    func handleNextClick() {
        if selectedImages.count > imageIndex + 1 {
            imageIndex += 1
            if singleMode {
                handleCompletion(object: singleImage.image, thisImageView: imageView)
            } else {
                handleCompletion(object: selectedImages[imageIndex].image, thisImageView: imageView)
            }
        }
        if imageIndex == selectedImages.count - 1 || singleMode {
            rightButton.isHidden = true
        } else {
            rightButton.isHidden = false
        }
        
        if imageIndex == 0 || singleMode {
            leftButton.isHidden = true
        } else {
            leftButton.isHidden = false
        }
    }
    
    func handlePrevClick() {
        if imageIndex > 0 {
            imageIndex -= 1
            if singleMode {
                handleCompletion(object: singleImage.image, thisImageView: imageView)
            } else {
                handleCompletion(object: selectedImages[imageIndex].image, thisImageView: imageView)
            }
            
        }
        
        if imageIndex == selectedImages.count - 1 {
            rightButton.isHidden = true
        } else {
            rightButton.isHidden = false
        }
        
        if imageIndex == 0 {
            leftButton.isHidden = true
        } else {
            leftButton.isHidden = false
        }
    }

    //Ask the User to select new Photos, when no Image is displayed
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
}
