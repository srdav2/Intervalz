//
//  IntervalGroup+CoreDataProperties.swift
//  Intervalz
//
//  Created by stuart davis on 6/4/2025.
//
//

import Foundation
import CoreData


extension IntervalGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<IntervalGroup> {
        return NSFetchRequest<IntervalGroup>(entityName: "IntervalGroup")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var order: Int16
    @NSManaged public var repeatCount: Int16
    @NSManaged public var intervals: NSSet?
    @NSManaged public var workout: Workout?

}

// MARK: Generated accessors for intervals
extension IntervalGroup {

    @objc(addIntervalsObject:)
    @NSManaged public func addToIntervals(_ value: Interval)

    @objc(removeIntervalsObject:)
    @NSManaged public func removeFromIntervals(_ value: Interval)

    @objc(addIntervals:)
    @NSManaged public func addToIntervals(_ values: NSSet)

    @objc(removeIntervals:)
    @NSManaged public func removeFromIntervals(_ values: NSSet)

}

extension IntervalGroup : Identifiable {

}
