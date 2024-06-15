//
//  StudyViewController.swift
//  Insight
//
//  Created by Theo Kramer on 27.05.24.
//

import Foundation
import UIKit

class StudyViewController: ViewController {
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var imageViewStudy: UIImageView!
    
    // Declare buttons and stack view
    let easyButton = UIButton()
    let forgotButton = UIButton()
    let partiallyRecalledButton = UIButton()
    let recalledWithEffortButton = UIButton()
    let buttonsStackView = UIStackView()
    
    @objc override func onOrientationChange() {
        handleCompletion(object: selectedImages[imageIndex].image, thisImageView: imageViewStudy)
    }
    
    override func viewDidLoad() {
        selectedImages.shuffle()
        nextButton.tag = 3
        if imageIndex == selectedImages.count - 1 {
            nextButton.isHidden = true
        } else {
            nextButton.isHidden = false
        }
        
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
            edgePan.edges = .right

        view.addGestureRecognizer(edgePan)
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.onOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        if selectedImages.count != 0 {
            handleCompletion(object: selectedImages[imageIndex].image, thisImageView: imageViewStudy)
        }
        setupButtons()
    }
    
    override func handleNextClick() {
        if imageIndex < selectedImages.count - 1 {
            imageIndex += 1
            handleCompletion(object: selectedImages[imageIndex].image, thisImageView: imageViewStudy)
        }
        if imageIndex == selectedImages.count - 1 {
            nextButton.isHidden = true
        } else {
            nextButton.isHidden = false
        }
        buttonsStackView.isHidden = true
    }
    
    @IBAction func nextClicked(_ sender: Any) {
        nextButton.isHidden = true
        buttonsStackView.isHidden = false
    }
    
    func setupButtons() {
            // Configure buttons
            
        configureButton(button: forgotButton, title: "Again\n <1 min", color: .systemRed, action: #selector(forgotButtonTapped))
        configureButton(button: partiallyRecalledButton, title: "Hard\n4d", color: .systemOrange, action: #selector(partiallyRecalledButtonTapped))
            configureButton(button: recalledWithEffortButton, title: "Good\n10d", color: .systemGreen, action: #selector(recalledWithEffortButtonTapped))
        configureButton(button: easyButton, title: "Easy\n13d", color: .systemBlue, action: #selector(skipButtonTapped))
            
            // Arrange buttons in a stack view
            
            buttonsStackView.addArrangedSubview(forgotButton)
            buttonsStackView.addArrangedSubview(partiallyRecalledButton)
            buttonsStackView.addArrangedSubview(recalledWithEffortButton)
            buttonsStackView.addArrangedSubview(easyButton)
            buttonsStackView.axis = .horizontal
            buttonsStackView.distribution = .fillEqually
            buttonsStackView.spacing = 8
            buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
            buttonsStackView.isHidden = true  // Initially hide the buttons
            
            view.addSubview(buttonsStackView)
            
            // Constraints for stack view
            NSLayoutConstraint.activate([
                buttonsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                buttonsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                buttonsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                buttonsStackView.heightAnchor.constraint(equalToConstant: 60)
            ])
        }
        
        func configureButton(button: UIButton, title: String, color: UIColor, action: Selector) {
            
            button.backgroundColor = color.withAlphaComponent(0.25)
            button.setTitle(title, for: .normal)
            button.setTitleColor(color, for: .normal)
            button.titleLabel?.lineBreakMode = .byWordWrapping
            button.titleLabel?.textAlignment = .center
            button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            
            button.layer.cornerRadius = 8
            button.clipsToBounds = true
            button.addTarget(self, action: action, for: .touchUpInside)
        }
        
        @objc func skipButtonTapped() {
            handleNextClick()
        }
        
        @objc func forgotButtonTapped() {
            handleNextClick()
        }
        
        @objc func partiallyRecalledButtonTapped() {
            handleNextClick()
        }
        
        @objc func recalledWithEffortButtonTapped() {
            handleNextClick()
        }
        
        
}
