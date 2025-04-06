import Foundation
import HealthKit
import WatchKit // For haptics
import Combine // For ObservableObject

// Observable object to manage the state and logic of a workout session
class WorkoutSessionManager: NSObject, ObservableObject, HKWorkoutSessionDelegate {

    // MARK: - Published Properties (for SwiftUI View)
    @Published var currentOverallStepIndex: Int = 0 // Tracks overall progress across all steps/repeats
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRestPeriod: Bool = false
    @Published var sessionState: HKWorkoutSessionState = .notStarted
    @Published var workoutName: String = ""
    @Published var currentPhaseName: String = "" // Name of interval or "Rest"
    @Published var currentRepetition: Int = 1 // Current repeat count for the group
    @Published var totalRepetitions: Int = 1 // Total repeats for the current group (0 for indefinite)
    @Published var currentGroupName: String = "" // Optional name for the group

    // MARK: - Properties
    let healthStore = HKHealthStore()
    var workoutSession: HKWorkoutSession?
    var workoutBuilder: HKWorkoutBuilder?
    let workout: Workout // The workout plan from Core Data
    private var timer: Timer?
    private var workoutPlan: [(group: IntervalGroup, intervals: [Interval])] = [] // Structured plan
    private var defaultRestDuration: TimeInterval

    // State tracking for the current position in the workoutPlan
    private var currentGroupIndex: Int = 0
    private var currentIntervalIndexInGroup: Int = 0
    private var currentRepeatCountForGroup: Int = 1
    private let indefiniteRepeatThreshold = 100 // Arbitrary limit for "indefinite"

    // MARK: - Initialization
    init(workout: Workout) {
        self.workout = workout
        self.defaultRestDuration = TimeInterval(workout.restDuration)
        super.init()
        setupWorkoutPlan()
    }

    private func setupWorkoutPlan() {
        self.workoutName = workout.name ?? "Unnamed Workout"
        let groupSet = workout.groups as? Set<IntervalGroup> ?? []
        let sortedGroups = groupSet.sorted { $0.order < $1.order }

        // Create the structured plan
        workoutPlan = sortedGroups.map { group in
            let intervalSet = group.intervals as? Set<Interval> ?? []
            let sortedIntervals = intervalSet.sorted { $0.order < $1.order }
            return (group: group, intervals: sortedIntervals)
        }

        // Set initial state if the plan is not empty
        if let firstGroupTuple = workoutPlan.first, let firstInterval = firstGroupTuple.intervals.first {
            let firstGroup = firstGroupTuple.group
            self.timeRemaining = TimeInterval(firstInterval.duration)
            self.currentPhaseName = firstInterval.name ?? "Interval 1"
            self.currentGroupName = "Group \(firstGroup.order + 1)" // Basic group name
            self.totalRepetitions = Int(firstGroup.repeatCount)
            self.currentRepetition = 1
            self.isRestPeriod = false
        } else {
            // Handle empty workout case
            self.timeRemaining = 0
            self.currentPhaseName = "Empty Workout"
            self.currentGroupName = ""
            self.totalRepetitions = 0
            self.currentRepetition = 0
        }
        self.currentOverallStepIndex = 0
    }

    // MARK: - Session Control
    func startSession() {
        guard !workoutPlan.isEmpty, workoutPlan.contains(where: { !$0.intervals.isEmpty }) else {
            print("Cannot start workout with no groups or intervals.")
            // TODO: Handle this error state more gracefully
            return
        }
        // Reset state variables just in case start is called multiple times (though UI should prevent)
        currentGroupIndex = 0
        currentIntervalIndexInGroup = 0
        currentRepeatCountForGroup = 1
        setupWorkoutPlan() // Re-setup initial state display values

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .highIntensityIntervalTraining
        configuration.locationType = .unknown

        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
        } catch {
            print("Error creating workout session: \(error.localizedDescription)")
            return
        }

        workoutSession?.delegate = self
        workoutSession?.startActivity(with: Date())
        workoutBuilder?.beginCollection(withStart: Date()) { (success, error) in
            guard success else {
                print("Error beginning builder collection: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            DispatchQueue.main.async {
                self.sessionState = .running
                self.startTimer()
                print("Workout session started and builder collection began.")
            }
        }
    }

    func pauseSession() {
        workoutSession?.pause()
    }

    func resumeSession() {
        workoutSession?.resume()
    }

    func endSession() {
        workoutSession?.end()
    }

    // MARK: - Timer Logic
    private func startTimer() {
        stopTimer() // Ensure no existing timer is running
        guard sessionState == .running else { return }

        // Schedule a timer that fires every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.sessionState == .running else { return }

            if self.timeRemaining > 1 {
                self.timeRemaining -= 1
            } else {
                // Time's up for the current interval/rest
                self.timeRemaining = 0
                self.playHapticFeedback()
                self.moveToNextPhase()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Phase Transition
    private func moveToNextPhase() {
        stopTimer() // Stop timer during transition
        currentOverallStepIndex += 1 // Increment step counter

        let currentGroupTuple = workoutPlan[currentGroupIndex]
        let currentGroup = currentGroupTuple.group
        let intervalsInCurrentGroup = currentGroupTuple.intervals
        let repeatsForCurrentGroup = Int(currentGroup.repeatCount)

        if isRestPeriod {
            // ========== Rest Period Finished ==========
            isRestPeriod = false
            currentIntervalIndexInGroup += 1

            if currentIntervalIndexInGroup < intervalsInCurrentGroup.count {
                // --- Move to next interval within the same group repeat ---
                let nextInterval = intervalsInCurrentGroup[currentIntervalIndexInGroup]
                timeRemaining = TimeInterval(nextInterval.duration)
                currentPhaseName = nextInterval.name ?? "Interval \(currentIntervalIndexInGroup + 1)"
                // currentRepetition and totalRepetitions remain the same
                startTimer()
            } else {
                // --- Finished last interval of the current group repeat ---
                currentRepeatCountForGroup += 1

                // Check if more repeats are needed for this group
                let indefiniteRepeat = (repeatsForCurrentGroup == 0)
                let maxRepeats = indefiniteRepeat ? indefiniteRepeatThreshold : repeatsForCurrentGroup

                if currentRepeatCountForGroup <= maxRepeats {
                    // --- Start next repeat of the current group ---
                    currentIntervalIndexInGroup = 0 // Reset to first interval
                    let firstInterval = intervalsInCurrentGroup[currentIntervalIndexInGroup]
                    timeRemaining = TimeInterval(firstInterval.duration)
                    currentPhaseName = firstInterval.name ?? "Interval 1"
                    currentRepetition = currentRepeatCountForGroup // Update displayed repetition
                    // totalRepetitions remains the same
                    startTimer()
                } else {
                    // --- Finished all repeats for the current group, move to next group ---
                    currentGroupIndex += 1
                    if currentGroupIndex < workoutPlan.count {
                        // --- Start first interval of the next group ---
                        let nextGroupTuple = workoutPlan[currentGroupIndex]
                        let nextGroup = nextGroupTuple.group
                        guard let firstInterval = nextGroupTuple.intervals.first else {
                            // Skip empty group (should ideally be prevented by UI)
                            print("Warning: Skipping empty group at index \(currentGroupIndex)")
                            moveToNextPhase() // Immediately try to move past it
                            return
                        }
                        currentIntervalIndexInGroup = 0
                        currentRepeatCountForGroup = 1
                        timeRemaining = TimeInterval(firstInterval.duration)
                        currentPhaseName = firstInterval.name ?? "Interval 1"
                        currentGroupName = "Group \(nextGroup.order + 1)"
                        totalRepetitions = Int(nextGroup.repeatCount)
                        currentRepetition = 1
                        startTimer()
                    } else {
                        // --- Finished last group, end workout ---
                        endSession()
                    }
                }
            }
        } else {
            // ========== Interval Period Finished ==========

            // Check if it was the last interval in the current group repeat
            if currentIntervalIndexInGroup < intervalsInCurrentGroup.count - 1 {
                // --- Move to rest period before next interval in this repeat ---
                isRestPeriod = true
                timeRemaining = defaultRestDuration
                currentPhaseName = "Rest"
                startTimer()
            } else {
                // --- Finished last interval of the group repeat ---
                // Check if more repeats are needed OR if it's the last group overall
                let indefiniteRepeat = (repeatsForCurrentGroup == 0)
                let maxRepeats = indefiniteRepeat ? indefiniteRepeatThreshold : repeatsForCurrentGroup
                let isLastGroup = (currentGroupIndex == workoutPlan.count - 1)
                let moreRepeatsInGroup = (currentRepeatCountForGroup < maxRepeats)

                if moreRepeatsInGroup || !isLastGroup {
                    // --- Move to rest period before next repeat or next group ---
                    isRestPeriod = true
                    timeRemaining = defaultRestDuration
                    currentPhaseName = "Rest"
                    startTimer()
                } else {
                    // --- Finished last interval of last repeat of last group, end workout ---
                    endSession()
                }
            }
        }
    }

    // MARK: - Haptics
    private func playHapticFeedback() {
        // Play a distinct haptic to signal phase end
        WKInterfaceDevice.current().play(.success)
    }

    // MARK: - HKWorkoutSessionDelegate Methods

    // Called when the session state changes
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.sessionState = toState
            print("Workout session state changed to: \(toState.rawValue)")

            switch toState {
            case .running:
                // Restart timer if resuming from paused state
                if fromState == .paused {
                    self.startTimer()
                }
            case .paused:
                // Stop the timer when paused
                self.stopTimer()
            case .ended:
                // Stop timer and finalize workout
                self.stopTimer()
                self.finalizeWorkout(endDate: date)
            case .notStarted, .prepared:
                break // Nothing specific needed here yet
            @unknown default:
                print("Unhandled workout session state: \(toState)")
                break // ENSURE THIS BREAK IS PRESENT
            }
        }
    }

    // Called if the session fails
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed with error: \(error.localizedDescription)")
        // TODO: Handle session failure (e.g., show alert, stop timer)
        DispatchQueue.main.async {
            self.stopTimer()
            self.sessionState = .notStarted // Or an error state if defined
        }
    }

    // MARK: - Finalize Workout
    private func finalizeWorkout(endDate: Date) {
        workoutBuilder?.endCollection(withEnd: endDate) { (success, error) in
            if !success {
                print("Error ending builder collection: \(error?.localizedDescription ?? "Unknown error")")
                // Handle error
                return
            }

            self.workoutBuilder?.finishWorkout { (savedWorkout, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error saving workout to HealthKit: \(error.localizedDescription)")
                        // Handle error - maybe inform user workout wasn't saved
                    } else {
                        print("Workout successfully saved to HealthKit: \(savedWorkout?.description ?? "N/A")")
                        // Workout saved successfully
                    }
                    // Reset builder and session reference
                    self.workoutBuilder = nil
                    self.workoutSession = nil
                    // The view observing sessionState == .ended should handle dismissal/navigation
                }
            }
        }
    }
} 
