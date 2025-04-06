import SwiftUI
import CoreData

struct AddIntervalGroupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    // The workout we're adding a group to
    let workout: Workout

    // Using String for TextField, will convert to Int16
    @State private var repeatCountString: String = "1" 
    @State private var repeatsIndefinitely: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Repetitions").foregroundColor(.gray)) {
                    HStack {
                        Text("Repeat Group")
                        Spacer()
                        // Use TextField for repeats, disable if indefinite is checked
                        TextField("Times", text: $repeatCountString)
                            .keyboardType(.numberPad)
                            .frame(width: 50)
                            .multilineTextAlignment(.trailing)
                            .disabled(repeatsIndefinitely)
                            .onChange(of: repeatCountString) { newValue in
                                // Ensure only numbers are entered and limit to reasonable max if needed
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if let num = Int(filtered), num <= 100 { // Limit repeats to 100
                                    repeatCountString = String(num)
                                } else if filtered.isEmpty {
                                    repeatCountString = ""
                                } else {
                                    repeatCountString = "100" // Max out
                                }
                            }
                        Text("times")
                    }
                    
                    Toggle("Repeat Indefinitely", isOn: $repeatsIndefinitely)
                        .onChange(of: repeatsIndefinitely) { newValue in
                            if newValue {
                                repeatCountString = "0" // Use 0 to represent indefinite
                            }
                        }
                }
                Section(header: Text("Hint").foregroundColor(.gray)) {
                    Text("Set repeats to 1 to run the intervals in this group only once.")
                    if repeatsIndefinitely {
                         Text("Indefinite repeat means the group repeats until the workout is manually ended.")
                             .foregroundColor(.blue)
                    } else {
                         Text("Set to 0 or use the toggle for indefinite repeats.")
                    }
                }
            }
            .navigationTitle("New Interval Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGroup()
                        dismiss()
                    }
                    // Validate: Ensure repeat count is a valid number >= 0
                    .disabled((Int16(repeatCountString) == nil && !repeatsIndefinitely) || (Int16(repeatCountString) ?? 1) < 0)
                }
            }
            .colorScheme(.dark)
        }
        .accentColor(Color(red: 0.0, green: 0.8, blue: 0.8))
    }

    private func saveGroup() {
        // Use 0 for indefinite, otherwise parse the string, default to 1 if invalid
        let repeatValue = repeatsIndefinitely ? 0 : (Int16(repeatCountString) ?? 1)
        // Ensure repeatValue is at least 0 if indefinite wasn't toggled
        let finalRepeatCount = max(0, repeatValue)

        withAnimation {
            let newGroup = IntervalGroup(context: viewContext)
            newGroup.id = UUID()
            newGroup.repeatCount = finalRepeatCount
            // Set order based on existing groups
            newGroup.order = Int16(workout.groups?.count ?? 0)
            newGroup.workout = workout

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error saving group \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct AddIntervalGroupView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let sampleWorkout = Workout(context: context)
        sampleWorkout.name = "Preview Workout for Group Add" // Assign name here

        // Return the view directly
        return AddIntervalGroupView(workout: sampleWorkout)
            .environment(\.managedObjectContext, context)
    }
} 