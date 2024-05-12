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
    @IBOutlet weak var cropButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var saveAll: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet var panGesture: UIPanGestureRecognizer!

    var editMode = false
    
    
    struct selectedImages2 {
        var image: UIImage
        var index: String
    }
    
    var selectedImages: [selectedImages2] = []
    var imageIndex = 0
    
    // Layer into which to draw bounding box paths.
    var pathLayer: CALayer?
    
    // Image parameters for reuse throughout app
    var imageWidth: CGFloat = 0
    var imageHeight: CGFloat = 0
    
    
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
        
        editButton.tag = 3
        cropButton.tag = 3
        leftButton.tag = 3
        rightButton.tag = 3
        saveAll.tag = 3
        editButton.backgroundColor = UIColor.white
        
        ViewController.fetchCoreData {items in
            if let items = (items ?? []) as [ImageEntity]? {
                print(items)
                for item in items {
                    guard let thisImage = UIImage(data: item.imageData ?? Data()) else {
                        return
                    }
                    self.selectedImages.append(selectedImages2.init(image: thisImage, index: item.id ?? ""))
                }
                //ViewController.deleteCoreData(indexPath: 0, items: items)
            } else {
                print("FEHLER")
            }
        }
    }
    
    func handleData() {
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if imageView.image == nil {
            promptPhoto()
        }
    }
    
}

