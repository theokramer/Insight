
import Photos
import UIKit
import Vision
import SwiftUI
import CropViewController
import PhotosUI
import CoreData

var imageIndex = 0
var viewController = true
var maxImageIndex = 0
var editImages: [selectedImage] = []

@available(iOS 13.0, *)
class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate, UIScrollViewDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet var panGesture: UIPanGestureRecognizer!
    @IBOutlet weak var scrollView: UIScrollView!
    
    public var editAllClicked = false
    let toggleButton = UIButton(type: .custom)
    let nButton = UIButton(type: .custom)
    
    private var lastPanPosition: CGPoint = .zero
    
    var singleMode = false
    var firstTime = false
    var imageWidth: CGFloat = 0
    var imageHeight: CGFloat = 0
    
    public var cellId: String = ""
    var editMode = false

    @FetchRequest(sortDescriptors: []) var topics: FetchedResults<Topic>
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @objc func onOrientationChange() {
        handleCompletion(object: editImages[imageIndex].image, thisImageView: imageView, customBounds: editImages[imageIndex].boxes)
    }
    
    func scaleAndOrient(image: UIImage) -> UIImage {
        let maxResolution: CGFloat = 640
        
        guard let cgImage = image.cgImage else {
            print("UIImage has no CGImage backing it!")
            return image
        }
        
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        var transform = CGAffineTransform.identity
        
        var bounds = CGRect(x: 0, y: 0, width: width, height: height)
        
        if width > maxResolution || height > maxResolution {
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
    
    func show(_ image: UIImage, thisImageView: UIImageView) {
        pathLayer?.removeFromSuperlayer()
        pathLayer = nil
        thisImageView.image = nil
        
        let correctedImage = scaleAndOrient(image: image)
        thisImageView.image = correctedImage
        
        guard let cgImage = correctedImage.cgImage else {
            print("Trying to show an image not backed by CGImage!")
            return
        }
        
        let fullImageWidth = CGFloat(cgImage.width)
        let fullImageHeight = CGFloat(cgImage.height)
        
        let imageFrame = thisImageView.frame
        let widthRatio = fullImageWidth / imageFrame.width
        let heightRatio = fullImageHeight / imageFrame.height
        
        let scaleDownRatio = max(widthRatio, heightRatio)
        
        imageWidth = fullImageWidth / scaleDownRatio
        imageHeight = fullImageHeight / scaleDownRatio
        
        let xLayer = (imageFrame.width - imageWidth) / 2
        let yLayer = thisImageView.frame.minY + (imageFrame.height - imageHeight) / 2
        let drawingLayer = CALayer()
        drawingLayer.bounds = CGRect(x: xLayer, y: yLayer, width: imageWidth, height: imageHeight)
        drawingLayer.anchorPoint = CGPoint.zero
        drawingLayer.position = CGPoint(x: xLayer, y: yLayer)
        drawingLayer.opacity = 1
        pathLayer = drawingLayer
        self.scrollView.layer.addSublayer(pathLayer!)
    }

    func handleCompletion(object: Any?, thisImageView: UIImageView, customBounds: [ImageBox]) {
        if let image = object as? UIImage {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.show(image, thisImageView: thisImageView)
                guard let drawLayer = pathLayer else {
                    return
                }
                self.draw(text: customBounds, onImageWithBounds: drawLayer.frame)
                drawLayer.setNeedsDisplay()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let imageSize = imageView.image?.size {
                    scrollView.contentSize = imageSize
                }
        
        
        setupScrollView()

        imageView.isUserInteractionEnabled = true // Allow interaction with imageView and its subviews

        var boxesArray: [ImageBox] = []
        ViewController.fetchCoreDataBoxes { items in
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
        editButton.addTarget(self, action: #selector(editBoxes(_:)), for: .touchUpInside)

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
        
        leftButton.tag = 3
        rightButton.tag = 3
        
        if imageIndex == editImages.count - 1 || singleMode {
              rightButton.isHidden = true
          } else {
              rightButton.isHidden = false
          }
          UIDevice.current.beginGeneratingDeviceOrientationNotifications()
          NotificationCenter.default.addObserver(self, selector: #selector(self.onOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
          let backButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(prepareImageForSaving))
          self.navigationItem.leftBarButtonItem = backButton
        
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc func screenEdgeSwipedL(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .recognized {
            handlePrevClick()
        }
    }
        
    @objc func screenEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .recognized {
            handleNextClick()
        }
    }
    
    

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    @objc func editBoxes(_ sender: UIButton) {
        editMode.toggle()
        if editMode {
            sender.setImage(UIImage(systemName: "pencil.circle.fill"), for: .normal)
        } else {
            sender.setImage(UIImage(systemName: "pencil.circle"), for: .normal)
        }
        handleCompletion(object: editImages[imageIndex].image, thisImageView: imageView, customBounds: editImages[imageIndex].boxes)
    }


    func handleNextClick() {
        if editImages.count > imageIndex + 1 {
            imageIndex += 1
            
            handleCompletion(object: editImages[imageIndex].image, thisImageView: imageView, customBounds: editImages[imageIndex].boxes)
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
    
}


// MARK: - UIScrollViewDelegate

extension ViewController {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    
    
    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.zoomScale = 1.0 // Set initial zoom scale
        
        
        // Add pan gesture recognizer for panning the image
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        scrollView.addGestureRecognizer(panGesture)
        
        // Enable user interaction for imageView
        imageView.isUserInteractionEnabled = true
    }

    
    @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        guard let imageView = imageView else { return }
        
        let translation = recognizer.translation(in: imageView.superview)
        
        switch recognizer.state {
        case .began, .changed:
            imageView.center = CGPoint(x: imageView.center.x + translation.x, y: imageView.center.y + translation.y)
            recognizer.setTranslation(.zero, in: imageView.superview)
        default:
            break
        }
    }
}
