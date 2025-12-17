import SwiftUI

struct DashboardView: View {

    // MARK: - State

    @StateObject private var firebaseService = FirebaseService.shared
    @State private var showingAddMeter = false

    @State private var newMeterNumber = ""
    @State private var newMeterName = ""

    @State private var meterToEdit: Meter?
    @State private var meterToDelete: Meter?

    @State private var editMeterName = ""
    @State private var editMeterNumber = ""

    // MARK: - Helpers

    private func colorForMeter(_ meter: Meter) -> LinearGradient {
        let base = abs(meter.meterNumber.hashValue)
        let hue1 = Double(base % 360) / 360.0
        let hue2 = Double((base / 7) % 360) / 360.0

        return LinearGradient(
            colors: [
                Color(hue: hue1, saturation: 0.5, brightness: 1.0),
                Color(hue: hue2, saturation: 0.45, brightness: 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var deleteAlertIsPresented: Binding<Bool> {
        Binding(
            get: { meterToDelete != nil },
            set: { if !$0 { meterToDelete = nil } }
        )
    }

    // MARK: - Animated Background

    private var animatedBackground: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let offset1 = CGFloat(sin(t / 5)) * 40
            let offset2 = CGFloat(cos(t / 6)) * -30

            ZStack {
                LinearGradient(
                    colors: [
                        Color(.sRGB, red: 0.85, green: 0.94, blue: 0.98, opacity: 1),
                        Color(.sRGB, red: 0.78, green: 0.90, blue: 0.98, opacity: 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.35), Color.mint.opacity(0.25)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(x: -120 + offset1, y: -140 + offset2)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.30), Color.purple.opacity(0.22)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 360, height: 360)
                    .blur(radius: 90)
                    .offset(x: 160 - offset2, y: 220 - offset1)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                animatedBackground

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        header

                        if firebaseService.meters.isEmpty {
                            emptyState
                        } else {
                            meterList
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.vertical, 16)
                }

                addButton
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("EnergyLens")
                        .font(.headline)
                }
            }
            .sheet(isPresented: $showingAddMeter) {
                addMeterSheet
            }
            .sheet(item: $meterToEdit) { meter in
                editMeterSheet(meter)
            }
            .alert(
                NSLocalizedString("Delete Meter", comment: ""),
                isPresented: deleteAlertIsPresented
            ) {
                Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {}
                Button(NSLocalizedString("Delete", comment: ""), role: .destructive) {
                    if let meter = meterToDelete {
                        deleteMeter(meter)
                    }
                }
            } message: {
                Text(NSLocalizedString(
                    "Are you sure you want to delete this meter? This action cannot be undone.",
                    comment: ""
                ))
            }
            .onAppear {
                firebaseService.listenToMeters()
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.mint.opacity(0.45), Color.cyan.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.white)
                    Text("EnergyLens")
                        .font(.largeTitle.weight(.semibold))
                    Spacer()
                }

                Text(NSLocalizedString("Manage your meters and track consumption.", comment: ""))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
        }
        .padding(.horizontal)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.cyan)

            Text(NSLocalizedString("No Meters Yet", comment: ""))
                .font(.title3.bold())

            Text(NSLocalizedString(
                "Tap the button below to add your first electricity meter.",
                comment: ""
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(24)
    }

    private var meterList: some View {
        VStack(spacing: 12) {
            ForEach(firebaseService.meters) { meter in
                MeterRow(
                    meter: meter,
                    gradient: colorForMeter(meter),
                    isEditing: meterToEdit?.meterNumber == meter.meterNumber,
                    onEdit: { meterToEdit = meter },
                    onDelete: { meterToDelete = meter }
                )
            }
        }
        .padding(.horizontal)
    }

    private var addButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    showingAddMeter = true
                } label: {
                    Label("Add Meter", systemImage: "plus")
                        .padding()
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [.cyan, .blue, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        )
                        .foregroundStyle(.white)
                }
                .padding()
            }
        }
    }

    // MARK: - Sheets

    private var addMeterSheet: some View {
        NavigationStack {
            Form {
                TextField("Meter Name", text: $newMeterName)
                TextField("Meter Number", text: $newMeterNumber)
            }
            .navigationTitle("Add Meter")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { addMeter() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddMeter = false }
                }
            }
        }
    }

    private func editMeterSheet(_ meter: Meter) -> some View {
        NavigationStack {
            Form {
                TextField("Meter Name", text: $editMeterName)
                TextField("Meter Number", text: $editMeterNumber)
            }
            .navigationTitle("Edit Meter")
            .onAppear {
                editMeterName = meter.name
                editMeterNumber = meter.meterNumber
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { updateMeter(meter) }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { meterToEdit = nil }
                }
            }
        }
    }

    // MARK: - Actions

    private func addMeter() {
        try? firebaseService.addMeter(
            Meter(name: newMeterName, meterNumber: newMeterNumber, createdAt: Date())
        )
        showingAddMeter = false
        newMeterName = ""
        newMeterNumber = ""
    }

    private func updateMeter(_ meter: Meter) {
        try? firebaseService.updateMeter(
            oldMeterNumber: meter.meterNumber,
            newName: editMeterName,
            newMeterNumber: editMeterNumber
        )
        meterToEdit = nil
    }

    private func deleteMeter(_ meter: Meter) {
        try? firebaseService.deleteMeter(meter)
        meterToDelete = nil
    }
}

// MARK: - MeterRow

private struct MeterRow: View {
    let meter: Meter
    let gradient: LinearGradient
    let isEditing: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        NavigationLink(destination: MeterDetailView(meter: meter)) {
            HStack {
                Text(meter.name)
                Spacer()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(gradient.opacity(0.2)))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Edit", action: onEdit)
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}

#Preview {
    DashboardView()
}
