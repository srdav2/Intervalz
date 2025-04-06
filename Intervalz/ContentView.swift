//
//  ContentView.swift
//  Intervalz
//
//  Created by stuart davis on 6/4/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        // Display our WorkoutListView as the main view
        WorkoutListView()
            .preferredColorScheme(.dark) // Apply dark mode preference globally here too
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
