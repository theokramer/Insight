//
//  PreProcessImage.swift
//  Insight
//
//  Created by Theo Kramer on 12.05.24.
//

import Foundation
import UIKit
import CoreData

struct TextBox {
    var minX: Float
    var minY: Float
    var width: Float
    var height: Float
    var id: String
}


extension ViewController {
    
    //Fetches the Images of Core Data and returns it as an Array
    static func fetchCoreData(onSuccess: @escaping ([ImageEntity]?) -> Void) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        do {
            let items = try context.fetch(ImageEntity.fetchRequest()) as? [ImageEntity]
            onSuccess(items)
        } catch {
            print("error-Fetching data")
        }
    }
    
    

    
    //Removes Image of Core Data at specific index
    static func deleteCoreData(indexPath: Int, items: [ImageEntity]) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let dataToRemove = items[indexPath]
        context.delete(dataToRemove)
        do {
            try context.save()
        } catch {
            print("error-Deleting data")
        }
    }
    
    //Saves the added Images in Core Data
    @objc func prepareImageForSaving() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        var found = false
        
        if singleMode {
            
            ViewController.fetchCoreData {items in
                if let items = (items ?? []) as [ImageEntity]? {
                    for item in items {
                        if self.singleImage.index == item.id {
                            
                            if self.singleImage.cropped {
                                context.delete(item)
                                do {
                                    try context.save()
                                    print("Single Success")
                                    found = false
                                } catch {
                                    print("error-Deleting data")
                                }
                                
                            } else {
                                found = true
                            }
                        }
                    }
                } else {
                    print("FEHLER")
                }
            }
            if !found {
                // create NSData from UIImage
                guard let jpegImageData = singleImage.image.jpegData(compressionQuality: 1) else {
                    // handle failed conversion
                    print("jpg error")
                    return
                }
                
                let newData = ImageEntity(context: context)
                newData.imageData = jpegImageData
                newData.id = singleImage.index
                
                for i in singleImage.boxes {
                    let singleBox = ImageBoxes(context: context)
                    singleBox.id = i.id
                    singleBox.height = i.height
                    singleBox.width = i.width
                    singleBox.minX = i.minX
                    singleBox.minY = i.minX
                    singleBox.imageEntity2 = newData
                }
                
                if cellId == "" {
                    newData.topic = Topic(context: context)
                    newData.topic?.id = UUID().uuidString
                    newData.topic?.name = "Physikum"
                } else {
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
                }
                
            }

        } else {
            for image in selectedImages {
                found = false
                
                //Removes all Images in Core Data that got cropped, so it gets updated.
                //TODO: Instead change the UIImage when cropped?
                ViewController.fetchCoreData {items in
                    if let items = (items ?? []) as [ImageEntity]? {
                        for item in items {
                            if image.index == item.id {
                                
                                if image.cropped {
                                    context.delete(item)
                                    do {
                                        try context.save()
                                        print("Success")
                                        found = false
                                    } catch {
                                        print("error-Deleting data")
                                    }
                                    
                                } else {
                                    found = true
                                }
                            }
                        }
                    } else {
                        print("FEHLER")
                    }
                }
                
                //If image is not in Core Data, upload it
                if !found {
                    // create NSData from UIImage
                    guard let jpegImageData = image.image.jpegData(compressionQuality: 1) else {
                        // handle failed conversion
                        print("jpg error")
                        return
                    }
                    
                    let newData = ImageEntity(context: context)
                    newData.imageData = jpegImageData
                    newData.id = image.index
                    
                    
                    for i in image.boxes {
                        let singleBox = ImageBoxes(context: context)
                        singleBox.id = i.id
                        singleBox.height = i.height
                        singleBox.width = i.width
                        singleBox.minX = i.minX
                        singleBox.minY = i.minX
                        singleBox.imageEntity2 = newData
                    }
                    
                    if cellId == "" {
                        newData.topic = Topic(context: context)
                        newData.topic?.id = UUID().uuidString
                        newData.topic?.name = "Physikum"
                    } else {
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
                    }
                    
                }
                
            }
        }
        
        
        
        DispatchQueue.main.async {
            do {
                try context.save()
                print("YEAH")
            } catch {
                print("error-saving data")
            }
        }
        
        if singleMode {
            self.dismiss(animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    
}
