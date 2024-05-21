//
//  PhotoPicker.swift
//  Insight
//
//  Created by Theo Kramer on 11.05.24.
//

import Foundation
import PhotosUI
import UIKit

extension ViewController: PHPickerViewControllerDelegate {
    
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
    
    /// - Tag: ParsePickerResults
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { [weak self] (object, error) in
                            if let image = object as? UIImage {
                                DispatchQueue.main.async { [weak self] in
                                    self?.selectedImages.append(selectedImage.init(image: image, index: UUID().uuidString, cropped: false))
                                }
                            }
                        })
        }
        
        if selectedImages.isEmpty {
            displayEmptyImage()
        } else {
            self.handleCompletion(object: selectedImages[imageIndex])
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
