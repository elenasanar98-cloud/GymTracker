import SwiftUI
import SwiftData

/// Card for a single exercise inside WorkoutDayView.
/// Shows sets/reps/rest, weight log inputs per set, and last/RM weight.
struct ExerciseCardView: View {
    @Environment(\.modelContext) private var context

    let exercise: PlannedExercise
    let sessionDate: Date
    let isCompleted: Bool
    let onComplete: () -> Void
    let onRestTap: () -> Void

    /// One entry per set: the user-typed weight (as String for TextField)
    @State private var setWeights: [String] = []
    @State private var setReps: [String] = []
    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerRow
                .padding()

            if isExpanded {
                Divider().background(Color.white.opacity(0.08))

                // Previous weight hint
                if let last = exercise.lastWeight {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Text("Última sesión: \(last.formatted(.number.precision(.fractionLength(1)))) kg")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Spacer()
                        if let rm = exercise.rm {
                            Text("RM: \(rm.formatted(.number.precision(.fractionLength(1)))) kg")
                                .font(.caption.bold())
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.06))
                }

                // Set rows
                VStack(spacing: 8) {
                    setHeaderRow
                    ForEach(0..<exercise.sets, id: \.self) { i in
                        setRow(index: i)
                    }
                }
                .padding()

                // Rest & done buttons
                HStack(spacing: 12) {
                    Button {
                        onRestTap()
                        saveAllWeights()
                    } label: {
                        Label("\(exercise.restSeconds)s descanso", systemImage: "timer")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.07))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Button {
                        saveAllWeights()
                        onComplete()
                    } label: {
                        Label(isCompleted ? "Hecho" : "Completar",
                              systemImage: isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isCompleted ? Color.green : Color.orange)
                            .foregroundStyle(isCompleted ? .white : .black)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(isCompleted)
                }
                .padding([.horizontal, .bottom])
            }
        }
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCompleted ? Color.green.opacity(0.4) : Color.white.opacity(0.07), lineWidth: 1)
        )
        .padding(.horizontal)
        .onAppear { initWeightState() }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    // MARK: Header
    private var headerRow: some View {
        HStack {
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(isCompleted ? .gray : .white)
                HStack(spacing: 12) {
                    pill("\(exercise.sets) series", icon: "repeat")
                    pill("\(exercise.repsPerSet) reps", icon: "figure.strengthtraining.traditional")
                    pill("\(exercise.restSeconds)s", icon: "timer")
                }
            }
            Spacer()
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.gray)
                    .frame(width: 30, height: 30)
            }
        }
    }

    private func pill(_ text: String, icon: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .foregroundStyle(.gray)
    }

    // MARK: Set rows
    private var setHeaderRow: some View {
        HStack {
            Text("Serie")
                .frame(width: 40, alignment: .leading)
            Text("Reps")
                .frame(maxWidth: .infinity, alignment: .center)
            Text("Peso (kg)")
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .font(.caption.bold())
        .foregroundStyle(.gray)
    }

    private func setRow(index: Int) -> some View {
        HStack(spacing: 8) {
            // Set number
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 28, height: 28)
                Text("\(index + 1)")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }

            // Reps field — safe subscript binding
            TextField(String(exercise.repsPerSet), text: safeBinding($setReps, index: index))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .padding(8)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(maxWidth: .infinity)
                .foregroundStyle(.white)

            // Weight field
            TextField(lastWeightHint, text: safeBinding($setWeights, index: index))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .padding(8)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(maxWidth: .infinity)
                .foregroundStyle(.white)
        }
    }

    // MARK: Helpers

    /// Creates a safe Binding<String> for an array @State at a given index.
    /// The array is guaranteed to be the right size after initWeightState().
    private func safeBinding(_ binding: Binding<[String]>, index: Int) -> Binding<String> {
        Binding(
            get: { binding.wrappedValue[safe: index] ?? "" },
            set: { newVal in
                if binding.wrappedValue.count > index {
                    binding.wrappedValue[index] = newVal
                }
            }
        )
    }

    private var lastWeightHint: String {
        if let w = exercise.lastWeight {
            return "\(w.formatted(.number.precision(.fractionLength(1))))"
        }
        return "0.0"
    }

    private func initWeightState() {
        // Prefill with last known weight
        let hint = exercise.lastWeight.map { "\($0.formatted(.number.precision(.fractionLength(1))))" } ?? ""
        setWeights = Array(repeating: hint, count: exercise.sets)
        setReps = Array(repeating: "\(exercise.repsPerSet)", count: exercise.sets)
    }

    private func saveAllWeights() {
        for i in 0..<exercise.sets {
            let weightStr = setWeights[safe: i] ?? ""
            let repsStr = setReps[safe: i] ?? ""
            guard let weight = Double(weightStr.replacingOccurrences(of: ",", with: ".")),
                  weight > 0 else { continue }
            let reps = Int(repsStr) ?? exercise.repsPerSet
            let log = WeightLog(weight: weight, repsActual: reps,
                                setNumber: i + 1, sessionDate: sessionDate)
            log.exercise = exercise
            exercise.weightLogs.append(log)
            context.insert(log)
        }
        try? c