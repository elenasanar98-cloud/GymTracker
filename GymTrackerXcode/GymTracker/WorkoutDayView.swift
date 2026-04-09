import SwiftUI
import SwiftData

/// The active workout screen. Shows all exercises for a given day.
struct WorkoutDayView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let day: RoutineDay
    let routine: Routine

    /// Tracks which exercises have been marked complete this session
    @State private var completedExerciseIDs: Set<UUID> = []
    @State private var showFinishConfirm = false
    @State private var sessionDate: Date = Date()
    @State private var timerSeconds: Int = 0
    @State private var timerRunning = false
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var restCountdown: Int = 0
    @State private var showRestTimer = false

    private var sortedExercises: [PlannedExercise] {
        day.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    private var allDone: Bool {
        !sortedExercises.isEmpty &&
        sortedExercises.allSatisfy { completedExerciseIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Session timer
                        timerHeader

                        // Exercise list
                        ForEach(sortedExercises) { exercise in
                            ExerciseCardView(
                                exercise: exercise,
                                sessionDate: sessionDate,
                                isCompleted: completedExerciseIDs.contains(exercise.id),
                                onComplete: { markComplete(exercise) },
                                onRestTap: { startRest(seconds: exercise.restSeconds) }
                            )
                        }

                        // Finish button
                        if allDone {
                            Button { showFinishConfirm = true } label: {
                                Label("Finalizar entrenamiento", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .leading, endPoint: .trailing))
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, 40)
                }

                // Rest timer overlay
                if showRestTimer {
                    restOverlay
                }
            }
            .navigationTitle(day.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(completedExerciseIDs.count)/\(sortedExercises.count)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear { startSessionTimer() }
            .onDisappear { timerTask?.cancel() }
            .confirmationDialog("¿Finalizar entrenamiento?",
                                isPresented: $showFinishConfirm,
                                titleVisibility: .visible) {
                Button("Finalizar") { finishWorkout() }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Se guardará este día como completado.")
            }
        }
    }

    // MARK: Timer header
    private var timerHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.weekdayName.uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                Text(day.title)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(timerSeconds))
                    .font(.title2.monospacedDigit().bold())
                    .foregroundStyle(.white)
                Text("tiempo")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: Rest timer overlay
    private var restOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Descanso")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 12)
                        .frame(width: 140, height: 140)
                    Circle()
                        .trim(from: 0, to: restCountdown > 0 ? CGFloat(restCountdown) / 180 : 0)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: restCountdown)
                    Text("\(restCountdown)s")
                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                Button("Saltar") {
                    showRestTimer = false
                    timerTask?.cancel()
                }
                .padding(.horizontal, 32).padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .padding(40)
            .background(Color(white: 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(40)
        }
        .transition(.opacity)
    }

    // MARK: Actions
    private func markComplete(_ ex: PlannedExercise) {
        withAnimation { completedExerciseIDs.insert(ex.id) }
    }

    private func startRest(seconds: Int) {
        restCountdown = seconds
        showRestTimer = true
        timerTask?.cancel()
        timerTask = Task {
            while restCountdown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { restCountdown -= 1 }
            }
            await MainActor.run { showRestTimer = false }
        }
    }

    private func startSessionTimer() {
        timerTask?.cancel()
        timerTask = Task {
            while true {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { timerSeconds += 1 }
            }
        }
    }

    private func finishWorkout() {
        timerTask?.cancel()
        // Create completion record
        let session = CompletedSession(routineDay: day, routine: routine)
        context.insert(session)
        try? context.save()
        dismiss()
    }

    private func formatTime(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}
