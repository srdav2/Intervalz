import CoreData
import SwiftUI // Keep SwiftUI import if needed for previews or other potential uses

// Shared PersistenceController for Core Data
struct PersistenceController {
    static let shared = PersistenceController()

    // Use standard container, not CloudKit
    let container: NSPersistentContainer

    // Preview provider for SwiftUI Previews - useful for both targets
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // Create sample data for previews
        let sampleWorkout = Workout(context: viewContext)
        sampleWorkout.id = UUID()
        sampleWorkout.name = "Preview Workout"
        sampleWorkout.createdAt = Date()
        sampleWorkout.restDuration = 60

        // Create a sample IntervalGroup
        let sampleGroup = IntervalGroup(context: viewContext)
        sampleGroup.id = UUID()
        sampleGroup.order = 0
        sampleGroup.repeatCount = 1 // Example repeat count
        sampleGroup.workout = sampleWorkout // Associate group with workout

        let interval1 = Interval(context: viewContext)
        interval1.id = UUID()
        interval1.name = "Warmup"
        interval1.duration = 300 // 5 minutes
        interval1.order = 0
        // Assign interval to the group
        interval1.group = sampleGroup

        let interval2 = Interval(context: viewContext)
        interval2.id = UUID()
        interval2.name = "Sprint"
        interval2.duration = 60 // 1 minute
        interval2.order = 1
        // Assign interval to the group
        interval2.group = sampleGroup

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()


    init(inMemory: Bool = false) {
        // Use standard container, not CloudKit
        container = NSPersistentContainer(name: "Intervalz")
        if inMemory {
            // Use in-memory store for previews or testing
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } 
        // else {
            // CloudKit configuration removed
        //    guard let description = container.persistentStoreDescriptions.first else {
        //        fatalError("###< PersistenceController >### No persistent store description found.")
        //    }
        //    // Ensure iCloud options are set
        //    description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        //    description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        //    // IMPORTANT: Ensure this matches your container identifier in Capabilities
        //    description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.stuartdavis.Intervalz")
        // }


        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
             print("Loaded persistent store: \(storeDescription.url?.absoluteString ?? "nil")")
        })
        // Merging from parent/iCloud is not needed for local-only store
        // container.viewContext.automaticallyMergesChangesFromParent = true 
        // container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
} 