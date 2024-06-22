
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
        editButton.setImage(UIImage(systemName: "pencil"), for: .normal)
        editButton.setTitleColor(.white, for: .normal)
        editButton.addTarget(self, action: #selector(editBoxes(_:)), for: .touchUpInside)
        
        let barButton = UIBarButtonItem(customView: editButton)
        self.navigationItem.rightBarButtonItem = barButton
        
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
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
        imageIndex += 1
    }
    
    func handlePrevClick() {
        imageIndex -= 1
    }
}


// MARK: - UIScrollViewDelegate

extension ViewController {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForZooming()
        
        let imageViewSize = imageView.frame.size
        let scrollViewSize = scrollView.bounds.size
        
        let verticalPadding = imageViewSize.height < scrollViewSize.height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0
        let horizontalPadding = imageViewSize.width < scrollViewSize.width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0
        
        scrollView.contentInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
        
        // Adjust content offset to zoom into the center of pinch gesture
        let offsetX = max((scrollView.contentSize.width - scrollView.bounds.size.width) / 2, 0)
        let offsetY = max((scrollView.contentSize.height - scrollView.bounds.size.height) / 2, 0)
        
        scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.contentInset = .zero // Reset content inset when zooming starts
    }
    
    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 10.0
        scrollView.zoomScale = 1.0 // Set initial zoom scale
        
        // Add pan gesture recognizer for panning the image
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        imageView.addGestureRecognizer(panGesture)
        
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
    
    private func updateConstraintsForZooming() {
        guard let imageView = imageView else { return }
        
        let imageViewSize = imageView.frame.size
        let scrollViewSize = scrollView.bounds.size
        
        let verticalPadding = imageViewSize.height < scrollViewSize.height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0
        let horizontalPadding = imageViewSize.width < scrollViewSize.width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0
        
        scrollView.contentInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
    }
}
