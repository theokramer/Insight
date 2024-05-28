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
    
    //Gets Id of the selected Topic when called by View Controller
    public var cellId:String = ""
    
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
        handleCompletion(object: selectedImages[imageIndex].image, thisImageView: imageView)
    }
    
    override func viewDidLoad() {
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
        
        
        if imageIndex == 0 {
            leftButton.isHidden = true
        } else {
            leftButton.isHidden = false
        }
        if imageIndex == selectedImages.count - 1 {
            rightButton.isHidden = true
        } else {
            rightButton.isHidden = false
        }
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.onOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        let backButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(prepareImageForSaving))
        self.navigationItem.leftBarButtonItem = backButton
        if selectedImages.count != 0 {  
            self.handleCompletion(object: selectedImages[imageIndex].image, thisImageView: imageView)
        }
        
        
        //Give all Buttons the same Tag, so they doesn't disappear, when removing the Toggle-Buttons
        leftButton.tag = 3
        rightButton.tag = 3
    }

    //Ask the User to select new Photos, when no Image is displayed
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
}
