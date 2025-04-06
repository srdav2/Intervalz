//
//  ContentView.swift
//  Intervalzwatch Watch App
//
//  Created by stuart davis on 6/4/2025.
//

import SwiftUI
import CoreData // Import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext // Access context

    var body: some View {
        // Display the WorkoutListView as the main view for the watch app
        WorkoutListView()
            .environment(\.managedObjectContext, viewContext) // Pass context down
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
