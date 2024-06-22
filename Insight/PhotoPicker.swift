//
//  PhotoPicker.swift
//  Insight
//
//  Created by Theo Kramer on 11.05.24.
//

import Foundation
import PhotosUI
import UIKit

extension OverviewController: PHPickerViewControllerDelegate {
    
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
                imagePicker.allowsEditing = true
                imagePicker.delegate = self
                self.present(imagePicker, animated: true)
                
            }
            
            let cameraAction = UIAlertAction(title: "Camera",
                                             style: .default,
                                             handler: presentCamera)
            
            func presentLibrary(_ _: UIAlertAction) {
                presentPicker(filter: nil)
            }
            
            func presentFilePicker(_ _: UIAlertAction) {
                presentPicker(filter: nil)
            }
            
            let libraryAction = UIAlertAction(title: "Photo Library",
                                              style: .default,
                                              handler: presentLibrary)
            
            let fileAction = UIAlertAction(title: "Files",
                                           style: .default,
                                           handler: presentFilePicker)
            
            let cancelAction = UIAlertAction(title: "Cancel",
                                             style: .cancel,
                                             handler: nil)
            
           
            
            // Implementierung der anderen Aktionen ...
            
            // Angabe der Ortungsinformationen für den Popover
            if let popoverController = prompt.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.width * 0.83, y: self.view.bounds.height * 0.83, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            // Hinzufügen der Aktionen zum Alert Controller
            prompt.addAction(cameraAction)
            prompt.addAction(libraryAction)
            prompt.addAction(fileAction)
            prompt.addAction(cancelAction)
            // Weitere Aktionen hinzufügen...
            
            // Präsentieren des Alert Controllers
            self.present(prompt, animated: true, completion: nil)
        }
    
    
    func presentPicker(filter: PHPickerFilter?) {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        
        // Set the filter type according to the user’s selection.
        configuration.filter = filter
        // Set the mode to avoid transcoding, if possible, if your app supports arbitrary image/video encodings.
        configuration.preferredAssetRepresentationMode = .current
        // Set the selection behavior to respect the user’s selection order.
        configuration.selection = .ordered
        // Set the selection limit to enable multiselection.
        configuration.selectionLimit = 0
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        editImages.append(selectedImage.init(image: image, index: UUID().uuidString, cropped: false, boxes: []))
        performSegue(withIdentifier: "showViewController", sender: true)
    }
    
    /// - Tag: ParsePickerResults
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { [] (object, error) in
                            if let image = object as? UIImage {
                                self.handleCompletion(object: image)
                            }
                            
                        })
            
        }
        
        self.performSegue(withIdentifier: "showViewController", sender: true)
        
    }
    
    func handleCompletion(object: Any?) {
        
        if let image = object as? UIImage {
            //TODO: Not the best Approach. Display after view is loaded!
            DispatchQueue.main.async {
                let cgOrientation = CGImagePropertyOrientation(image.imageOrientation)
                
                // Fire off request based on URL of chosen photo.
                
                //Calls the vision request
                
                self.performVisionRequest(image: image, orientation: cgOrientation)
            }
            
        }
    }

    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dismiss picker, returning to original root viewController.
        dismiss(animated: true, completion: nil)
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
