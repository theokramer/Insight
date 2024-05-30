//
//  itemCell.swift
//  Insight
//
//  Created by Theo Kramer on 16.05.24.
//

import UIKit


//Displays a Image inside the Cell
class itemCell: UICollectionViewCell {
    


    @IBOutlet weak var imageView: UIImageView!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    

    
    func setImage(image: UIImage) {
        // Calculate the aspect ratio of the image
        let aspectRatio = image.size.width / image.size.height
        // Set the image in the UIImageView
        imageView.image = image
        
        // Calculate the target width based on the cell width
        let targetWidth = min(bounds.width, image.size.width)
        
        // Calculate the target height based on the aspect ratio and the target width
        let targetHeight = targetWidth / aspectRatio
        
        // Adjust the frame of the UIImageView to fit the scaled image
        imageView.frame.size = CGSize(width: targetWidth, height: targetHeight)
        
        // Calculate the origin coordinates to center the image horizontally within the UIImageView
        let originX = (bounds.width - imageView.frame.width) / 2
        
        // Keep the original Y origin calculation
        let originY = (bounds.height - imageView.frame.height) / 2
        
        imageView.frame.origin = CGPoint(x: originX, y: originY)
        
        // Set content mode to scaleAspectFit
        imageView.contentMode = .scaleAspectFit
    }



}
