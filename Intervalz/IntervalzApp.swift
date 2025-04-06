//
//  IntervalzApp.swift
//  Intervalz
//
//  Created by stuart davis on 6/4/2025.
//

import SwiftUI
import CoreData

@main
struct IntervalzApp: App {
    // Use the shared instance from the separate Persistence.swift file
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

// PersistenceController struct is now removed from this file and lives in Persistence.swift
