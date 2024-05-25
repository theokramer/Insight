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


//Object to add and modify new Images
struct selectedImage {
    var image: UIImage
    var index: String
    var cropped: Bool
}

//Array of selected Images in Photo Picker
var selectedImages: [selectedImage] = []

@available(iOS 13.0, *)
class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate {
    
    //All Storyboard Components
    @IBOutlet weak var cropButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var saveAll: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet var panGesture: UIPanGestureRecognizer!
    @IBOutlet weak var toggleButton: UIButton!
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)*/
        
        //Give all Buttons the same Tag, so they doesn't disappear, when removing the Toggle-Buttons
        editButton.tag = 3
        cropButton.tag = 3
        leftButton.tag = 3
        rightButton.tag = 3
        saveAll.tag = 3
        cancelButton.tag = 3
        toggleButton.tag = 3
        
        //Improve readability of Edit Button
        editButton.backgroundColor = UIColor.white
    }
    
    /*@objc func onOrientationChange() {
        self.updateBoxPositions()
    }*/

    //Ask the User to select new Photos, when no Image is displayed
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if imageView.image == nil {
            promptPhoto()
        }
    }
    
}
