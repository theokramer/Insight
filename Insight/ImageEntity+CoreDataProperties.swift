//
//  ImageEntity+CoreDataProperties.swift
//  Insight
//
//  Created by Theo Kramer on 12.05.24.
//
//

import Foundation
import CoreData


extension ImageEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ImageEntity> {
        return NSFetchRequest<ImageEntity>(entityName: "ImageEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var topic: Topic?
    
    public var wrappedId: String {
            id ?? "Unknown Id"
        }

}

extension ImageEntity : Identifiable {

}
