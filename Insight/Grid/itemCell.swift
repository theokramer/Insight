import UIKit

class itemCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
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
