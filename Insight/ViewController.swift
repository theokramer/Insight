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



@available(iOS 13.0, *)
class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet var panGesture: UIPanGestureRecognizer!
    var drawingMode = false
    var editMode = false
    var myImage = UIImage()
    private var selection = [String: PHPickerResult]()
    private var selectedAssetIdentifiers = [String]()
    private var selectedAssetIdentifierIterator: IndexingIterator<[String]>?
    private var currentAssetIdentifier: String?
    
    // Layer into which to draw bounding box paths.
    var pathLayer: CALayer?
    
    // Image parameters for reuse throughout app
    var imageWidth: CGFloat = 0
    var imageHeight: CGFloat = 0
    
    //Handle user swipe to select multiple Text Boxes in Edit Mode. TODO: Improve the recognition of the swipe
    @IBAction func panRecognized(_ sender: Any) {
        guard let panGesture = sender as? UIPanGestureRecognizer else {
            return
        }
        let location = panGesture.location(in: view)
        for case let button as UIButton in view.subviews {
            if button.frame.offsetBy(dx: 0, dy: -(button.frame.minY - button.frame.maxY)).contains(location) {
                    for layer in button.layer.sublayers ?? [] {
                        guard let shapeLayer = layer as? CAShapeLayer else {
                            continue
                        }
                        if editMode  {
                            if shapeLayer.fillColor == UIColor.red.cgColor {
                                
                                shapeLayer.fillColor = UIColor.white.cgColor
                            } else {
                                shapeLayer.fillColor = UIColor.red.cgColor
                            }
                        }
                        
                        
                    }
                }
            }
    }
    
    //Updates the changes of the user in Edit Mode.
    fileprivate func saveEdits() {
        if editMode {
            let id = Int.random(in: 0..<10000000)
            let id2 = Int.random(in: 0..<10000000)
            for view in view.subviews {
                if let button = view as? UIButton {
                    for layer in button.layer.sublayers ?? [] {
                        print(layer)
                        guard let shapeLayer = layer as? CAShapeLayer else {
                            continue
                        }
                        //Wenn das edit endet, werden alle Buttons, die die gleiche Farbe haben gegrouped -> Das jetzt für unendlich viele Farben machen?
                        if shapeLayer.fillColor == UIColor.red.cgColor {
                            
                            button.tag = id
                            shapeLayer.fillColor = UIColor.white.cgColor
                        }
                        if shapeLayer.fillColor == UIColor.blue.cgColor {
                            
                            button.tag = id2
                            shapeLayer.fillColor = UIColor.white.cgColor
                        }

                    }
                    
                }
                
            }
            
        }
        allWhite()
        
    }
    
    

    //Is called, when the user presses the edit button. Calls saveEdits()
    @IBAction func editClicked(_ sender: Any) {
        
        
        if editMode {
            saveEdits()
        }
        
        editMode = !editMode
        editButton.backgroundColor = editMode ? UIColor.red : UIColor.white
        
    }
    
    //Makes all Text Boxes white, when changing between editMode and normal Mode
    func allWhite() {
        for view in view.subviews {
            if let button = view as? UIButton {
                for layer in button.layer.sublayers ?? [] {
                    guard let shapeLayer = layer as? CAShapeLayer else {
                        continue
                    }
                    
                        shapeLayer.fillColor = UIColor.white.cgColor
                    
                    

                }
                
            }
            
        }
    }

    // Background is black, so display status bar in white.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editButton.tag = 3
        editButton.backgroundColor = UIColor.white
        
        
        // Tapping the image view brings up the photo picker.
        //let photoTap = UITapGestureRecognizer(target: self, action: #selector(promptPhoto))
        //self.view.addGestureRecognizer(photoTap)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if imageView.image == nil {
            promptPhoto()
        }
    }
    
    func handleCompletion(assetIdentifier: String, object: Any?, error: Error? = nil) {
        if let image = object as? UIImage {
            show(image)
            let cgOrientation = CGImagePropertyOrientation(image.imageOrientation)
            
            // Fire off request based on URL of chosen photo.
            guard let cgImage = image.cgImage else {
                return
            }
            
            letUserDraw(image: cgImage, orientation: cgOrientation)
        }
    }
    
    private func presentPicker(filter: PHPickerFilter?) {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        
        // Set the filter type according to the user’s selection.
        configuration.filter = filter
        // Set the mode to avoid transcoding, if possible, if your app supports arbitrary image/video encodings.
        configuration.preferredAssetRepresentationMode = .current
        // Set the selection behavior to respect the user’s selection order.
        configuration.selection = .ordered
        // Set the selection limit to enable multiselection.
        configuration.selectionLimit = 0
        // Set the preselected asset identifiers with the identifiers that the app tracks.
        configuration.preselectedAssetIdentifiers = selectedAssetIdentifiers
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        displayNext()
    }
    
    
    //Let the User select a photo of his Library or Take a new one
    @objc
    func promptPhoto() {
        
        let prompt = UIAlertController(title: "Choose a Photo",
                                       message: "Please choose a photo.",
                                       preferredStyle: .actionSheet)
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        func presentCamera(_ _: UIAlertAction) {
            imagePicker.sourceType = .camera
            self.present(imagePicker, animated: true)
        }
        
        let cameraAction = UIAlertAction(title: "Camera",
                                         style: .default,
                                         handler: presentCamera)
        
        func presentLibrary(_ _: UIAlertAction) {
            
                presentPicker(filter: nil)
            
        }
        
        let libraryAction = UIAlertAction(title: "Photo Library",
                                          style: .default,
                                          handler: presentLibrary)
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel,
                                         handler: nil)
        
        // Implementierung der anderen Aktionen ...
        
        // Angabe der Ortungsinformationen für den Popover
        if let popoverController = prompt.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        // Hinzufügen der Aktionen zum Alert Controller
        prompt.addAction(cameraAction)
        prompt.addAction(libraryAction)
        prompt.addAction(cancelAction)
        // Weitere Aktionen hinzufügen...
        
        // Präsentieren des Alert Controllers
        self.present(prompt, animated: true, completion: nil)
    }
    
    // MARK: - Helper Methods
    
    /// - Tag: PreprocessImage
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
    
    func presentAlert(_ title: String, error: NSError) {
        // Always present alert on main thread.
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title,
                                                    message: error.localizedDescription,
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK",
                                         style: .default) { _ in
                // Do nothing -- simply dismiss alert.
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dismiss picker, returning to original root viewController.
        dismiss(animated: true, completion: nil)
    }
    
    //Show CropViewController, to Crop the Image
    func presentCropViewController(image: UIImage) {
        let cropViewController = CropViewController(croppingStyle: .default, image: image)
        cropViewController.delegate = self
        self.present(cropViewController, animated: true, completion: nil)
    }
    
    //Let the USer crop the selected image and than show it
    func cropViewController(_ cropViewController: CropViewController, didCropImageToRect cropRect: CGRect, angle: Int) {
        
        guard let originalImage = cropImage2(image: myImage, rect: cropRect, scale: myImage.scale) else {
             return
         }
        
        // Display image on screen.
        show(originalImage)
        
        
        // Convert from UIImageOrientation to CGImagePropertyOrientation.
        let cgOrientation = CGImagePropertyOrientation(originalImage.imageOrientation)
        
        // Fire off request based on URL of chosen photo.
        guard let cgImage = originalImage.cgImage else {
            return
        }
        
        letUserDraw(image: cgImage, orientation: cgOrientation)
        
        
        
        // Dismiss the picker to return to original view controller.
        dismiss(animated: true, completion: nil)
        
    }
    
    internal func imagePickerController(_ picker: UIImagePickerController,
                                        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        // Extract chosen image.
        let originalImage: UIImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        myImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        
        // Dismiss the picker to return to original view controller.
        dismiss(animated: true, completion: nil)
        
        presentCropViewController(image: originalImage)
        
    }
    
    //Performs the selected Cropping. TODO: Take care of the angle and orientation of the image
    func cropImage2(image: UIImage, rect: CGRect, scale: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: rect.size.width / scale, height: rect.size.height / scale), true, 0.0)
        image.draw(at: CGPoint(x: -rect.origin.x / scale, y: -rect.origin.y / scale))
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return croppedImage
    }
    
    //Calls the vision request
    func letUserDraw(image: CGImage, orientation: CGImagePropertyOrientation) {
        
        //Möglichkeit geben, dass der User auf dem Bild ein Rechteck zeichnet
        //Die bounds von dem Rechteck bestimmen dann in welchem Bereich die Texte verdeckt werden. Damit so etwas wie die Überschrift oder so nicht affected wird
        
        if(true) {
            performVisionRequest(image: image, orientation: orientation)
        }
    }
    
    //Shows the selected and cropped Image
    func show(_ image: UIImage) {
        
        // Remove previous paths & image
        pathLayer?.removeFromSuperlayer()
        pathLayer = nil
        imageView.image = nil
        
        // Account for image orientation by transforming view.
        let correctedImage = scaleAndOrient(image: image)
        
        // Place photo inside imageView.
        imageView.image = correctedImage
        
        // Transform image to fit screen.
        guard let cgImage = correctedImage.cgImage else {
            print("Trying to show an image not backed by CGImage!")
            return
        }
        
        let fullImageWidth = CGFloat(cgImage.width)
        let fullImageHeight = CGFloat(cgImage.height)
        
        let imageFrame = imageView.frame
        let widthRatio = fullImageWidth / imageFrame.width
        let heightRatio = fullImageHeight / imageFrame.height
        
        // ScaleAspectFit: The image will be scaled down according to the stricter dimension.
        let scaleDownRatio = max(widthRatio, heightRatio)
        
        // Cache image dimensions to reference when drawing CALayer paths.
        imageWidth = fullImageWidth / scaleDownRatio
        imageHeight = fullImageHeight / scaleDownRatio
        
        // Prepare pathLayer to hold Vision results.
        let xLayer = (imageFrame.width - imageWidth) / 2
        let yLayer = imageView.frame.minY + (imageFrame.height - imageHeight) / 2
        let drawingLayer = CALayer()
        drawingLayer.bounds = CGRect(x: xLayer, y: yLayer, width: imageWidth, height: imageHeight)
        drawingLayer.anchorPoint = CGPoint.zero
        drawingLayer.position = CGPoint(x: xLayer, y: yLayer)
        //Change opacity of Rectangle HERE
        drawingLayer.opacity = 1
        pathLayer = drawingLayer
        self.view.layer.addSublayer(pathLayer!)
    }
    
    // MARK: - Vision
    
    /// - Tag: PerformRequests
    fileprivate func performVisionRequest(image: CGImage, orientation: CGImagePropertyOrientation) {
        
        // Fetch desired requests based on switch status.
        let requests = createVisionRequests()
        // Create a request handler.
        let imageRequestHandler = VNImageRequestHandler(cgImage: image,
                                                        orientation: orientation,
                                                        options: [:])
        
        // Send the requests to the request handler.
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequestHandler.perform(requests)
            } catch let error as NSError {
                print("Failed to perform image request: \(error)")
                self.presentAlert("Image Request Failed", error: error)
                return
            }
        }
    }
    
    /// - Tag: CreateRequests
    fileprivate func createVisionRequests() -> [VNRequest] {
        
        // Create an array to collect all desired requests.
        var requests: [VNRequest] = []
        
        
        
        // Create & include a request if and only if switch is ON.
        
            //requests.append(self.rectangleDetectionRequest)
        
        
            requests.append(self.textDetectionRequest)
        
        
        // Return grouped requests as a single array.
        return requests
    }
    

    
    fileprivate func handleDetectedText(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            self.presentAlert("Text Detection Error", error: nsError)
            return
        }
        // Perform drawing on the main thread.
        DispatchQueue.main.async {
            guard let drawLayer = self.pathLayer,
                  let results = request?.results as? [VNTextObservation] else {
                return
            }
            
            //Display Rectangles above the text
            self.draw(text: results, onImageWithBounds: drawLayer.frame)
            
            
            drawLayer.setNeedsDisplay()
        }
    }
    
    
    @available(iOS 13.0, *)
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        
        return path
    }
    
    lazy var textDetectionRequest: VNDetectTextRectanglesRequest = {
        let textDetectRequest = VNDetectTextRectanglesRequest(completionHandler: self.handleDetectedText)
        // Tell Vision to report bounding box around each character.
        textDetectRequest.reportCharacterBoxes = true
        return textDetectRequest
    }()
    
    
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
    
    //Creates white Boxes above the detected Text Fields
    fileprivate func draw(text: [VNTextObservation], onImageWithBounds bounds: CGRect) {
        removeAllButtonsFromView()
        CATransaction.begin()
        
        // Array to hold groups of intersecting text observations
        var textGroups: [[VNTextObservation]] = []
        
        for wordObservation in text {
        var grouped = false
            
            let wordBox = boundingBox(forRegionOfInterest: wordObservation.boundingBox, withinImageBounds: bounds)
            
            // Check if the current word observation intersects with any existing group
            for (index, group) in textGroups.enumerated() {
                for groupObservation in group {
                    let groupBox = boundingBox(forRegionOfInterest: groupObservation.boundingBox, withinImageBounds: bounds)
                    let distanceX = abs(wordBox.midX - groupBox.midX)
                     let distanceY = abs(wordBox.midY - groupBox.midY)
                     let minXDistance = (wordBox.width + groupBox.width) / 2
                     let minYDistance = (wordBox.height + groupBox.height) / 2
                    if wordBox.intersects(groupBox) || distanceX <= CGFloat(slider.value) + minXDistance && distanceY <=  CGFloat(slider.value) + minYDistance {
                        // Add the current observation to the existing group
                        textGroups[index].append(wordObservation)
                        grouped = true
                        break
                    }
                }
                if grouped { break }
            }
            
            // If the current observation does not intersect with any existing group, create a new group
            if !grouped {
                textGroups.append([wordObservation])
            }
        }
        
        
        
        // Create buttons for each group of intersecting text observations
        for group in textGroups {
            let id = Int.random(in: 1..<100000000)
            let fillColor = UIColor.white // You may want to change the fill color as needed
            
            // Calculate the bounding box for the group
            
            for observation in group {
                
                var observationBox = boundingBox(forRegionOfInterest: observation.boundingBox, withinImageBounds: bounds)
                
                observationBox = observationBox.offsetBy(dx: 0, dy: (observationBox.minY - observationBox.maxY))
                let shapeButton = createShapeButton(frame: observationBox, fillColor: fillColor, tag: id)
                view.addSubview(shapeButton)
                
            }
            
            
            
            
            
            
        }
        
        CATransaction.commit()
    }
    
    //Makes the Boxes toggable
    func createShapeButton(frame: CGRect, fillColor: UIColor, tag: Int) -> UIButton {
        
        // Create shape layer
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: frame.width, height: frame.height)).cgPath
        
        shapeLayer.fillColor = fillColor.cgColor
        
        let button = UIButton()
        button.frame = frame
        button.tag = tag
        
        // Add shape layer to button's layer
        button.layer.addSublayer(shapeLayer)
        
        
        // Add action to button
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        
        
        return button
    }
    
    //Is called, when a box is clicked
    @objc func buttonTapped(_ sender: UIButton) {
        
        for layer in sender.layer.sublayers ?? [] {
            guard let shapeLayer = layer as? CAShapeLayer else {
                continue
            }
            if editMode {
                //Wenn der User einen weißen Button anklickt werden alle weißen Buttons mit dem gleichen Tag rot. Wenn der User einen roten Button anklickt wird nur dieser blau. Wenn der User einen blauen Button anklickt wird dieser weiß. Alle roten Buttons bekommen bei Klick auf den Save Button den gleichen Tag, alle blauen bekommen ebenfalls den gleichen Tag, aber einen anderen als die roten und alle weißen Buttons bekommen einen einzigartigen Tag
                if shapeLayer.fillColor == UIColor.white.cgColor {
                    shapeLayer.fillColor = UIColor.red.cgColor
                    
                }
                else if shapeLayer.fillColor == UIColor.blue.cgColor {
                    sender.tag = Int.random(in: 1..<10000000)
                    shapeLayer.fillColor = UIColor.white.cgColor
                }
                
                else {
                    sender.tag = Int.random(in: 1..<10000000)
                    shapeLayer.fillColor = UIColor.blue.cgColor
                }
                
                for view in view.subviews {
                                    if let button = view as? UIButton {
                                        
                                        if sender.tag == button.tag && sender.frame != button.frame {
                                            
                                            for layer2 in button.layer.sublayers ?? [] {
                                                print(sender)
                                                print(button)
                                                print("")
                                                guard let shapeLayer2 = layer2 as? CAShapeLayer else {
                                                    continue
                                                }
                                                if shapeLayer2.fillColor == UIColor.white.cgColor {
                                                    shapeLayer2.fillColor = UIColor.red.cgColor
                                                    
                                                }

                                            }
                                                                                    }
                                    
                                    }
                                }
                
                
            } else {
                
                
                
                for view in view.subviews {
                                    if let button = view as? UIButton {
                                        
                                        
                                        /*let distanceX = abs(sender.frame.midX - button.frame.midX)
                                         let distanceY = abs(sender.frame.midY - button.frame.midY)
                                         let minXDistance = (sender.frame.width + button.frame.width) / 2
                                         let minYDistance = (sender.frame.height + button.frame.height) / 2
                                        
                                        if ((sender.tag == button.tag) || (sender.frame.intersects(button.frame) || distanceX <= CGFloat(slider.value) + minXDistance && distanceY <=  CGFloat(slider.value) + minYDistance)) && sender.frame != button.frame {*/
                                        if sender.tag == button.tag && sender.frame != button.frame {
                                            for layer2 in button.layer.sublayers ?? [] {
                                                guard let shapeLayer2 = layer2 as? CAShapeLayer else {
                                                    continue
                                                }
                                                if shapeLayer2.fillColor == UIColor.clear.cgColor {
                                                    shapeLayer2.fillColor = UIColor.white.cgColor
                                                    
                                                } else {
                                                    shapeLayer2.fillColor = UIColor.clear.cgColor
                                                }

                                            }
                                        }
                                            
                                        //}
                                        
                                    }
                                }
                
                if shapeLayer.fillColor == UIColor.clear.cgColor {
                    shapeLayer.fillColor = UIColor.white.cgColor
                    
                } else {
                    shapeLayer.fillColor = UIColor.clear.cgColor
                }
            }
        }
        // Entferne den Button von der Ansicht und füge ihn wieder hinzu, um die Änderungen anzuzeigen
        sender.removeFromSuperview()
        view.addSubview(sender)
    }

}



extension ViewController: PHPickerViewControllerDelegate {
    /// - Tag: ParsePickerResults
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        
        let existingSelection = self.selection
        var newSelection = [String: PHPickerResult]()
        for result in results {
            let identifier = result.assetIdentifier!
            newSelection[identifier] = existingSelection[identifier] ?? result
        }
        
        // Track the selection in case the user deselects it later.
        selection = newSelection
        selectedAssetIdentifiers = results.map(\.assetIdentifier!)
        selectedAssetIdentifierIterator = selectedAssetIdentifiers.makeIterator()
        
        if selection.isEmpty {
            
            displayEmptyImage()
        } else {
            displayNext()
        }
    }
}

private extension ViewController {
    
    /// - Tag: LoadItemProvider
    func displayNext() {
        guard let assetIdentifier = selectedAssetIdentifierIterator?.next() else { return }
        currentAssetIdentifier = assetIdentifier
        
        let progress: Progress?
        let itemProvider = selection[assetIdentifier]!.itemProvider
        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            progress = itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                DispatchQueue.main.async {
                    self?.handleCompletion(assetIdentifier: assetIdentifier, object: image, error: error)
                }
            }
        } else {
            progress = nil
        }
        
    }
}

private extension ViewController {
    
    func displayEmptyImage() {
        displayImage(UIImage(systemName: "photo.on.rectangle.angled"))
    }
    
    func displayErrorImage() {
        displayImage(UIImage(systemName: "exclamationmark.circle"))
    }
    
    func displayUnknownImage() {
        displayImage(UIImage(systemName: "questionmark.circle"))
    }
    
    func displayImage(_ image: UIImage?) {
        imageView.image = image
    }
        
}


extension ViewController {
    func removeAllButtonsFromView() {
        for subview in view.subviews {
            if let button = subview as? UIButton {
                button.removeFromSuperview()
            }
        }
    }
}
