//
//  ImageBoxes+CoreDataProperties.swift
//  
//
//  Created by Theo Kramer on 20.06.24.
//
//

import Foundation
import CoreData


extension ImageBoxes {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ImageBoxes> {
        return NSFetchRequest<ImageBoxes>(entityName: "ImageBoxes")
    }

    @NSManaged public var height: Float
    @NSManaged public var id: String?
    @NSManaged public var minX: Float
    @NSManaged public var minY: Float
    @NSManaged public var width: Float
    @NSManaged public var tag: Int64
    @NSManaged public var imageEntity2: ImageEntity?
    
    public var wrappedId: String {
        id ?? "Unknown Name"
    }

}
