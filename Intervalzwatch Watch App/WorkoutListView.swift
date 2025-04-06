import SwiftUI
import CoreData

struct WorkoutListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Workout.createdAt, ascending: true)],
        animation: .default)
    private var workouts: FetchedResults<Workout>

    var body: some View {
        NavigationView {
            List {
                if workouts.isEmpty {
                    Text("No workouts created yet. Add workouts on your iPhone.")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ForEach(workouts) { workout in
                        // NavigationLink to a detail/start view (to be created)
                        NavigationLink(destination: WorkoutStartView(workout: workout)) {
                            Text(workout.name ?? "Unnamed Workout")
                                .lineLimit(1) // Keep names concise on watch
                        }
                    }
                    // Deleting workouts might be better handled on the iPhone app for simplicity
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
        }
        .accentColor(Color(red: 0.0, green: 0.8, blue: 0.8)) // Teal accent
        // Apply dark theme styling
        .colorScheme(.dark)
    }
}

struct WorkoutListView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview needs the managed object context
        WorkoutListView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
} 