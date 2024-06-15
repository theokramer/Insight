//
//  ImageReview+CoreDataProperties.swift
//  
//
//  Created by Theo Kramer on 15.06.24.
//
//

import Foundation
import CoreData


extension ImageReview {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ImageReview> {
        return NSFetchRequest<ImageReview>(entityName: "ImageReview")
    }

    @NSManaged public var id: String?
    @NSManaged public var review_date: Date?
    @NSManaged public var rating: Int16
    @NSManaged public var interval: Int64
    @NSManaged public var ease_factor: Float
    @NSManaged public var repetitions: Int16
    @NSManaged public var image: ImageEntity?

}
