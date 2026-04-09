import SwiftUI
import SwiftData

@main
struct GymTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RoutineListView()
        }
        .modelContainer(for: [
            Routine.self,
            RoutineDay.self,
            PlannedExercise.self,
            WeightLog.self,
            CompletedSession.self
        ])
    }
}
