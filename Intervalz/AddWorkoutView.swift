import SwiftUI

struct AddWorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss // To close the sheet

    @State private var workoutName: String = ""
    @State private var restDurationMinutes: Int = 1 // Default rest 1 minute
    @State private var restDurationSeconds: Int = 0  // Default rest 0 seconds

    // Simple validation
    private var isInputValid: Bool {
        !workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (restDurationMinutes > 0 || restDurationSeconds > 0)
    }

    let availableMinutes = Array(0...59)
    let availableSeconds = Array(0...59)

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Workout Details").foregroundColor(.gray)) {
                    TextField("Workout Name", text: $workoutName)
                }

                Section(header: Text("Default Rest Period Between Intervals").foregroundColor(.gray)) {
                    HStack {
                        Picker("Minutes", selection: $restDurationMinutes) {
                            ForEach(availableMinutes, id: \.self) { minute in
                                Text("\(minute) min").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel) // Use wheel picker for better selection
                        .frame(width: 100)
                        .clipped()

                        Picker("Seconds", selection: $restDurationSeconds) {
                            ForEach(availableSeconds, id: \.self) { second in
                                Text("\(second) sec").tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        .clipped()
                    }
                    .frame(height: 150) // Give pickers enough height
                }
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWorkout()
                        dismiss()
                    }
                    .disabled(!isInputValid) // Disable save if input is invalid
                }
            }
            // Apply dark theme styling
            .background(Color.black.edgesIgnoringSafeArea(.all)) // Black background
            .colorScheme(.dark) // Ensure text and controls are light
        }
        .accentColor(Color(red: 0.0, green: 0.8, blue: 0.8)) // Teal accent color
    }

    private func saveWorkout() {
        withAnimation {
            let newWorkout = Workout(context: viewContext)
            newWorkout.id = UUID()
            newWorkout.createdAt = Date()
            newWorkout.name = workoutName.trimmingCharacters(in: .whitespacesAndNewlines)
            // Convert minutes and seconds to total seconds for storage
            newWorkout.restDuration = Int64((restDurationMinutes * 60) + restDurationSeconds)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                // In a real app, handle this error more gracefully
                print("Unresolved error \(nsError), \(nsError.userInfo)")
                // fatalError is okay for development but not production
                // fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct AddWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        AddWorkoutView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
} 