import SwiftUI
import CoreData

struct WorkoutListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Fetch request to get workouts, sorted by creation date
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Workout.createdAt, ascending: true)],
        animation: .default)
    private var workouts: FetchedResults<Workout>

    @State private var showingAddWorkoutSheet = false

    var body: some View {
        NavigationView {
            List {
                ForEach(workouts) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                        Text(workout.name ?? "Unnamed Workout")
                    }
                }
                .onDelete(perform: deleteWorkouts)
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddWorkoutSheet = true
                    } label: {
                        Label("Add Workout", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddWorkoutSheet) {
                AddWorkoutView()
                    .environment(\.managedObjectContext, viewContext) // Pass context to sheet
            }
            // Placeholder for detail view when no workout is selected (especially on iPad)
            .safeAreaInset(edge: .bottom, content: { Color.clear.frame(height: 0) }) // Prevents list going under tab bar if added later
             Text("Select a workout") // Placeholder for split view
        }
        // Apply a dark theme consistent look
        .navigationViewStyle(.stack) // Use stack style for iPhone consistency
        .accentColor(Color(red: 0.0, green: 0.8, blue: 0.8)) // Teal accent color like Fitness app
    }

    private func deleteWorkouts(offsets: IndexSet) {
        withAnimation {
            offsets.map { workouts[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// Preview Provider
struct WorkoutListView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutListView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext) // Use shared controller for preview
            .preferredColorScheme(.dark) // Preview in dark mode
    }
} 