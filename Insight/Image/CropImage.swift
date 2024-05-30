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
    func presentCropViewControllerSquare(image: UIImage) {
        let cropViewController = CropViewController(croppingStyle: .default, image: image, aspectRatio: .presetSquare)
        cropViewController.delegate = self
        self.present(cropViewController, animated: true, completion: nil)
    }
    
    //Let the USer crop the selected image and than show it
    func cropViewController(_ cropViewController: CropViewController, didCropImageToRect cropRect: CGRect, angle: Int) {
        
        
        
        guard let originalImage = cropImage(image: imageView.image!, rect: cropRect, scale: 1) else {
             return
         }
        
        
        let CGImage = originalImage.cgImage
        var portraitImage: UIImage = originalImage
        if angle == 90 {
            portraitImage = UIImage(cgImage: CGImage!, scale: originalImage.scale, orientation: .right)
        }
        
        if angle == 180 {
            portraitImage = UIImage(cgImage: CGImage!, scale: originalImage.scale, orientation: .down)
        }
        
        if angle == -90 {
            portraitImage = UIImage(cgImage: CGImage!, scale: originalImage.scale, orientation: .left)
        }
        
        
        
        for i in selectedImages.indices {
            if i == imageIndex {
                selectedImages[i].image = portraitImage
                selectedImages[i].cropped = true
            }
        }
        handleCompletion(object: selectedImages[imageIndex].image, thisImageView: imageView)
        
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
