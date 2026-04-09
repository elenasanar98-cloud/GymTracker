import SwiftUI
import SwiftData

/// Shows all days grouped by week; auto-navigates to the next pending day.
struct RoutineDetailView: View {
    @Environment(\.modelContext) private var context
    let routine: Routine

    @State private var activeDay: RoutineDay?
    @State private var showActiveWorkout = false

    private var groupedDays: [(week: Int, days: [RoutineDay])] {
        let sorted = routine.days.sorted {
            if $0.weekNumber != $1.weekNumber { return $0.weekNumber < $1.weekNumber }
            return $0.weekdayIndex < $1.weekdayIndex
        }
        var result: [(week: Int, days: [RoutineDay])] = []
        var current: (week: Int, days: [RoutineDay])? = nil
        for day in sorted {
            if current?.week == day.weekNumber {
                current!.days.append(day)
            } else {
                if let c = current { result.append(c) }
                current = (week: day.weekNumber, days: [day])
            }
        }
        if let c = current { result.append(c) }
        return result
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header card
                    headerCard
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Start next day button
                    if let next = routine.nextDay() {
                        Button {
                            activeDay = next
                            showActiveWorkout = true
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Empezar \(next.title)")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .leading, endPoint: .trailing))
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    } else if routine.isCompleted {
                        completedBanner
                            .padding(.horizontal)
                            .padding(.top, 16)
                    }

                    // Week list
                    ForEach(groupedDays, id: \.week) { group in
                        weekSection(group)
                    }
                    .padding(.top, 20)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showActiveWorkout) {
            if let day = activeDay {
                WorkoutDayView(day: day, routine: routine)
            }
        }
    }

    // MARK: Header card
    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack {
                statBox(value: "\(routine.totalWeeks)", label: "Semanas")
                statBox(value: "\(routine.weekdays.count)", label: "Días/sem")
                statBox(value: "\(routine.completedSessions.count)", label: "Hechos")
                statBox(value: "\(routine.days.count)", label: "Total")
            }
            ProgressBar(value: routine.days.isEmpty ? 0 :
                Double(routine.completedSessions.count) / Double(routine.days.count))
            Text("\(routine.completedSessions.count) de \(routine.days.count) entrenamientos completados")
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .padding(16)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.orange)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    private var completedBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "trophy.fill").foregroundStyle(.yellow)
            VStack(alignment: .leading) {
                Text("¡Rutina completada!")
                    .font(.headline).foregroundStyle(.white)
                Text("Has terminado las \(routine.totalWeeks) semanas")
                    .font(.caption).foregroundStyle(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Week section
    private func weekSection(_ group: (week: Int, days: [RoutineDay])) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Semana \(group.week)")
                .font(.subheadline.bold())
                .foregroundStyle(.gray)
                .padding(.horizontal)

            VStack(spacing: 6) {
                ForEach(group.days) { day in
                    dayRow(day)
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 16)
    }

    private func dayRow(_ day: RoutineDay) -> some View {
        let isNext = routine.nextDay()?.id == day.id
        let isDone = day.isCompleted

        return Button {
            activeDay = day
            showActiveWorkout = true
        } label: {
            HStack {
                Circle()
                    .fill(isDone ? Color.green : (isNext ? Color.orange : Color.white.opacity(0.15)))
                    .frame(width: 10, height: 10)

                Text(day.weekdayName)
                    .font(.subheadline)
                    .foregroundStyle(isDone ? .gray : .white)
                    .strikethrough(isDone, color: .gray)

                Spacer()

                Text("\(day.exercises.count) ejercicios")
                    .font(.caption)
                    .foregroundStyle(.gray)

                if isNext {
                    Text("HOY")
                        .font(.caption2.bold())
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(.orange)
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                }

                if isDone {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(12)
            .background(Color(white: 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isNext ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
