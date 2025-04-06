import SwiftUI
import CoreData

struct WorkoutDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var workout: Workout // Pass the selected workout

    // State to manage adding items (groups or intervals)
    @State private var showingAddItemSheet = false
    @State private var itemToAdd: ItemType? = nil // Enum to specify what to add
    @State private var targetGroup: IntervalGroup? = nil // For adding interval to specific group

    // Enum to differentiate sheet presentation
    enum ItemType: Identifiable {
        case group
        case interval
        var id: Int { hashValue }
    }

    // Computed property to sort groups by their 'order' attribute
    private var sortedGroups: [IntervalGroup] {
        let set = workout.groups as? Set<IntervalGroup> ?? []
        return set.sorted { $0.order < $1.order }
    }

    // Helper to get sorted intervals for a specific group
    private func sortedIntervals(for group: IntervalGroup) -> [Interval] {
        let set = group.intervals as? Set<Interval> ?? []
        return set.sorted { $0.order < $1.order }
    }

    var body: some View {
        List {
            // Section for Workout Details
            Section(header: Text("Workout Settings").foregroundColor(.gray)) {
                HStack {
                    Text("Default Rest")
                    Spacer()
                    Text(formatDuration(seconds: Int(workout.restDuration)))
                        .foregroundColor(.gray)
                }
            }

            // Display Groups and their Intervals
            ForEach(sortedGroups) { group in
                Section {
                    // Group Header with Repeat Count
                    HStack {
                        Text("Group \(group.order + 1)")
                            .font(.headline)
                        Spacer()
                        Text(group.repeatCount == 0 ? "Repeat Indefinitely" : "Repeat \(group.repeatCount)x")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    // TODO: Add Edit/Delete buttons for groups later

                    // Intervals within the group
                    ForEach(sortedIntervals(for: group)) { interval in
                        HStack {
                            Text(interval.name ?? "Interval \(interval.order + 1)")
                            Spacer()
                            Text(formatDuration(seconds: Int(interval.duration)))
                                .foregroundColor(.gray)
                        }
                    }
                    .onDelete { offsets in
                        deleteIntervals(in: group, at: offsets)
                    }
                    .onMove { source, destination in
                        moveIntervals(in: group, from: source, to: destination)
                    }

                    // Button to add interval TO THIS GROUP
                    Button {
                        targetGroup = group // Set the target group
                        itemToAdd = .interval // Specify adding an interval
                        showingAddItemSheet = true
                    } label: {
                        Label("Add Interval to Group \(group.order + 1)", systemImage: "plus.circle")
                            .font(.footnote)
                    }
                    .accentColor(Color(red: 0.0, green: 0.8, blue: 0.8).opacity(0.8))

                } header: { // Empty header to maintain Section spacing if needed
                    // Text("") // Use if header above doesn't provide enough space
                }
            }
            .onDelete(perform: deleteGroups) // Allow deleting whole groups
            // TODO: Add .onMove for reordering groups later

            // Button to add a new Group
            Button {
                targetGroup = nil // No specific group target
                itemToAdd = .group // Specify adding a group
                showingAddItemSheet = true
            } label: {
                Label("Add New Group", systemImage: "plus.rectangle.on.rectangle")
            }
            .accentColor(Color(red: 0.0, green: 0.8, blue: 0.8))
        }
        .navigationTitle(workout.name ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton() // Enable list editing (delete/move intervals within groups)
            }
        }
        .sheet(item: $itemToAdd) { itemType in // Use .sheet(item:) for context
            // Determine which sheet to present based on itemType
            switch itemType {
            case .group:
                AddIntervalGroupView(workout: workout)
                    .environment(\.managedObjectContext, viewContext)
            case .interval:
                // Ensure we have a target group when adding an interval
                if let targetGroup = targetGroup {
                    AddIntervalView(group: targetGroup) // Pass the group instead of workout
                        .environment(\.managedObjectContext, viewContext)
                } else {
                    // Fallback or error view if targetGroup is nil (shouldn't happen with current logic)
                    Text("Error: No target group specified for interval.")
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .colorScheme(.dark)
    }

    // --- Helper Functions (Modified/New) ---

    private func formatDuration(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    // Delete Groups
    private func deleteGroups(offsets: IndexSet) {
        withAnimation {
            let groupsToDelete = offsets.map { sortedGroups[$0] }
            groupsToDelete.forEach(viewContext.delete)
            updateGroupOrder()
            saveContext()
        }
    }

    // Delete Intervals within a specific group
    private func deleteIntervals(in group: IntervalGroup, at offsets: IndexSet) {
        withAnimation {
            let intervalsToDelete = offsets.map { sortedIntervals(for: group)[$0] }
            intervalsToDelete.forEach(viewContext.delete)
            updateIntervalOrder(in: group)
            saveContext()
        }
    }

    // Move Intervals within a specific group
    private func moveIntervals(in group: IntervalGroup, from source: IndexSet, to destination: Int) {
        var revisedIntervals = sortedIntervals(for: group)
        revisedIntervals.move(fromOffsets: source, toOffset: destination)
        for (index, interval) in revisedIntervals.enumerated() {
            interval.order = Int16(index)
        }
        saveContext()
    }

    // Update order after group deletion
    private func updateGroupOrder() {
        let remainingGroups = sortedGroups.filter { !$0.isDeleted }
        for (index, group) in remainingGroups.enumerated() {
            group.order = Int16(index)
        }
    }

    // Update interval order within a group after deletion
    private func updateIntervalOrder(in group: IntervalGroup) {
        let remainingIntervals = sortedIntervals(for: group).filter { !$0.isDeleted }
        for (index, interval) in remainingIntervals.enumerated() {
            interval.order = Int16(index)
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

// --- Preview Provider (Needs Update) ---
struct WorkoutDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Create dummy data matching new structure
        let context = PersistenceController.preview.container.viewContext
        let sampleWorkout = Workout(context: context)
        sampleWorkout.id = UUID()
        sampleWorkout.name = "Sample Group Workout"
        sampleWorkout.createdAt = Date()
        sampleWorkout.restDuration = 60

        let group1 = IntervalGroup(context: context)
        group1.id = UUID()
        group1.order = 0
        group1.repeatCount = 2 // Repeat twice
        group1.workout = sampleWorkout

        let interval1 = Interval(context: context)
        interval1.id = UUID()
        interval1.name = "Warmup"
        interval1.duration = 45
        interval1.order = 0
        interval1.group = group1

        let interval2 = Interval(context: context)
        interval2.id = UUID()
        interval2.name = "Work"
        interval2.duration = 60
        interval2.order = 1
        interval2.group = group1

        let group2 = IntervalGroup(context: context)
        group2.id = UUID()
        group2.order = 1
        group2.repeatCount = 1 // Run once
        group2.workout = sampleWorkout

        let interval3 = Interval(context: context)
        interval3.id = UUID()
        interval3.name = "Cooldown"
        interval3.duration = 120
        interval3.order = 0
        interval3.group = group2

        return NavigationView {
            WorkoutDetailView(workout: sampleWorkout)
                .environment(\.managedObjectContext, context)
                .preferredColorScheme(.dark)
        }
    }
} 