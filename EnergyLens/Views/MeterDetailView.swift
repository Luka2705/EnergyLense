import SwiftUI
import Charts
import Combine

private enum ActiveSheet: Identifiable {
    case scanner
    case manualEntry
    case editReading(Reading)
    case rename

    var id: String {
        switch self {
        case .scanner: return "scanner"
        case .manualEntry: return "manualEntry"
        case .editReading(let r):
            let suffix = r.id ?? "unknown"
            return "editReading_\(suffix)"
        case .rename: return "rename"
        }
    }
}

private final class MeterDetailViewModel: ObservableObject {
    @Published var scannedText = ""
    @Published var isScanning = false
    @Published var readingToEdit: Reading? = nil
    @Published var editedName: String = ""
    @Published var editedNumber: String = ""
    @Published var activeSheet: ActiveSheet? = nil
}

struct MeterDetailView: View {
    let meter: Meter
    @ObservedObject private var firebaseService = FirebaseService.shared
    @StateObject private var viewModel = MeterDetailViewModel()
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Hero Header
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.35), Color.cyan.opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(meter.name)
                                .font(.largeTitle.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Spacer()
                            Label("\(meter.meterNumber)", systemImage: "gauge.medium")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                        Text(NSLocalizedString("Live energy insights", comment: ""))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.editedName = meter.name
                        viewModel.editedNumber = meter.meterNumber
                        viewModel.activeSheet = .rename
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .padding(.horizontal)

                // Stats Card
                VStack(spacing: 0) {
                    StatsSection(readings: firebaseService.readings)
                }
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
                .padding(.horizontal)

                // Chart Card
                VStack(spacing: 0) {
                    ChartSection(readings: firebaseService.readings)
                }
                .padding(6)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
                .padding(.horizontal)

                // History Card
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Label(NSLocalizedString("History", comment: ""), systemImage: "clock.arrow.circlepath")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(String(format: NSLocalizedString("%d entries", comment: ""), firebaseService.readings.count))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                    Divider().opacity(0.2)

                    // Table Header Row
                    HStack(spacing: 12) {
                        Text(NSLocalizedString("Date", comment: ""))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)
                        Text(NSLocalizedString("Value", comment: ""))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .trailing)
                        Text(NSLocalizedString("Δ", comment: ""))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                        Text("")
                            .frame(width: 70)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)

                    // Rows
                    VStack(spacing: 8) {
                        ForEach(Array(firebaseService.readings.enumerated()), id: \.element.id) { index, reading in
                            let previous = index + 1 < firebaseService.readings.count ? firebaseService.readings[index + 1] : nil
                            let delta = previous.map { reading.value - $0.value }

                            HStack(spacing: 12) {
                                // Date
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(reading.date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year(.twoDigits)))
                                        .font(.footnote.weight(.medium))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Text(reading.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)
                                Spacer()
                                // Value
                                Text("\(Int(reading.value.rounded())) kWh")
                                    .font(.footnote.monospacedDigit())
                                    .foregroundStyle(.primary)
                                    .frame(width: 80, alignment: .trailing)
                                // Delta
                                Group {
                                    if let delta = delta {
                                        let intDelta = Int(delta.rounded())
                                        let sign = intDelta >= 0 ? "+" : ""
                                        Text("\(sign)\(intDelta)")
                                            .font(.footnote.monospacedDigit())
                                            .foregroundStyle(intDelta >= 0 ? .green : .red)
                                    } else {
                                        Text("–").foregroundStyle(.secondary)
                                    }
                                }
                                .frame(width: 60, alignment: .trailing)

                                // Actions
                                HStack(spacing: 8) {
                                    Button {
                                        viewModel.activeSheet = .editReading(reading)
                                    } label: {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .buttonStyle(.borderless)

                                    Menu {
                                        Button(role: .destructive) {
                                            deleteReading(reading)
                                        } label: {
                                            Label(NSLocalizedString("Delete", comment: ""), systemImage: "trash")
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis")
                                            .rotationEffect(.degrees(90))
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .menuStyle(.automatic)
                                }
                                .frame(width: 70, alignment: .trailing)
                            }
                            .padding(10)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }

                        if firebaseService.readings.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "tray")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.secondary)
                                Text(NSLocalizedString("No readings yet", comment: ""))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(NSLocalizedString("Add your first reading to see history here.", comment: ""))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(24)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }
                    }
                    .padding(12)
                }
                .padding(6)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
                .padding(.horizontal)
            }
            .padding(.vertical, 16)
        }
        .background(
            LinearGradient(
                colors: [Color(UIColor.systemGroupedBackground), Color(UIColor.secondarySystemGroupedBackground)],
                startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .navigationTitle(meter.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        viewModel.editedName = meter.name
                        viewModel.editedNumber = meter.meterNumber
                        viewModel.activeSheet = .rename
                    } label: {
                        Label(NSLocalizedString("Rename Meter", comment: ""), systemImage: "pencil")
                    }
                    Button {
                        viewModel.activeSheet = .scanner
                    } label: {
                        Label(NSLocalizedString("Scan Camera", comment: ""), systemImage: "camera.fill")
                    }
                    Button {
                        viewModel.activeSheet = .manualEntry
                    } label: {
                        Label(NSLocalizedString("Manual Entry", comment: ""), systemImage: "keyboard")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue)
                        .font(.system(size: 22, weight: .semibold))
                }
            }
        }
        .sheet(item: $viewModel.activeSheet) { sheet in
            switch sheet {
            case .scanner:
                ScannerView(scannedText: $viewModel.scannedText, isScanning: $viewModel.isScanning)
                    .onAppear { viewModel.isScanning = true }
                    .onChange(of: viewModel.scannedText) {
                        if let value = Double(viewModel.scannedText.filter("0123456789.".contains)) {
                            saveReading(value: value)
                        }
                        viewModel.activeSheet = nil
                    }
            case .manualEntry:
                ManualEntryView(meterId: meter.meterNumber, readingToEdit: nil)
            case .editReading(let reading):
                ManualEntryView(meterId: meter.meterNumber, readingToEdit: reading)
            case .rename:
                NavigationView {
                    Form {
                        Section(header: Text(NSLocalizedString("Rename Meter", comment: ""))) {
                            TextField(NSLocalizedString("Meter Name", comment: ""), text: $viewModel.editedName)
                                .textInputAutocapitalization(.words)
                            TextField(NSLocalizedString("Meter Number", comment: ""), text: $viewModel.editedNumber)
                                .keyboardType(.numberPad)
                        }
                    }
                    .navigationTitle(NSLocalizedString("Rename", comment: ""))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(NSLocalizedString("Cancel", comment: "")) {
                                viewModel.activeSheet = nil
                                viewModel.editedName = ""
                                viewModel.editedNumber = ""
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(NSLocalizedString("Save", comment: "")) {
                                let newName = viewModel.editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                                let newNumber = viewModel.editedNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !newName.isEmpty, !newNumber.isEmpty else { return }
                                do {
                                    try FirebaseService.shared.updateMeter(
                                        oldMeterNumber: meter.meterNumber,
                                        newName: newName,
                                        newMeterNumber: newNumber
                                    )
                                    Haptics.shared.play(.success)
                                    viewModel.activeSheet = nil
                                } catch {
                                    Haptics.shared.play(.error)
                                }
                            }
                            .disabled(viewModel.editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.editedNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
        }
        .onAppear {
            firebaseService.listenToReadings(for: meter.meterNumber)
        }
    }
}

// MARK: - Save / Delete

extension MeterDetailView {
    
    private func saveReading(value: Double) {
        let reading = Reading(meterId: meter.meterNumber, value: value, date: .now)
        do {
            try firebaseService.addReading(reading)
            Haptics.shared.play(.success)
        } catch {
            Haptics.shared.play(.error)
        }
    }
    
    private func deleteReading(_ reading: Reading) {
        do {
            try firebaseService.deleteReading(reading)
            Haptics.shared.play(.success)
        } catch {
            Haptics.shared.play(.error)
        }
    }
}

