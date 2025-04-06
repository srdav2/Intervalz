//
//  Interval+CoreDataProperties.swift
//  Intervalz
//
//  Created by stuart davis on 6/4/2025.
//
//

import Foundation
import CoreData


extension Interval {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Interval> {
        return NSFetchRequest<Interval>(entityName: "Interval")
    }

    @NSManaged public var duration: Int64
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var order: Int16
    @NSManaged public var group: IntervalGroup?

}

extension Interval : Identifiable {

}
