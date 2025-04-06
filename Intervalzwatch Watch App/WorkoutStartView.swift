import SwiftUI
import HealthKit // Import HealthKit

struct WorkoutStartView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss // To potentially dismiss this view programmatically
    @ObservedObject var workout: Workout

    // State to manage navigation to the active session view
    @State private var shouldNavigateToSession = false

    // HealthKit store
    let healthStore = HKHealthStore()

    // Computed property to get all intervals sorted by group order, then interval order
    private var sortedIntervals: [Interval] {
        // Safely unwrap the groups Set
        guard let groupsSet = workout.groups as? Set<IntervalGroup> else { return [] }

        // Sort groups by their order
        let sortedGroups = groupsSet.sorted { $0.order < $1.order }

        // Flatten intervals from sorted groups, then sort intervals within each group
        let allIntervals = sortedGroups.flatMap { group -> [Interval] in
            guard let intervalsSet = group.intervals as? Set<Interval> else { return [] }
            return intervalsSet.sorted { $0.order < $1.order } // Sort intervals within the group
        }

        return allIntervals
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text(workout.name ?? "Workout")
                    .font(.title3)
                    .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.8))

                Text("Intervals: \(sortedIntervals.count)")
                Text("Default Rest: \(formatDuration(seconds: Int(workout.restDuration)))")

                if !sortedIntervals.isEmpty {
                    Text("Preview:")
                        .font(.headline)
                        .foregroundColor(.gray)
                    // Show first few intervals as a preview
                    ForEach(sortedIntervals.prefix(3)) { interval in
                        HStack {
                            Text(interval.name ?? "Interval \(interval.order + 1)")
                            Spacer()
                            Text(formatDuration(seconds: Int(interval.duration)))
                                .foregroundColor(.gray)
                        }
                    }
                    if sortedIntervals.count > 3 {
                        Text("...")
                            .foregroundColor(.gray)
                    }
                }

                Button {
                    startWorkout() // Call function to request authorization and start
                } label: {
                    Text("Start")
                        .font(.headline)
                        .foregroundColor(.black) // Black text on green button
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green) // Standard workout start button color
                .cornerRadius(10)

            }
            .padding()
        }
        .navigationDestination(isPresented: $shouldNavigateToSession) {
            WorkoutSessionView(workout: workout)
        }
        .navigationTitle("Ready?")
        .navigationBarTitleDisplayMode(.inline)
        .accentColor(Color(red: 0.0, green: 0.8, blue: 0.8))
        .colorScheme(.dark)
    }

    // Function to request HealthKit authorization and proceed
    private func startWorkout() {
        requestHealthKitAuthorization {
            // This completion handler runs after the user responds to the HealthKit prompt
            // We navigate whether authorized or not, the session view will handle denied state
            shouldNavigateToSession = true
        }
    }

    // Request HealthKit Authorization
    private func requestHealthKitAuthorization(completion: @escaping () -> Void) {
        let typesToShare: Set = [
            HKObjectType.workoutType() // Request permission to save workouts
        ]
        let typesToRead: Set = [
            HKObjectType.workoutType() // Optionally read past workouts if needed later
            // Add other types like heart rate if you plan to read them during the workout
            // HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]

        // Check if HealthKit is available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on this device.")
            // Handle error - maybe show an alert
            completion() // Proceed even if unavailable, session view might show error
            return
        }

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            if let error = error {
                print("Error requesting HealthKit authorization: \(error.localizedDescription)")
                // Handle error
            }

            if success {
                print("HealthKit authorization granted.")
            } else {
                print("HealthKit authorization denied.")
                // User denied permission, the session view should handle this gracefully
            }
            // Call the completion handler on the main thread to trigger UI updates
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    // Helper function to format seconds into MM:SS
    private func formatDuration(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// Preview needs a sample workout
struct WorkoutStartView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let sampleWorkout = Workout(context: context)
        sampleWorkout.id = UUID()
        sampleWorkout.name = "Preview Workout"
        sampleWorkout.createdAt = Date()
        sampleWorkout.restDuration = 60

        // Create a sample group for the preview
        let sampleGroup = IntervalGroup(context: context)
        sampleGroup.id = UUID()
        sampleGroup.order = 0
        sampleGroup.repeatCount = 1
        sampleGroup.workout = sampleWorkout // Link group to workout

        let interval1 = Interval(context: context)
        interval1.id = UUID()
        interval1.name = "Warmup Preview" // Give it a name for clarity
        interval1.duration = 45
        interval1.order = 0
        interval1.group = sampleGroup // Link interval to group

        // Add another interval to the sample group for better preview
        let interval2 = Interval(context: context)
        interval2.id = UUID()
        interval2.name = "Sprint Preview"
        interval2.duration = 30
        interval2.order = 1
        interval2.group = sampleGroup // Link interval to group

        return NavigationView { // Wrap in NavigationView for preview title
            WorkoutStartView(workout: sampleWorkout)
                .environment(\.managedObjectContext, context)
        }
    }
} 