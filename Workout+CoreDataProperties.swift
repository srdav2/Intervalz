//
//  Workout+CoreDataProperties.swift
//  Intervalz
//
//  Created by stuart davis on 6/4/2025.
//
//

import Foundation
import CoreData


extension Workout {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Workout> {
        return NSFetchRequest<Workout>(entityName: "Workout")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var restDuration: Int64
    @NSManaged public var groups: NSSet?

}

// MARK: Generated accessors for groups
extension Workout {

    @objc(addGroupsObject:)
    @NSManaged public func addToGroups(_ value: IntervalGroup)

    @objc(removeGroupsObject:)
    @NSManaged public func removeFromGroups(_ value: IntervalGroup)

    @objc(addGroups:)
    @NSManaged public func addToGroups(_ values: NSSet)

    @objc(removeGroups:)
    @NSManaged public func removeFromGroups(_ values: NSSet)

}

extension Workout : Identifiable {

}
