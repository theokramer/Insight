//
//  OverviewController.swift
//  Insight
//
//  Created by Theo Kramer on 13.05.24.
//

import Foundation
import UIKit
import CoreData

class OverviewController: UIViewController, UICollectionViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var textField: UITextField!
    var cellId: String = ""
    @IBOutlet weak var addChartsButton: UIButton!
    var dataSource:[selectedImages2] = []
    var estimateWidth = 160.0
    var cellMarginSize = 16.0
    
    struct selectedImages2 {
        var image: UIImage
        var index: String
        var cropped: Bool
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textField.delegate = self
        textField.returnKeyType = UIReturnKeyType.done
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
                        let imageStruct = selectedImages2.init(image: thisImage, index: item.wrappedId, cropped: false)
                        self.dataSource.append(imageStruct)
                    }
                    
                }
            } else {
                print("FEHLER")
            }
        }
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UINib(nibName: "itemCell", bundle: nil), forCellWithReuseIdentifier: "itemCell")
        self.setUpGridView()
    }
    
    func setUpGridView() {
        let flow = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flow.minimumInteritemSpacing = CGFloat(self.cellMarginSize)
        flow.minimumLineSpacing = CGFloat(self.cellMarginSize)
    }
    
    
    @IBAction func addChartsClicked(_ sender: Any) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        if let text = textField.text {
            print(text)
        }
        
        /*
         
         let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
         do {
             guard let items = try context.fetch(Topic.fetchRequest()) as? [Topic] else {
                 return
             }
             for myTopic in items {
                 if myTopic.id == cellId {
                     newData.topic = myTopic
                 }
                 
             }
         } catch {
             print("error-Fetching data")
         }
         
         */
        
        /*let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Topic")
        
        fetchRequest.predicate = NSPredicate(format: "id = %@", cellId)
        
        do {
            let fetchResults = try fetchRequest.execute()
            print(fetchResults)
            /*if fetchResults.count != 0{
                        let managedObject = fetchResults[0]
                        managedObject.setValue(textField.text, forKey: "name")*/

                    //}
        }
            
        catch {
            print("NOPE")
        }
        
        DispatchQueue.main.async {
            do {
                try context.save()
                print("YEAH")
            } catch {
                print("error-saving data")
            }
        }*/
        
        
        performSegue(withIdentifier: "showViewController", sender: cellId)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       if (segue.identifier == "showViewController") {
          let secondView = segue.destination as! ViewController
          let object = sender as! String
           secondView.cellId = object
       }
    }
}

extension OverviewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "itemCell", for: indexPath) as! itemCell
        cell.setImage(image: self.dataSource[indexPath.row].image)
        return cell
    }
}

extension OverviewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.calculateWidth()
        return CGSize(width: width, height: width)
    }
    func calculateWidth() -> CGFloat {
        let estimateWidth = CGFloat(estimateWidth)
        let cellCount = floor(CGFloat(self.view.frame.size.width / estimateWidth))
        let margin = CGFloat(cellMarginSize * 2)
        let width = (CGFloat(self.view.frame.size.width) - CGFloat(cellMarginSize) * (cellCount - 1) - margin) / cellCount
        return width
    }
}
