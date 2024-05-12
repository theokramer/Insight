//
//  PreProcessImage.swift
//  Insight
//
//  Created by Theo Kramer on 12.05.24.
//

import Foundation
import UIKit
import CoreData


extension ViewController {
    
    static func fetchCoreData(onSuccess: @escaping ([ImageEntity]?) -> Void) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        do {
            let items = try context.fetch(ImageEntity.fetchRequest()) as? [ImageEntity]
            onSuccess(items)
        } catch {
            print("error-Fetching data")
        }
    }
    
    
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

    func prepareImageForSaving(images:[ViewController.selectedImages2]) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        var found = false
        for image in images {
            found = false
            ViewController.fetchCoreData {items in
                if let items = (items ?? []) as [ImageEntity]? {
                    for item in items {
                        if image.index == item.id {
                            found = true
                        }
                    }
                } else {
                    print("FEHLER")
                }
            }
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
                newData.topic = Topic(context: context)
                newData.topic?.id = UUID().uuidString
                newData.topic?.name = UUID().uuidString
                
                
                
                
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
        
        
        

    }
    
    
}
