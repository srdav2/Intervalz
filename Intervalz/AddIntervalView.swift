import SwiftUI
import CoreData

struct AddIntervalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    // The group we're adding an interval to (changed from workout)
    let group: IntervalGroup

    @State private var intervalName: String = ""
    @State private var durationMinutes: Int = 0
    @State private var durationSeconds: Int = 30 // Default interval 30 seconds

    // Simple validation: duration must be greater than 0
    private var isInputValid: Bool {
        durationMinutes > 0 || durationSeconds > 0
    }

    let availableMinutes = Array(0...59)
    let availableSeconds = Array(0...59)

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Interval Details").foregroundColor(.gray)) {
                    TextField("Interval Name (Optional)", text: $intervalName)
                }

                Section(header: Text("Interval Duration").foregroundColor(.gray)) {
                    HStack {
                        Picker("Minutes", selection: $durationMinutes) {
                            ForEach(availableMinutes, id: \.self) { minute in
                                Text("\(minute) min").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        .clipped()

                        Picker("Seconds", selection: $durationSeconds) {
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
            .navigationTitle("New Interval")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveInterval()
                        dismiss()
                    }
                    .disabled(!isInputValid)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .colorScheme(.dark)
        }
        .accentColor(Color(red: 0.0, green: 0.8, blue: 0.8))
    }

    private func saveInterval() {
        withAnimation {
            let newInterval = Interval(context: viewContext)
            newInterval.id = UUID()
            let intervalNameTrimmed = intervalName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !intervalNameTrimmed.isEmpty {
                newInterval.name = intervalNameTrimmed
            }
            newInterval.duration = Int64((durationMinutes * 60) + durationSeconds)

            // Set the order based on existing intervals within the group
            let currentMaxOrder = group.intervals?.count ?? 0
            newInterval.order = Int16(currentMaxOrder)

            // Establish the relationship to the group
            newInterval.group = group

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
                // Handle error
            }
        }
    }
}

// Preview needs a sample Group
struct AddIntervalView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        // Find the sample workout and its first group from the preview controller
        let request = Workout.fetchRequest()
        let sampleWorkout = try? context.fetch(request).first
        let sampleGroup = sampleWorkout?.groups?.anyObject() as? IntervalGroup ?? IntervalGroup(context: context)
        if sampleGroup.workout == nil { // Add dummy if needed
            sampleGroup.workout = sampleWorkout
            sampleGroup.id = UUID()
            sampleGroup.repeatCount = 1
        }

        return AddIntervalView(group: sampleGroup)
            .environment(\.managedObjectContext, context)
    }
} 