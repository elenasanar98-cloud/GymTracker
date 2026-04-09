import SwiftUI
import SwiftData

struct RoutineListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]

    @State private var showCreate = false
    @State private var routineToDelete: Routine?
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if routines.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(routines) { routine in
                                NavigationLink(value: routine) {
                                    RoutineCard(routine: routine)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        routineToDelete = routine
                                        showDeleteConfirm = true
                                    } label: {
                                        Label("Eliminar rutina", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Mis Rutinas")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreate = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationDestination(for: Routine.self) { routine in
                RoutineDetailView(routine: routine)
            }
            .sheet(isPresented: $showCreate) {
                CreateRoutineView()
            }
            .confirmationDialog("¿Eliminar \"\(routineToDelete?.name ?? "")\"?",
                                isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Eliminar", role: .destructive) {
                    if let r = routineToDelete {
                        context.delete(r)
                        try? context.save()
                    }
                }
            } message: {
                Text("Se perderán todos los registros de progreso.")
            }
            .preferredColorScheme(.dark)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange.opacity(0.7))
            Text("Sin rutinas aún")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Pulsa + para crear tu primera rutina")
                .font(.subheadline)
                .foregroundStyle(.gray)
            Button {
                showCreate = true
            } label: {
                Label("Crear rutina", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.orange)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Routine Card
struct RoutineCard: View {
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(routine.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if routine.isCompleted {
                    Label("Completada", systemImage: "checkmark.seal.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                } else {
                    Text(routine.progressDescription)
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            // Weekday pills
            HStack(spacing: 6) {
                ForEach(routine.weekdays, id: \.self) { wd in
                    Text(shortWeekday(wd))
                        .font(.caption2.bold())
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.1))
                        .foregroundStyle(.white.opacity(0.8))
                        .clipShape(Capsule())
                }
            }

            // Progress bar
            ProgressBar(value: progressFraction(routine))

            if let next = routine.nextDay() {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Próximo: \(next.title)")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding(16)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    private func shortWeekday(_ index: Int) -> String {
        let symbols = Calendar.current.shortWeekdaySymbols
        let idx = max(0, min(index - 1, symbols.count - 1))
        return symbols[idx].prefix(3).uppercased()
    }

    private func progressFraction(_ r: Routine) -> Double {
        guard r.days.count > 0 else { return 0 }
        return Double(r.completedSessions.count) / Double(r.days.count)
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let value: Double  // 0.0 – 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * max(0, min(value, 1)), height: 6)
                    .animation(.easeInOut, value: value)
            }
        }
        .frame(height: 6)
    }
}
