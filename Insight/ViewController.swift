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
var viewController = true
var maxImageIndex = 0

var editImages: [selectedImage] = []

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
    var firstTime = false
    
    var imageWidth: CGFloat = 0
    var imageHeight: CGFloat = 0
    
    //Gets Id of the selected Topic when called by View Controller
    public var cellId:String = ""
    
    //Determines wether or not the User is currently editing the Text Boxes
    var editMode = false


    
    //Fetch Request to get all added Topics of the User
    @FetchRequest(sortDescriptors: []) var topics:FetchedResults<Topic>
    
    // Background is black, so display status bar in white.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @objc func onOrientationChange() {
        handleCompletion(object: editImages[imageIndex].image, thisImageView: imageView, customBounds: editImages[imageIndex].boxes)
    }
    
    func scaleAndOrient(image: UIImage) -> UIImage {
        
        // Set a default value for limiting image size.
        let maxResolution: CGFloat = 640
        
        guard let cgImage = image.cgImage else {
            print("UIImage has no CGImage backing it!")
            return image
        }
        
        // Compute parameters for transform.
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        var transform = CGAffineTransform.identity
        
        var bounds = CGRect(x: 0, y: 0, width: width, height: height)
        
        if width > maxResolution ||
            height > maxResolution {
            let ratio = width / height
            if width > height {
                bounds.size.width = maxResolution
                bounds.size.height = round(maxResolution / ratio)
            } else {
                bounds.size.width = round(maxResolution * ratio)
                bounds.size.height = maxResolution
            }
        }
        
        
        let scaleRatio = bounds.size.width / width
        let orientation = image.imageOrientation
        switch orientation {
        case .up:
            transform = .identity
        case .down:
            transform = CGAffineTransform(translationX: width, y: height).rotated(by: .pi)
        case .left:
            let boundsHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundsHeight
            transform = CGAffineTransform(translationX: 0, y: width).rotated(by: 3.0 * .pi / 2.0)
        case .right:
            let boundsHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundsHeight
            transform = CGAffineTransform(translationX: height, y: 0).rotated(by: .pi / 2.0)
        case .upMirrored:
            transform = CGAffineTransform(translationX: width, y: 0).scaledBy(x: -1, y: 1)
        case .downMirrored:
            transform = CGAffineTransform(translationX: 0, y: height).scaledBy(x: 1, y: -1)
        case .leftMirrored:
            let boundsHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundsHeight
            transform = CGAffineTransform(translationX: height, y: width).scaledBy(x: -1, y: 1).rotated(by: 3.0 * .pi / 2.0)
        case .rightMirrored:
            let boundsHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundsHeight
            transform = CGAffineTransform(scaleX: -1, y: 1).rotated(by: .pi / 2.0)
        default:
            transform = .identity
        }
        
        return UIGraphicsImageRenderer(size: bounds.size).image { rendererContext in
            let context = rendererContext.cgContext
            
            if orientation == .right || orientation == .left {
                context.scaleBy(x: -scaleRatio, y: scaleRatio)
                context.translateBy(x: -height, y: 0)
            } else {
                context.scaleBy(x: scaleRatio, y: -scaleRatio)
                context.translateBy(x: 0, y: -height)
            }
            context.concatenate(transform)
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
    
    //Shows the selected and cropped Image
    func show(_ image: UIImage, thisImageView: UIImageView) {
        // Remove previous paths & image
        pathLayer?.removeFromSuperlayer()
        pathLayer = nil
        thisImageView.image = nil
        
        // Account for image orientation by transforming view.
        let correctedImage = scaleAndOrient(image: image)
        
        // Place photo inside imageView.
        thisImageView.image = correctedImage
        
        // Transform image to fit screen.
        guard let cgImage = correctedImage.cgImage else {
            print("Trying to show an image not backed by CGImage!")
            return
        }
        
        let fullImageWidth = CGFloat(cgImage.width)
        let fullImageHeight = CGFloat(cgImage.height)
        
        let imageFrame = thisImageView.frame
        let widthRatio = fullImageWidth / imageFrame.width
        let heightRatio = fullImageHeight / imageFrame.height
        
        // ScaleAspectFit: The image will be scaled down according to the stricter dimension.
        let scaleDownRatio = max(widthRatio, heightRatio)
        
        // Cache image dimensions to reference when drawing CALayer paths.
        imageWidth = fullImageWidth / scaleDownRatio
        imageHeight = fullImageHeight / scaleDownRatio
        
        // Prepare pathLayer to hold Vision results.
        let xLayer = (imageFrame.width - imageWidth) / 2
        let yLayer = thisImageView.frame.minY + (imageFrame.height - imageHeight) / 2
        let drawingLayer = CALayer()
        drawingLayer.bounds = CGRect(x: xLayer, y: yLayer, width: imageWidth, height: imageHeight)
        drawingLayer.anchorPoint = CGPoint.zero
        drawingLayer.position = CGPoint(x: xLayer, y: yLayer)
        //Change opacity of Rectangle HERE
        drawingLayer.opacity = 1
        pathLayer = drawingLayer
        self.view.layer.addSublayer(pathLayer!)
    }

    
    func handleCompletion(object: Any?, thisImageView: UIImageView, customBounds: [ImageBox]) {
        
        if let image = object as? UIImage {
            //TODO: Not the best Approach. Display after view is loaded!
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.show(image, thisImageView: thisImageView)
                //Calls the vision request
                
                    guard let drawLayer = pathLayer else  {
                        return
                    }
                    
                    //Display Rectangles above the text
                    self.draw(text: customBounds, onImageWithBounds: drawLayer.frame)
                    
                    
                    drawLayer.setNeedsDisplay()
                
            }
            
        }
    }
    
    override func viewDidLoad() {
        var boxesArray:[ImageBox] = []
        ViewController.fetchCoreDataBoxes {items in
            if let items = (items ?? []) as [ImageBoxes]? {
                for box in items {
                    if box.imageEntity2?.wrappedId == editImages[imageIndex].index {
                        let thisBoxFrame = VNTextObservation(boundingBox: CGRect(x: Double(box.minX), y: Double(box.minY), width: Double(box.width), height: Double(box.height)))
                        boxesArray.append(ImageBox(frame: thisBoxFrame, tag: Int(box.tag)))
                    }
        
                }
            } else {
                print("FEHLER")
            }
        }
        
            if editImages.count != 0 {
                handleCompletion(object: editImages[imageIndex].image, thisImageView: imageView, customBounds: boxesArray)
            }
        
        
        viewController = true
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
        if imageIndex == editImages.count - 1 || singleMode {
            rightButton.isHidden = true
        } else {
            rightButton.isHidden = false
        }
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.onOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        let backButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(prepareImageForSaving))
        self.navigationItem.leftBarButtonItem = backButton
        
        
        
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
        if editImages.count > imageIndex + 1 {
            imageIndex += 1
            
                handleCompletion(object: editImages[imageIndex].image, thisImageView: imageView, customBounds: editImages[imageIndex].boxes)
                /*if editImages[imageIndex].boxes.isEmpty {
                    
                } else {
                    handleCompletion(object: editImages[imageIndex].image, thisImageView: imageView, customBounds: editImages[imageIndex].boxes)
                }*/
                
                
            
            
            
            
           
        }
        if imageIndex == editImages.count - 1 || singleMode {
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
            
            handleCompletion(object: editImages[imageIndex].image, thisImageView: imageView, customBounds: editImages[imageIndex].boxes)
            
        }
        
        if imageIndex == editImages.count - 1 {
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
