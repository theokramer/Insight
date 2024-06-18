//
//  OverviewController.swift
//  Insight
//
//  Created by Theo Kramer on 13.05.24.
//

import Foundation
import UIKit
import CoreData
import SwiftUI
import Vision

//Object to add and modify new Images
struct selectedImage {
    var image: UIImage
    var index: String
    var cropped: Bool
    var boxes: [VNTextObservation]
}

struct studyImage {
    var image: UIImage
    var index: String
    var review: Review
    var boxes: [VNTextObservation]
}

struct Review {
    var index: String
    var review_date: Date?
    var rating: Int16
    var interval: Int64
    var ease_factor: Float
    var repetitions: Int16
}

//Array of selected Images in Photo Picker
var selectedImages: [selectedImage] = []

@available(iOS 13.0, *)
class OverviewController: UIViewController, UICollectionViewDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @IBOutlet weak var studyChartsButton: UIButton!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var addChartsButton: UIButton!
    @IBOutlet weak var tempStatusLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tempDescrLabel: UILabel!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    
    @IBAction func moreButtonClicked(_ sender: Any) {
        editAll()
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var cardInDeck: UILabel!
    @FetchRequest(sortDescriptors: []) var topics:FetchedResults<Topic>
    
    //Clicked Cell with Topic ID
    var cellId: String = ""
    
    var timer = Timer()
    
    //Array with Images -> Gets fetched of Core Data
    var dataSource:[selectedImage] = []
    
    //Configure Image Cell
    var estimateWidth = 300
    var cellMarginSize = UIScreen.main.bounds.width > 500 ? 50 : 30
    
    
    @IBAction func studyChartsClicked(_ sender: Any) {
        performSegue(withIdentifier: "studyChartsClicked", sender: cellId)
    }
    
    
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Topic> {
        return NSFetchRequest<Topic>(entityName: "Topic")
    }
    
    @objc func editAll() {
        performSegue(withIdentifier: "showViewController", sender: cellId)
    }
    
    var timeUntilNewCharts = -1
    
    func learnableImagesCount() -> Int {
        dataSource.removeAll()
        selectedImages.removeAll()
        
        var learnableImages:[studyImage] = []
        
        ViewController.fetchCoreData {items in
            if let items = (items ?? []) as [ImageEntity]? {
                for item in items {
                    
                    guard let thisImage = UIImage(data: item.imageData ?? Data()) else {
                        return
                    }
                    guard let myTopic = item.topic else {
                        return
                    }
                    
                    
                    if myTopic.id == self.cellId {
                        
                        if myTopic.name == "" {
                            self.textField.placeholder = "Ohne Titel"
                            self.textField.text = ""
                        } else {
                            self.textField.text = myTopic.wrappedName
                        }
                        
                        let imageStruct = selectedImage.init(image: thisImage, index: item.wrappedId, cropped: false, boxes: [])
                        self.dataSource.append(imageStruct)
                        selectedImages.append(imageStruct)

                        
                        if self.cellId == "" {
                            self.textField.text = ""
                        } else {
                            self.textField.text = myTopic.wrappedName
                        }
                        
                            if item.review != nil {
                                guard let reviewIndex = item.review?.id, let ratingNum = item.review?.rating, let interval = item.review?.interval, let ease_factor = item.review?.ease_factor, let review_date = item.review?.review_date, let repetitions = item.review?.repetitions else {
                                    return
                                }
                                
                                let newReviewDate = review_date.addingTimeInterval((Double(interval) * 60))
                                
                               
                                
                                if newReviewDate < Date.now {
                                    let myStudyImage = studyImage.init(image: thisImage, index: item.wrappedId, review: Review.init(index: "", review_date: Date.now, rating: -1, interval: -1, ease_factor: -1, repetitions: -1), boxes: [])
                                    learnableImages.append(myStudyImage)
                                } else {
                                    if Int(newReviewDate.timeIntervalSince(Date.now)) < self.timeUntilNewCharts || self.timeUntilNewCharts == -1 {
                                        self.timeUntilNewCharts = Int(newReviewDate.timeIntervalSince(Date.now))
                                    }
                                }
                            
                                
                            } else {
                                let myStudyImage = studyImage.init(image: thisImage, index: item.wrappedId, review: Review.init(index: "", review_date: Date.now, rating: -1, interval: -1, ease_factor: -1, repetitions: -1), boxes: [])
                                learnableImages.append(myStudyImage)
                            }
                            
                            
                        
                        
                        
                    }
                    
                }
            } else {
                print("FEHLER")
            }
        }
        
        
        if textField.text == "" {
                   textField.becomeFirstResponder()
               } else {
                   textField.resignFirstResponder()
               }
        
        return learnableImages.count
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        timer.invalidate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        topView.layer.cornerRadius = 15
        
        
        imageIndex = 0
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .ultraLight, scale: .large)
        
        var configuration = UIButton.Configuration.filled()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        configuration.cornerStyle = .capsule
        moreButton.configuration = configuration
        let moreImage = UIImage(systemName: "ellipsis", withConfiguration: config)?.withTintColor(.darkGray, renderingMode: .alwaysOriginal)
        moreButton.setImage(moreImage, for: .normal)
        moreButton.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2.0)
        

        
        // Layout für den Button festlegen
        NSLayoutConstraint.activate([
            collectionView.heightAnchor.constraint(equalToConstant: view.bounds.height - 480),
        ])
        
        self.navigationController?.navigationBar.isHidden = true
        
        hideKeyboardWhenTappedAround()
        
        if(UIScreen.main.bounds.width > 700) {
            estimateWidth = Int(UIScreen.main.bounds.width / 4.5)
        } 
        else if(UIScreen.main.bounds.width > 400) {
            estimateWidth = Int(UIScreen.main.bounds.width / 3.5)
        } else {
            estimateWidth = Int(UIScreen.main.bounds.width / 2.5)
        }
        studyChartsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        studyChartsButton.isEnabled = learnableImagesCount() > 0 ? true : false
        studyChartsButton.layer.shadowColor = UIColor.black.cgColor
        studyChartsButton.layer.shadowOpacity = 0.2
        studyChartsButton.layer.shadowOffset = .zero
        studyChartsButton.layer.shadowRadius = 10
        
        addChartsButton.layer.shadowColor = UIColor.black.cgColor
        addChartsButton.layer.shadowOpacity = 0.2
        addChartsButton.layer.shadowOffset = .zero
        addChartsButton.layer.shadowRadius = 10
        
        //studyChartsButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: (UIScreen.main.bounds.width / 2) - (studyChartsButton.frame.width / 2), bottom: 0, trailing: 0)
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        self.textField.delegate = self
        textField.returnKeyType = UIReturnKeyType.done
        textField.borderStyle = .none
        
        self.updateText()

        
        if self.collectionView.dataSource != nil {
            self.collectionView.reloadData()
        } else {
            //Configure Image List
            self.collectionView.delegate = self
            self.collectionView.dataSource = self
            self.collectionView.register(UINib(nibName: "itemCell", bundle: nil), forCellWithReuseIdentifier: "itemCell")
            self.collectionView.allowsSelection = true
            
            self.setUpGridView()
        }
        self.collectionView.reloadData()
        
        
        cardInDeck.text = "Total Charts (\(selectedImages.count))"
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.updateText()
            })
    }
    
    
    func updateText() {
        if learnableImagesCount() == 0 {
            tempStatusLabel.text = "\(formatDuration(seconds: timeUntilNewCharts))"
            tempStatusLabel.font = .boldSystemFont(ofSize: 30)
            tempDescrLabel.text = "until next Chart"
        } else {
            tempStatusLabel.text = "\(learnableImagesCount())"
            tempStatusLabel.font = .boldSystemFont(ofSize: 60)
            tempDescrLabel.text = "Charts left"
            studyChartsButton.isEnabled = true
        }
    }
    
    func formatDuration(seconds: Int) -> String {
        let weeks = seconds / 604800 // 7 * 24 * 3600
        let days = (seconds % 604800) / 86400 // 24 * 3600
        let hours = (seconds % 86400) / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        
        var parts: [String] = []
        if weeks > 0 {
            parts.append("\(weeks)w")
        }
        if days > 0 {
            parts.append("\(days)d" )
        }
        if hours > 0 {
            parts.append("\(hours)h")
        }
        if minutes > 0 {
            parts.append("\(minutes)m" )
        }
        if remainingSeconds > 0 {
            parts.append("\(remainingSeconds)s")
        }
        
        return parts.joined(separator: " : ")
    }




    
    override func viewDidLoad() {
            super.viewDidLoad()
            imageIndex = 0
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.register(UINib(nibName: "itemCell", bundle: nil), forCellWithReuseIdentifier: "itemCell")
            setUpGridView()
            print(learnableImagesCount())
            print(timeUntilNewCharts)
            
        }
    
    
    //Make the Image List adaptable
        func setUpGridView() {
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.minimumInteritemSpacing = CGFloat(self.cellMarginSize)
            flowLayout.minimumLineSpacing = CGFloat(self.cellMarginSize)
            flowLayout.sectionInset = UIEdgeInsets(top: 0, left: CGFloat(self.cellMarginSize), bottom: 0, right: CGFloat(self.cellMarginSize))
            collectionView.collectionViewLayout = flowLayout
        }
    
    @IBAction func studyClicked(_ sender: Any) {
        saveText()
    }
    
    
    
    //Is called when the User clicks the add Button -> Shows AddImage Page
    @IBAction func addChartsClicked(_ sender: Any) {
        saveText()
        promptPhoto()
    }
    
    @objc func saveText() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        do {
            guard let items = try context.fetch(Topic.fetchRequest()) as? [Topic] else {
                return
            }
            for myTopic in items {
                if myTopic.id == cellId {
                    myTopic.setValue(textField.text, forKey: "name")
                }
                
            }
        } catch {
            print("error-Fetching data")
        }
        
       DispatchQueue.main.async {
           do {
               try context.save()
           } catch {
               print("error-saving data")
           }
       }
        if textField.text == "" {
            textField.placeholder = "Ohne Titel"
        }
    }
    
    func hideKeyboardWhenTappedAround() {
           let tapGesture = UITapGestureRecognizer(target: self,
                            action: #selector(textFieldShouldReturn))
           view.addGestureRecognizer(tapGesture)
    }
    
    @objc func someViewInMyCellTapped(_ sender: UIGestureRecognizer) {
        
    }
    
    //Dismisses Keyboard when Done button is clicked
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        saveText()
        return false
    }
    
    //Transfers the Topic ID to the next Page
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       if (segue.identifier == "showViewController") {
          let secondView = segue.destination as! ViewController
          let object = sender as! String
           secondView.cellId = object
           secondView.singleMode = false
       }
        if (segue.identifier == "studyChartsClicked") {
           let secondView = segue.destination as! StudyViewController
           let object = sender as! String
            secondView.cellId = object
            secondView.singleMode = false
            
        }
    }
}



//Configures the UI List
extension OverviewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "itemCell", for: indexPath) as! itemCell
            let thisImage = self.dataSource[indexPath.row].image
            cell.setImage(image: thisImage)
            cell.layer.cornerRadius = 15
            cell.mySelImage = self.dataSource[indexPath.row]
        
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.someViewInMyCellTapped(_:)))
            cell.addGestureRecognizer(tap)
            tap.cancelsTouchesInView = false
            return cell
        }
    
    func collectionView(_ collectionView: UICollectionView,
             didSelectItemAt indexPath: IndexPath) {
        let selectedData = dataSource[indexPath.row]
                showBottomSheet(with: selectedData)
    }
    
    func showBottomSheet(with data: selectedImage) {
            let bottomSheetVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BottomSheetViewController") as! BottomSheetViewController
            bottomSheetVC.configure(with: data)
            bottomSheetVC.info = data
            bottomSheetVC.cellID = cellId
            bottomSheetVC.indizes = [0,1,2,3,4]
            minusHeight = 0
            bottomSheetVC.modalPresentationStyle = .custom
            bottomSheetVC.transitioningDelegate = bottomSheetVC.presentationManager
            present(bottomSheetVC, animated: true, completion: nil)
            
        }
    
    // Funktion, um die Größe eines UIImage zu ändern
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let newImage = renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return newImage
    }
    
}

extension OverviewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return calculateCellSize()
    }

    func calculateWidth() -> CGFloat {
        let estimateWidth = CGFloat(self.estimateWidth)
        let cellCount = floor(CGFloat(self.view.frame.size.width / estimateWidth))
        let margin = CGFloat(cellMarginSize * 2)
        let width = (CGFloat(self.view.frame.size.width) - CGFloat(cellMarginSize) * (cellCount - 1) - margin) / cellCount
        return width
    }
    
    func calculateCellSize() -> CGSize {
        let width = self.calculateWidth()
        return CGSize(width: width, height: width)
    }
}

public extension UIView {
    
    func roundCornerWithShadow(cornerRadius: CGFloat, shadowRadius: CGFloat, offsetX: CGFloat, offsetY: CGFloat, colour: UIColor, opacity: Float) {
        
        self.clipsToBounds = false

        let layer = self.layer
        layer.masksToBounds = false
        layer.cornerRadius = cornerRadius
        layer.shadowOffset = CGSize(width: offsetX, height: offsetY);
        layer.shadowColor = colour.cgColor
        layer.shadowRadius = shadowRadius
        layer.shadowOpacity = opacity
        layer.shadowPath = UIBezierPath(roundedRect: layer.bounds, cornerRadius: layer.cornerRadius).cgPath
        
        let bColour = self.backgroundColor
        self.backgroundColor = nil
        layer.backgroundColor = bColour?.cgColor
        
    }
    
}

class BottomSheetViewController: UIViewController {
    let presentationManager = HalfScreenPresentationManager()
    private var dimmingView: UIView?
    var info: selectedImage = selectedImage(image: UIImage(), index: "", cropped: false, boxes: [])
    var cellID: String = ""
    var indizes:[Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        setupGestureRecognizers()
        setupButtons()
    }

    func configure(with data: selectedImage) {
        // Update UI elements with data from selectedImage
    }

    private func setupGestureRecognizers() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGesture)
    }

    private func setupButtons() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        
        let buttonTitles = ["Select", "Edit", "Freeze", "Move", "Delete"]
        let buttonIcons = ["checkmark.circle", "pencil", "pause.circle", "arrow.right.circle", "trash"]
        
        for (index, title) in buttonTitles.enumerated() {
            if indizes.contains(index) {
                let button = createButton(title: title, icon: buttonIcons[index], index: index)
                button.tag = index
                button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
                stackView.addArrangedSubview(button)
            }
            
        }

        view.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func createButton(title: String, icon: String, index: Int) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 22, leading: 22, bottom: 22, trailing: 22)
        configuration.imagePadding = 15
        let button = UIButton(type: .system)
        button.configuration? = configuration
        button.setTitle(title, for: .normal)
        button.setTitleColor(index == 4 ? .red : .black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        
        let image = UIImage(systemName: icon)
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = index == 4 ? .red : .black
        button.contentHorizontalAlignment = .left
        
        
        button.configuration = configuration
        button.backgroundColor = .lightGray.withAlphaComponent(0.2)
        button.layer.cornerRadius = 10
        
        
        return button
    }

    @objc private func buttonTapped(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            print("Select tapped")
            // Handle Select action
        case 1:
            print("Edit tapped")
            if let editViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as? ViewController {
                editViewController.singleImage = info
                editViewController.cellId = cellID
                editViewController.singleMode = true
                let navigationController = UINavigationController(rootViewController: editViewController)
                navigationController.modalPresentationStyle = .overFullScreen
                present(navigationController, animated: true, completion: nil)
            }
            
        case 2:
            print("Freeze tapped")
            // Handle Freeze action
        case 3:
            print("Move tapped")
            // Handle Move action
        case 4:
            print("Delete tapped")
            dismissViewController()
        default:
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       if (segue.identifier == "showViewController2") {
          let secondView = segue.destination as! ViewController
          let object = sender as! selectedImage
           secondView.cellId = ""
           secondView.singleImage = object
       }
        
    }
    
    @IBAction func dismissViewController() {
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            
            //Removes all Images in Core Data that got cropped, so it gets updated.
            //TODO: Instead change the UIImage when cropped?
            ViewController.fetchCoreData {items in
                if let items = (items ?? []) as [ImageEntity]? {
                    for item in items {
                        if self.info.index == item.id {

                                context.delete(item)
                                do {
                                    try context.save()
                                    self.dismiss(animated: true, completion: nil)
                                    
                                    print("Success")
                                } catch {
                                    print("error-Deleting data")
                                }
                                
                            
                        }
                    }
                } else {
                    print("FEHLER")
                }
            }
        
        
        
    }
    
    

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .changed:
            if translation.y > 0 {
                view.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended:
            if translation.y > 100 || velocity.y > 500 {
                dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.view.transform = .identity
                }
            }
        default:
            break
        }
    }
}


class HalfScreenPresentationManager: NSObject, UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return HalfScreenPresentationController(presentedViewController: presented, presenting: presenting)
    }


    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        guard let toView = transitionContext.view(forKey: .to) else { return }

        containerView.addSubview(toView)
        toView.frame = containerView.bounds.offsetBy(dx: 0, dy: containerView.bounds.height)

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            toView.frame = containerView.bounds
        }, completion: { finished in
            transitionContext.completeTransition(finished)
        })
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
}

var minusHeight = 0.0

class HalfScreenPresentationController: UIPresentationController {
    private let dimmingView = UIView()
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        let height = containerView.bounds.height / 2 - containerView.bounds.height * 0.1 * minusHeight
        return CGRect(x: 0, y: containerView.bounds.height - height, width: containerView.bounds.width, height: height)
    }

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        dimmingView.frame = containerView.bounds
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmingView.alpha = 0
        containerView.addSubview(dimmingView)

        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1
        }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
        }, completion: { _ in
            self.dimmingView.removeFromSuperview()
        })
    }
}
