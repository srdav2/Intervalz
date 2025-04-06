import SwiftUI
import HealthKit // Needed for HKWorkoutSessionState

struct WorkoutSessionView: View {
    @Environment(\.dismiss) var dismiss // To dismiss the view when workout ends
    @StateObject var sessionManager: WorkoutSessionManager // Manages the workout logic

    // Use the workout passed in to initialize the manager
    init(workout: Workout) {
        _sessionManager = StateObject(wrappedValue: WorkoutSessionManager(workout: workout))
    }

    var body: some View {
        // Use a TabView for paged navigation (common in watchOS workout apps)
        TabView {
            // Page 1: Timer and Current State
            timerPageView
                .tag(0)

            // Page 2: Controls (Pause/Resume/End)
            controlsPageView
                .tag(1)

            // Potentially add more pages later (e.g., Heart Rate, Metrics)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic)) // Use page dots
        .navigationBarBackButtonHidden(true) // Prevent accidental back swiping
        .onAppear {
            // Start the session when the view appears
            sessionManager.startSession()
        }
        .onChange(of: sessionManager.sessionState) { oldState, newState in
            // Dismiss the view automatically when the session ends
            if newState == .ended {
                dismiss()
            }
        }
        .colorScheme(.dark)
        .accentColor(Color(red: 0.0, green: 0.8, blue: 0.8))
    }

    // MARK: - Timer Page View
    private var timerPageView: some View {
        VStack(spacing: 8) { // Reduced spacing a bit
            Spacer()
            // Display Current Group Name and Repetition
            Text(sessionManager.currentGroupName)
                .font(.caption)
                .foregroundColor(.gray)
            if sessionManager.totalRepetitions != 1 { // Only show reps if more than 1 or indefinite
                Text(sessionManager.totalRepetitions == 0 ? "Repeat \(sessionManager.currentRepetition)" : "Repeat \(sessionManager.currentRepetition) of \(sessionManager.totalRepetitions)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            // Display Current Phase (Interval Name or Rest)
            Text(sessionManager.isRestPeriod ? "Rest" : sessionManager.currentPhaseName)
                .font(.title3)
                .lineLimit(1)
                .foregroundColor(sessionManager.isRestPeriod ? .blue : Color(red: 0.0, green: 0.8, blue: 0.8))

            // Display Timer
            Text(formatTimeInterval(sessionManager.timeRemaining))
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.5) // Allow text to shrink if needed

            // Removed overall step index display for now, can be added back if desired
            // Text("Step \(sessionManager.currentOverallStepIndex + 1)")
            //     .font(.caption)
            //     .foregroundColor(.gray)

            Spacer()
        }
        .padding()
        .background(Color.black) // Ensure black background
    }

    // MARK: - Controls Page View
    private var controlsPageView: some View {
        VStack(spacing: 15) {
            Spacer()
            HStack(spacing: 20) {
                // Pause/Resume Button
                Button {
                    if sessionManager.sessionState == .running {
                        sessionManager.pauseSession()
                    } else if sessionManager.sessionState == .paused {
                        sessionManager.resumeSession()
                    }
                } label: {
                    Image(systemName: sessionManager.sessionState == .running ? "pause.fill" : "play.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(.black)
                }
                .frame(width: 70, height: 70)
                .background(Color.yellow) // Standard pause color
                .clipShape(Circle())
                .disabled(sessionManager.sessionState == .ended) // Disable if ended

                // End Button
                Button {
                    sessionManager.endSession()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(.black)
                }
                .frame(width: 70, height: 70)
                .background(Color.red) // Standard end color
                .clipShape(Circle())
            }
            Spacer()
        }
        .padding()
        .background(Color.black)
    }

    // MARK: - Helper Functions
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Preview requires a sample workout with the new structure
struct WorkoutSessionView_Previews: PreviewProvider {
    static var previews: some View {
        // Use the preview controller which should have sample group data
        let context = PersistenceController.preview.container.viewContext
        let request = Workout.fetchRequest()
        // Find the specific sample workout created in PersistenceController.preview
        request.predicate = NSPredicate(format: "name == %@", "Sample Group Workout") 
        let sampleWorkout = try? context.fetch(request).first
        
        guard let workoutToPreview = sampleWorkout else {
             return AnyView(Text("Error loading preview workout"))
        }

        // Simulate being in a running state for preview
        let manager = WorkoutSessionManager(workout: workoutToPreview)
        manager.sessionState = .running
        manager.timeRemaining = 42 // Sample time
        manager.currentGroupName = "Group 1"
        manager.currentRepetition = 1
        manager.totalRepetitions = 2
        manager.currentPhaseName = "Work"

        return AnyView(
            WorkoutSessionView(workout: workoutToPreview)
                .environmentObject(manager) // Inject the manager for preview
                .environment(\.managedObjectContext, context)
        )
    }
} 