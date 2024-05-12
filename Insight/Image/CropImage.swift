//
//  CropImage.swift
//  Insight
//
//  Created by Theo Kramer on 12.05.24.
//

import Foundation
import UIKit
import CropViewController

extension ViewController {
    //Show CropViewController, to Crop the Image
    func presentCropViewController(image: UIImage) {
        let cropViewController = CropViewController(croppingStyle: .default, image: image)
        cropViewController.delegate = self
        self.present(cropViewController, animated: true, completion: nil)
    }
    
    //Let the USer crop the selected image and than show it
    func cropViewController(_ cropViewController: CropViewController, didCropImageToRect cropRect: CGRect, angle: Int) {
        
        guard let originalImage = cropImage(image: imageView.image!, rect: cropRect, scale: 1) else {
             return
         }
        
        for i in selectedImages.indices {
            if i == imageIndex {
                selectedImages[i].image = originalImage
                selectedImages[i].cropped = true
            }
        }
        handleCompletion(object: selectedImages[imageIndex].image)
        
        // Dismiss the picker to return to original view controller.
        dismiss(animated: true, completion: nil)
        
    }
    
    //Performs the selected Cropping. TODO: Take care of the angle and orientation of the image
    func cropImage(image: UIImage, rect: CGRect, scale: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: rect.size.width / scale, height: rect.size.height / scale), true, 0.0)
        image.draw(at: CGPoint(x: -rect.origin.x / scale, y: -rect.origin.y / scale))
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return croppedImage
    }
    
}
