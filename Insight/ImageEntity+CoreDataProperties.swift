//
//  ImageEntity+CoreDataProperties.swift
//  
//
//  Created by Theo Kramer on 18.06.24.
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
    @NSManaged public var review: ImageReview?
    @NSManaged public var topic: Topic?
    @NSManaged public var boxes: NSSet?
    
    public var wrappedId: String {
        id ?? "Unknown Name"
    }

}

// MARK: Generated accessors for boxes
extension ImageEntity {

    @objc(addBoxesObject:)
    @NSManaged public func addToBoxes(_ value: ImageBoxes)

    @objc(removeBoxesObject:)
    @NSManaged public func removeFromBoxes(_ value: ImageBoxes)

    @objc(addBoxes:)
    @NSManaged public func addToBoxes(_ values: NSSet)

    @objc(removeBoxes:)
    @NSManaged public func removeFromBoxes(_ values: NSSet)

}
