//
//  StudyViewController.swift
//  Insight
//
//  Created by Theo Kramer on 27.05.24.
//

import Foundation
import UIKit
import Vision

func findNextImage(cellId: String) -> studyImage? {
    var activeImage: studyImage
    var nextImage = studyImage.init(image: UIImage(), index: "", review: Review.init(index: "", review_date: Date.now, rating: -1, interval: -1, ease_factor: -1, repetitions: -1), boxes: [])
    ViewController.fetchCoreData {items in
        if let items = (items ?? []) as [ImageEntity]? {
            for item in items {
                
                guard let thisImage = UIImage(data: item.imageData ?? Data()) else {
                    return
                }
                guard let myTopic = item.topic else {
                    return
                }
                
                
                if myTopic.id == cellId {
                    
                    
                    
                        if item.review != nil {
                            guard let reviewIndex = item.review?.id, let ratingNum = item.review?.rating, let interval = item.review?.interval, let ease_factor = item.review?.ease_factor, let review_date = item.review?.review_date, let repetitions = item.review?.repetitions else {
                                return
                            }
                            
                            let newReviewDate = review_date.addingTimeInterval((Double(interval) * 60))
                            
                            let currentNextReviewDate =
                             nextImage.review.review_date?.addingTimeInterval((Double(nextImage.review.interval) * 60))
                            
                            
                            
                            if newReviewDate < Date.now {
                                
                                if nextImage.index == "" || nextImage.review.index == "" || newReviewDate < currentNextReviewDate! {
                                    let nextReview = Review.init(index: reviewIndex, review_date: review_date, rating: ratingNum, interval: interval, ease_factor: ease_factor, repetitions: repetitions)
                                    
                                    let boxes = item.boxes?.allObjects as? [ImageBoxes] ?? []
                                    
                                    let boxData = boxes.map { box -> VNTextObservation in
                                        return VNTextObservation(boundingBox: CGRect(x: Double(box.minX), y: Double(box.minY), width: Double(box.width), height: Double(box.height)))
                                    }
                                    
                                    
                                    
                                    nextImage = studyImage.init(image: thisImage, index: item.wrappedId, review: nextReview, boxes: boxData)
                                }
                            }
                        
                            
                        } else {
                            if nextImage.index == "" {
                                let boxes = item.boxes?.allObjects as? [ImageBoxes] ?? []
                                
                                let boxData = boxes.map { box -> VNTextObservation in
                                    return VNTextObservation(boundingBox: CGRect(x: Double(box.minX), y: Double(box.minY), width: Double(box.width), height: Double(box.height)))
                                }

                                
                                
                                nextImage = studyImage.init(image: thisImage, index: item.wrappedId, review: Review.init(index: "", review_date: Date.now, rating: -1, interval: -1, ease_factor: -1, repetitions: -1), boxes: boxData)
                            }
                            
                        }
                        
                        
                    
                    
                    
                }
                
            }
        } else {
            print("FEHLER")
        }
    }
    
    if nextImage.index == "" {
        return nil
    } else {
        activeImage = nextImage
    }
    
    return activeImage
}

class StudyViewController: ViewController {
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var imageViewStudy: UIImageView!
    
    var activeImage: studyImage = studyImage(image: UIImage(), index: "", review: Review.init(index: "", rating: -1, interval: -1, ease_factor: -1, repetitions: -1), boxes: [])
    
    // Declare buttons and stack view
    let easyButton = UIButton()
    let forgotButton = UIButton()
    let partiallyRecalledButton = UIButton()
    let recalledWithEffortButton = UIButton()
    let buttonsStackView = UIStackView()
    
    @objc override func onOrientationChange() {
        handleCompletion(object: activeImage.image, thisImageView: imageViewStudy, customBounds: activeImage.boxes)
    }
    

    
    override func viewDidAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = false
    }
    
    @objc func moreClicked(_ sender: Any) {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let editAction = UIAlertAction(title: "Edit", style: .default) { _ in
                print("Edit tapped")
                // Handle edit action
            }
            
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
                print("Delete tapped")
                // Handle delete action
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alertController.addAction(editAction)
            alertController.addAction(deleteAction)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
        }
    
    override func viewDidLoad() {
        nextButton.tag = 3
        
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.topItem?.title = ""
        
        let customButtonWithImage = UIButton(type: .system) // declare your button
        
        let image = UIImage(systemName: "ellipsis")?.withRenderingMode(.alwaysTemplate)
            
        customButtonWithImage.setImage(image, for: .normal)
        customButtonWithImage.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        customButtonWithImage.setTitleColor(.white, for: .normal) // set text color
        customButtonWithImage.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2.0)
        customButtonWithImage.addTarget(self, action: #selector(moreClicked(_:)), for: .touchUpInside)
        
        let customNavBarButton = UIBarButtonItem(customView: customButtonWithImage)
        
        navigationItem.rightBarButtonItems = [
            customNavBarButton
            ]
        

        
        activeImage = findNextImage(cellId: cellId) ?? studyImage(image: UIImage(), index: "", review: Review.init(index: "", rating: -1, interval: -1, ease_factor: -1, repetitions: -1), boxes: [])
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.onOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        handleCompletion(object: activeImage.image, thisImageView: imageViewStudy, customBounds: activeImage.boxes)
        setupButtons()
    }

    
    override func handleNextClick() {
        activeImage = findNextImage(cellId: cellId) ?? studyImage(image: UIImage(), index: "", review: Review.init(index: "", rating: -1, interval: -1, ease_factor: -1, repetitions: -1), boxes: [])
        if (activeImage.index == "") {
            showCompletionAlert()
        } else {
            handleCompletion(object: activeImage.image, thisImageView: imageViewStudy, customBounds: activeImage.boxes)
            buttonsStackView.isHidden = true
            nextButton.isHidden = false
        }
        
    }
    

    

    
    
    func goBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    func showCompletionAlert() {
            let alert = UIAlertController(title: "Charts Fertig", message: "Jetzt sind alle Charts fertig.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: goBack(_:)))
            present(alert, animated: true, completion: nil)
        }
    
    @IBAction func nextClicked(_ sender: Any) {
        nextButton.isHidden = true
        buttonsStackView.isHidden = false
    }
    
    func setupButtons() {
            // Configure buttons
            
        configureButton(button: forgotButton, title: "Forgot\n <1 min", color: .systemRed, action: #selector(feedbackButtonClicked(_:)), tag: 0)
        configureButton(button: partiallyRecalledButton, title: "Hard\n4d", color: .systemOrange, action: #selector(feedbackButtonClicked(_:)), tag: 1)
        configureButton(button: recalledWithEffortButton, title: "Good\n10d", color: .systemGreen, action: #selector(feedbackButtonClicked(_:)), tag: 2)
        configureButton(button: easyButton, title: "Easy\n13d", color: .systemBlue, action: #selector(feedbackButtonClicked(_:)), tag: 3)
            
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
        
    func configureButton(button: UIButton, title: String, color: UIColor, action: Selector, tag: Int) {
            
            button.backgroundColor = color.withAlphaComponent(0.25)
            button.setTitle(title, for: .normal)
            button.tag = tag
            button.setTitleColor(color, for: .normal)
            button.titleLabel?.lineBreakMode = .byWordWrapping
            button.titleLabel?.textAlignment = .center
            button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            
            button.layer.cornerRadius = 8
            button.clipsToBounds = true
            button.addTarget(self, action: action, for: .touchUpInside)
        }
    
    func calculate_next_interval(rating: Int, current_interval: Int, current_ease_factor: Float, reps: Int) -> Int{
        var new_interval = 0
        
        if rating < 1 {
            new_interval = current_interval
        }
            
        else {
            if reps <= 1 {
                new_interval = 24 * 60 * 6
            } else {
                new_interval = current_interval * Int(current_ease_factor)
            }
            
        }

        return new_interval
    }
    
    func calculate_new_ease_factor(current_ease_factor: Float, rating: Int) -> Float {
        let inverseRating = Float(3 - rating)
        let temp = (0.08 + inverseRating * 0.02)
        var new_ease_factor = current_ease_factor + (0.1 - (inverseRating * temp))
        if new_ease_factor < 1.3 {
            new_ease_factor = 1.3
        }
        return new_ease_factor
    }
    
    
    func calcReps(rating: Int, repetitions: Int) -> Int16 {
        var new_reps = repetitions
        if rating < 1 {
            new_reps = 0
        } else {
            new_reps = repetitions + 1
        }
        return Int16(new_reps)
    }
    
    
    func generateHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
        
    @IBAction func feedbackButtonClicked(_ sender: UIButton) {
        
        generateHapticFeedback()
            
        ViewController.fetchCoreData {items in
            if let items = (items ?? []) as [ImageEntity]? {
                for item in items {
                    
                    guard let myTopic = item.topic else {
                        return
                    }
                    
                    var saveReview: Review
                    
                    
                    if myTopic.id == self.cellId && item.wrappedId == self.activeImage.index {
                        
                        
                        if item.review != nil && item.review?.repetitions != 0 {
                                
                                
                                guard let reviewIndex = item.review?.id, let ratingNum = item.review?.rating, let interval = item.review?.interval, let ease_factor = item.review?.ease_factor, let review_date = item.review?.review_date, let repetitions = item.review?.repetitions else {
                                    return
                                }
                                print("Previous Review:")
                                print(reviewIndex)
                                print(ratingNum)
                                print(interval)
                                print(ease_factor)
                                print(review_date)
                            
                                let newInterval = Int64(self.calculate_next_interval(rating: sender.tag, current_interval: Int(interval), current_ease_factor: ease_factor, reps: Int(repetitions)))
                                let new_ease_factor = self.calculate_new_ease_factor(current_ease_factor: ease_factor, rating: sender.tag)
                                
                                let new_repetitions = self.calcReps(rating: sender.tag, repetitions: Int(repetitions))
                                
                                
                                saveReview = Review.init(index: reviewIndex, review_date: Date.now, rating: Int16(sender.tag), interval: newInterval, ease_factor: new_ease_factor, repetitions: new_repetitions)
                                
                            } else {
                                let newInterval: Int64
                                switch(sender.tag) {
                                    case 0:
                                        newInterval =  1
                                    case 1:
                                        newInterval = 60 * 12
                                    case 2:
                                        newInterval = 60 * 24
                                    case 3:
                                        newInterval = 60 * 24 * 4
                                    default:
                                        newInterval = 1
                                }
                                
                                saveReview = Review.init(index: UUID().uuidString, review_date: Date.now, rating: Int16(sender.tag), interval: newInterval, ease_factor: 2.5, repetitions: 1)
                            }
                            
                        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                        let imageReview = ImageReview(context: context)
                        imageReview.id = saveReview.index
                        imageReview.interval = saveReview.interval
                        imageReview.rating = saveReview.rating
                        imageReview.ease_factor = saveReview.ease_factor
                        imageReview.review_date = saveReview.review_date
                        
                        item.review = imageReview
                        
                        DispatchQueue.main.async {
                            do {
                                try context.save()
                            } catch {
                                print("error-saving data")
                            }
                        }
                        
                        }
                        
                        
                    
                    
                }
            } else {
                print("FEHLER")
            }
        }
                
            handleNextClick()
        }
        
        
}
