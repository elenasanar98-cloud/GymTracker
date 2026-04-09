import Foundation
import SwiftData

// MARK: - Routine
/// Represents a full training program (e.g. "Glute Focus 12 weeks")
@Model
final class Routine {
    var id: UUID
    var name: String
    var createdAt: Date
    /// Total duration in weeks (default 12)
    var totalWeeks: Int
    /// Days of week this routine runs: 1=Sunday … 7=Saturday (Calendar standard)
    var weekdays: [Int]

    @Relationship(deleteRule: .cascade) var days: [RoutineDay] = []
    @Relationship(deleteRule: .cascade) var completedSessions: [CompletedSession] = []

    init(name: String, totalWeeks: Int = 12, weekdays: [Int]) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.totalWeeks = totalWeeks
        self.weekdays = weekdays.sorted()
    }

    // MARK: Next day logic
    /// Returns the next RoutineDay that should be trained based on last completed session.
    func nextDay() -> RoutineDay? {
        guard !days.isEmpty else { return nil }

        let sortedDays = days.sorted {
            if $0.weekNumber != $1.weekNumber { return $0.weekNumber < $1.weekNumber }
            return $0.weekdayIndex < $1.weekdayIndex
        }

        guard let lastSession = completedSessions.sorted(by: { $0.completedAt < $1.completedAt }).last,
              let lastDay = lastSession.routineDay else {
            // Never trained: return first day
            return sortedDays.first
        }

        // Find the day AFTER the last completed one
        if let idx = sortedDays.firstIndex(where: { $0.id == lastDay.id }),
           idx + 1 < sortedDays.count {
            return sortedDays[idx + 1]
        }
        // Routine finished
        return nil
    }

    var isCompleted: Bool {
        nextDay() == nil && !days.isEmpty
    }

    var progressDescription: String {
        let total = days.count
        let done = completedSessions.count
        return "\(done)/\(total) días"
    }
}

// MARK: - RoutineDay
/// One training day: e.g. "Week 1 – Monday"
@Model
final class RoutineDay {
    var id: UUID
    var weekNumber: Int       // 1-12
    var weekdayIndex: Int     // same scale as Routine.weekdays (1=Sun…7=Sat)
    var notes: String

    @Relationship(deleteRule: .cascade) var exercises: [PlannedExercise] = []
    /// Back-reference (not stored, queried)
    var routine: Routine?

    init(weekNumber: Int, weekdayIndex: Int, notes: String = "") {
        self.id = UUID()
        self.weekNumber = weekNumber
        self.weekdayIndex = weekdayIndex
        self.notes = notes
    }

    var weekdayName: String {
        // weekdayIndex uses Calendar: 1=Sun, 2=Mon ... 7=Sat
        let symbols = Calendar.current.weekdaySymbols
        let idx = max(0, min(weekdayIndex - 1, symbols.count - 1))
        return symbols[idx]
    }

    var title: String { "Semana \(weekNumber) – \(weekdayName)" }

    var isCompleted: Bool {
        guard let r = routine else { return false }
        return r.completedSessions.contains { $0.routineDay?.id == self.id }
    }
}

// MARK: - PlannedExercise
/// An exercise as it appears in a RoutineDay, with its prescribed sets/reps/rest.
@Model
final class PlannedExercise {
    var id: UUID
    var name: String
    var orderIndex: Int
    var sets: Int
    var repsPerSet: Int
    var restSeconds: Int
    var notes: String

    var routineDay: RoutineDay?
    @Relationship(deleteRule: .cascade) var weightLogs: [WeightLog] = []

    init(name: String, orderIndex: Int = 0, sets: Int, repsPerSet: Int, restSeconds: Int, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.orderIndex = orderIndex
        self.sets = sets
        self.repsPerSet = repsPerSet
        self.restSeconds = restSeconds
        self.notes = notes
    }

    // MARK: Weight helpers
    /// Most recent weight logged for this exercise
    var lastWeight: Double? {
        weightLogs.sorted(by: { $0.loggedAt < $1.loggedAt }).last?.weight
    }

    /// All-time max weight (RM)
    var rm: Double? {
        weightLogs.map { $0.weight }.max()
    }
}

// MARK: - WeightLog
/// Records the weight used each time a PlannedExercise is performed.
@Model
final class WeightLog {
    var id: UUID
    var weight: Double      // kg
    var loggedAt: Date
    var sessionDate: Date   // date of the workout session
    var repsActual: Int     // actual reps done (may differ from planned)
    var setNumber: Int

    var exercise: PlannedExercise?

    init(weight: Double, repsActual: Int, setNumber: Int, sessionDate: Date = Date()) {
        self.id = UUID()
        self.weight = weight
        self.loggedAt = Date()
        self.sessionDate = sessionDate
        self.repsActual = repsActual
        self.setNumber = setNumber
    }
}

// MARK: - CompletedSession
/// Marks a RoutineDay as done on a specific date.
@Model
final class CompletedSession {
    var id: UUID
    var completedAt: Date
    var routineDay: RoutineDay?
    var routine: Routine?

    init(routineDay: RoutineDay, routine: Routine) {
        self.id = UUID()
        self.completedAt = Date()
        self.routineDay = routineDay
        self.routine = routine
    }
}
