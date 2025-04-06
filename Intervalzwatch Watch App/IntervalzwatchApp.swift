//
//  IntervalzwatchApp.swift
//  Intervalzwatch Watch App
//
//  Created by stuart davis on 6/4/2025.
//

import SwiftUI
import CoreData

@main
struct Intervalzwatch_Watch_AppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
