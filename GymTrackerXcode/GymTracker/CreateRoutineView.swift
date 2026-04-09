import SwiftUI
import SwiftData

/// Full flow to create a new Routine: name → weekdays → exercises per day × 12 weeks.
struct CreateRoutineView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // Step 1: basic info
    @State private var routineName: String = ""
    @State private var selectedWeekdays: Set<Int> = []   // 1=Sun … 7=Sat
    @State private var totalWeeks: Int = 12

    // Step 2: define exercises for each weekday
    // [weekdayIndex: [ExerciseDraft]]
    @State private var exerciseDrafts: [Int: [ExerciseDraft]] = [:]

    @State private var step: Int = 1
    @State private var selectedDayForEdit: Int? = nil

    private let weekdays: [(label: String, index: Int)] = [
        ("Dom", 1), ("Lun", 2), ("Mar", 3), ("Mié", 4),
        ("Jue", 5), ("Vie", 6), ("Sáb", 7)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                switch step {
                case 1: stepOne
                case 2: stepTwo
                default: EmptyView()
                }
            }
            .navigationTitle(step == 1 ? "Nueva Rutina" : "Ejercicios")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(step == 1 ? "Cancelar" : "Atrás") {
                        if step == 1 { dismiss() } else { step = 1 }
                    }
                    .foregroundStyle(.gray)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: Step 1 — Name & weekdays
    private var stepOne: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                formSection("Nombre de la rutina") {
                    TextField("Ej: Glúteos & Piernas", text: $routineName)
                        .padding()
                        .background(Color(white: 0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }

                formSection("Duración") {
                    HStack {
                        Text("Semanas:")
                            .foregroundStyle(.gray)
                        Spacer()
                        Stepper("\(totalWeeks)", value: $totalWeeks, in: 1...52)
                            .labelsHidden()
                        Text("\(totalWeeks)")
                            .font(.headline)
                            .foregroundStyle(.orange)
                            .frame(width: 30)
                    }
                    .padding()
                    .background(Color(white: 0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                formSection("Días de entrenamiento") {
                    HStack(spacing: 8) {
                        ForEach(weekdays, id: \.index) { wd in
                            let selected = selectedWeekdays.contains(wd.index)
                            Button {
                                if selected { selectedWeekdays.remove(wd.index) }
                                else { selectedWeekdays.insert(wd.index) }
                            } label: {
                                Text(wd.label)
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selected ? Color.orange : Color(white: 0.15))
                                    .foregroundStyle(selected ? .black : .white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }

                Button {
                    guard !routineName.trimmingCharacters(in: .whitespaces).isEmpty,
                          !selectedWeekdays.isEmpty else { return }
                    // Init exercise drafts for each selected day
                    for wd in selectedWeekdays where exerciseDrafts[wd] == nil {
                        exerciseDrafts[wd] = []
                    }
                    step = 2
                } label: {
                    Text("Siguiente")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canAdvance ? Color.orange : Color.gray.opacity(0.3))
                        .foregroundStyle(canAdvance ? .black : .gray)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canAdvance)
            }
            .padding()
        }
    }

    private var canAdvance: Bool {
        !routineName.trimmingCharacters(in: .whitespaces).isEmpty && !selectedWeekdays.isEmpty
    }

    // MARK: Step 2 — Exercises per weekday
    private var stepTwo: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Define los ejercicios para cada día. Se repetirán en las \(totalWeeks) semanas.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding(.horizontal)

                ForEach(selectedWeekdays.sorted(), id: \.self) { wd in
                    weekdayExerciseSection(wd)
                }

                Button { createRoutine() } label: {
                    Text("Crear Rutina")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .leading, endPoint: .trailing))
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding(.bottom, 40)
        }
        .sheet(item: $selectedDayForEdit) { wd in
            AddExercisesSheet(
                weekdayIndex: wd,
                drafts: Binding(
                    get: { exerciseDrafts[wd.id] ?? [] },
                    set: { exerciseDrafts[wd.id] = $0 }
                )
            )
        }
    }

    private func weekdayExerciseSection(_ wd: Int) -> some View {
        let drafts = exerciseDrafts[wd] ?? []
        let dayName = Calendar.current.weekdaySymbols[wd - 1]
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    selectedDayForEdit = WeekdayID(id: wd)
                } label: {
                    Label(drafts.isEmpty ? "Agregar" : "Editar (\(drafts.count))",
                          systemImage: "pencil.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }

            if drafts.isEmpty {
                Text("Sin ejercicios aún")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.vertical, 6)
            } else {
                ForEach(drafts) { draft in
                    HStack {
                        Text(draft.name)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(draft.sets)×\(draft.reps)")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    // MARK: Save routine
    private func createRoutine() {
        let routine = Routine(
            name: routineName.trimmingCharacters(in: .whitespaces),
            totalWeeks: totalWeeks,
            weekdays: Array(selectedWeekdays)
        )
        context.insert(routine)

        for week in 1...totalWeeks {
            for wd in selectedWeekdays.sorted() {
                let day = RoutineDay(weekNumber: week, weekdayIndex: wd)
                day.routine = routine
                context.insert(day)

                let drafts = exerciseDrafts[wd] ?? []
                for (idx, draft) in drafts.enumerated() {
                    let ex = PlannedExercise(
                        name: draft.name,
                        orderIndex: idx,
                        sets: draft.sets,
                        repsPerSet: draft.reps,
                        restSeconds: draft.rest,
                        notes: draft.notes
                    )
                    ex.routineDay = day
                    context.insert(ex)
                    day.exercises.append(ex)
                }
                routine.days.append(day)
            }
        }

        try? context.save()
        dismiss()
    }

    // MARK: Helper
    private func formSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.gray)
            content()
        }
    }
}

// MARK: - WeekdayID (Identifiable wrapper for sheet)
struct WeekdayID: Identifiable {
    let id: Int
}

// MARK: - ExerciseDraft
struct ExerciseDraft: Identifiable {
    let id: UUID = UUID()
    var name: String
    var sets: Int
    var reps: Int
    var rest: Int
    var notes: String
}

// MARK: - AddExercisesSheet
struct AddExercisesSheet: View {
    @Environment(\.dismiss) private var dismiss
    let weekdayIndex: WeekdayID
    @Binding var drafts: [ExerciseDraft]

    @State private var name: String = ""
    @State private var sets: Int = 3
    @State private var reps: Int = 12
    @State private var rest: Int = 60
    @State private var notes: String = ""
    @State private var editingDraft: ExerciseDraft? = nil

    private var dayName: String {
        let symbols = Calendar.current.weekdaySymbols
        let idx = max(0, min(weekdayIndex.id - 1, symbols.count - 1))
        return symbols[idx]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Existing exercises list
                        if !drafts.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Ejercicios guardados")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.gray)
                                ForEach(drafts) { draft in
                                    draftRow(draft)
                                }
                            }
                            .padding()
                            .background(Color(white: 0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal)
                        }

                        // Add form
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Agregar ejercicio")
                                .font(.subheadline.bold())
                                .foregroundStyle(.gray)

                            TextField("Nombre del ejercicio", text: $name)
                                .padding()
                                .background(Color(white: 0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.white)

                            HStack(spacing: 12) {
                                stepperField(label: "Series", value: $sets, range: 1...20)
                                stepperField(label: "Reps", value: $reps, range: 1...100)
                                stepperField(label: "Descanso (s)", value: $rest, range: 10...300, step: 10)
                            }

                            TextField("Notas (opcional)", text: $notes)
                                .padding()
                                .background(Color(white: 0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.white)

                            Button {
                                guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                let draft = ExerciseDraft(
                                    name: name.trimmingCharacters(in: .whitespaces),
                                    sets: sets, reps: reps, rest: rest, notes: notes)
                                drafts.append(draft)
                                name = ""; notes = ""
                            } label: {
                                Label("Agregar ejercicio", systemImage: "plus.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(name.isEmpty ? Color.gray.opacity(0.3) : Color.orange)
                                    .foregroundStyle(name.isEmpty ? .gray : .black)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding()
                        .background(Color(white: 0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(dayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") { dismiss() }
                        .foregroundStyle(.orange)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func draftRow(_ draft: ExerciseDraft) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(draft.name)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Text("\(draft.sets) series × \(draft.reps) reps · \(draft.rest)s descanso")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            Spacer()
            Button(role: .destructive) {
                drafts.removeAll { $0.id == draft.id }
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red.opacity(0.7))
            }
        }
        .padding(.vertical, 4)
    }

    private func stepperField(label: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int = 1) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.gray)
            HStack(spacing: 8) {
                Button {
                    if value.wrappedValue - step >= range.lowerBound {
                        value.wrappedValue -= step
                    }
                } label: {
                    Image(systemName: "minus.circle")
                        .foregroundStyle(.orange)
                }
                Text("\(value.wrappedValue)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(minWidth: 28)
                Button {
                    if value.wrappedValue + step <= range.upperBound {
                        value.wrappedValue += step
                    }
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.orange)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(white: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
