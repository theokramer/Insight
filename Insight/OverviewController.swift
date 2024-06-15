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

//Object to add and modify new Images
struct selectedImage {
    var image: UIImage
    var index: String
    var cropped: Bool
}

struct studyImage {
    var image: UIImage
    var index: String
    var review: Review
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
    @FetchRequest(sortDescriptors: []) var topics:FetchedResults<Topic>
    
    //Clicked Cell with Topic ID
    var cellId: String = ""
    
    //Array with Images -> Gets fetched of Core Data
    var dataSource:[selectedImage] = []
    
    //Configure Image Cell
    var estimateWidth = 300
    var cellMarginSize = UIScreen.main.bounds.width > 500 ? 50 : 30
    
    
    @IBAction func studyChartsClicked(_ sender: Any) {
        performSegue(withIdentifier: "studyChartsClicked", sender: cellId)
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Topic> {
        return NSFetchRequest<Topic>(entityName: "Topic")
    }
    
    @objc func editAll() {
        performSegue(withIdentifier: "showViewController", sender: cellId)
    }
    
    var timeUntilNewCharts = -1
    
    func learnableImagesCount() -> Int {
        
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
                        
                            if item.review != nil {
                                guard let reviewIndex = item.review?.id, let ratingNum = item.review?.rating, let interval = item.review?.interval, let ease_factor = item.review?.ease_factor, let review_date = item.review?.review_date, let repetitions = item.review?.repetitions else {
                                    return
                                }
                                
                                let newReviewDate = review_date.addingTimeInterval((Double(interval) * 60))
                                
                               
                                
                                if newReviewDate < Date.now {
                                    let myStudyImage = studyImage.init(image: thisImage, index: item.wrappedId, review: Review.init(index: "", review_date: Date.now, rating: -1, interval: -1, ease_factor: -1, repetitions: -1))
                                    learnableImages.append(myStudyImage)
                                } else {
                                    if Int(newReviewDate.timeIntervalSince(Date.now)) < self.timeUntilNewCharts || self.timeUntilNewCharts == -1 {
                                        self.timeUntilNewCharts = Int(newReviewDate.timeIntervalSince(Date.now))
                                    }
                                }
                            
                                
                            } else {
                                let myStudyImage = studyImage.init(image: thisImage, index: item.wrappedId, review: Review.init(index: "", review_date: Date.now, rating: -1, interval: -1, ease_factor: -1, repetitions: -1))
                                learnableImages.append(myStudyImage)
                            }
                            
                            
                        
                        
                        
                    }
                    
                }
            } else {
                print("FEHLER")
            }
        }
        
        return learnableImages.count
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        imageIndex = 0
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)), for: .normal) // Image can be downloaded from here below link
        button.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2.0)
        button.setTitleColor(.white, for: .normal) // You can change the TitleColor
        button.addTarget(self, action: #selector(editAll), for: .touchUpInside)

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        
        

        
        // Layout für den Button festlegen
        NSLayoutConstraint.activate([
            collectionView.heightAnchor.constraint(equalToConstant: view.bounds.height - 400),
        ])
        
        self.navigationController?.navigationBar.tintColor = .black
        
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
        //studyChartsButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: (UIScreen.main.bounds.width / 2) - (studyChartsButton.frame.width / 2), bottom: 0, trailing: 0)
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        self.textField.delegate = self
        textField.returnKeyType = UIReturnKeyType.done
        textField.borderStyle = .none

        //Load Topic Data from Core Data and apply it to textField
        do {
            guard let items = try context.fetch(Topic.fetchRequest()) as? [Topic] else {
                return
            }
            for myTopic in items {
                if myTopic.id == self.cellId {
                    if myTopic.name == "" {
                        self.textField.placeholder = "Ohne Titel"
                        self.textField.text = ""
                    } else {
                        self.textField.text = myTopic.wrappedName
                    }
                }
                
            }
        } catch {
            print("Fehler")
        }
        
        if textField.text == "" {
                   textField.becomeFirstResponder()
               } else {
                   textField.resignFirstResponder()
               }
        dataSource.removeAll()
        selectedImages.removeAll()
        //Add all Images to the Data Array with previously selected Topic ID
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
                        if self.cellId == "" {
                            self.textField.text = ""
                        } else {
                            self.textField.text = myTopic.wrappedName
                        }
                        let imageStruct = selectedImage.init(image: thisImage, index: item.wrappedId, cropped: false)
                        self.dataSource.append(imageStruct)
                        selectedImages.append(imageStruct)
                    }
                    
                }
            } else {
                print("FEHLER")
            }
        }
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
       }
        if (segue.identifier == "studyChartsClicked") {
           let secondView = segue.destination as! StudyViewController
           let object = sender as! String
            secondView.cellId = object
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
            return cell
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
