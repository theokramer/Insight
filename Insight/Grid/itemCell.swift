//
//  itemCell.swift
//  Insight
//
//  Created by Theo Kramer on 16.05.24.
//

import UIKit

class itemCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setImage(image: UIImage) {
        imageView.image = image
    }

}
