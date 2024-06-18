import UIKit

class itemCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    var mySelImage = selectedImage(image: UIImage(), index: "", cropped: false, boxes: [])
    
    @IBOutlet weak var cellMoreButton: UIButton!
    func setImage(image: UIImage) {
        // Set the content mode to scaleAspectFit
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.image = image
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupImageViewConstraints()
        
    }
    @IBAction func cellMoreClicked(_ sender: Any) {
        print(mySelImage.index)
    }
    
    private func setupImageViewConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    
    

}




