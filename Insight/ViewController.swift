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
    
    //Gets Id of the selected Topic when called by View Controller
    public var cellId:String = ""
    
    //Determines wether or not the User is currently editing the Text Boxes
    var editMode = false
    
    //Tracks the Index of the Image where the Cropped Button was clicked
    var imageIndex = 0
    
    
    //Object to add and modify new Images
    struct selectedImage {
        var image: UIImage
        var index: String
        var cropped: Bool
    }
    
    //Object to modify Images loaded from Core Data
    struct savedImage {
        var image: UIImage
        var index: String
        var topic: Topic
    }
    
    //Array of selected Images in Photo Picker
    var selectedImages: [selectedImage] = []
    
    //Array of saved Images from Core Data
    var savedImages: [savedImage] = []
    
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
        
        //Give all Buttons the same Tag, so they doesn't disappear, when removing the Toggle-Buttons
        editButton.tag = 3
        cropButton.tag = 3
        leftButton.tag = 3
        rightButton.tag = 3
        saveAll.tag = 3
        cancelButton.tag = 3
        
        //Improve readability of Edit Button
        editButton.backgroundColor = UIColor.white
        
        //Appends the savedImages Array, so the Images can be displayed
        ViewController.fetchCoreData {items in
            if let items = (items ?? []) as [ImageEntity]? {
                for item in items {
                    guard let thisImage = UIImage(data: item.imageData ?? Data()) else {
                        return
                    }
                    guard let myTopic = item.topic else {
                        return
                    }
                    if myTopic.id == self.cellId {
                        //Selected Images should not get appended, this is just for testing the feature and has to be updated
                        #if DEBUG
                        self.selectedImages.append(selectedImage.init(image: thisImage, index: item.id ?? "", cropped: false))
                        #endif
                        
                        //Fill the Array with all the Images in this explicit Topic
                        self.savedImages.append(savedImage.init(image: thisImage, index: item.id ?? "", topic: myTopic))
                    }
                    
                }
            }
        }
    }

    

    //Ask the User to select new Photos, when no Image is displayed
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if imageView.image == nil {
            promptPhoto()
        }
    }
    
}
