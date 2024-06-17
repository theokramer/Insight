//
//  Topic+CoreDataProperties.swift
//  
//
//  Created by Theo Kramer on 17.06.24.
//
//

import Foundation
import CoreData


extension Topic {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Topic> {
        return NSFetchRequest<Topic>(entityName: "Topic")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var imageEntity: NSSet?
    
    public var wrappedId: String {
        id ?? "Unknown Name"
    }
    
    public var wrappedName: String {
        name ?? "Unknown Name"
    }
    
    public var imageArray: [ImageEntity] {
        let set = imageEntity as? Set<ImageEntity> ?? []
        return set.sorted {
            $0.wrappedId <  $1.wrappedId
        }
    }

}

// MARK: Generated accessors for imageEntity
extension Topic {

    @objc(addImageEntityObject:)
    @NSManaged public func addToImageEntity(_ value: ImageEntity)

    @objc(removeImageEntityObject:)
    @NSManaged public func removeFromImageEntity(_ value: ImageEntity)

    @objc(addImageEntity:)
    @NSManaged public func addToImageEntity(_ values: NSSet)

    @objc(removeImageEntity:)
    @NSManaged public func removeFromImageEntity(_ values: NSSet)
    
    

}
