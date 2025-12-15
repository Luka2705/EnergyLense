import SwiftUI
import Charts
import Combine

private final class MeterDetailViewModel: ObservableObject {
    @Published var showingScanner = false
    @Published var showingManualEntry = false
    @Published var scannedText = ""
    @Published var isScanning = false
    @Published var readingToEdit: Reading? = nil
}

struct MeterDetailView: View {
    let meter: Meter
    @ObservedObject private var firebaseService = FirebaseService.shared
    @StateObject private var viewModel = MeterDetailViewModel()
    
    var body: some View {
        ScrollView {
            content
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(meter.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        viewModel.showingScanner = true
                    } label: {
                        Label(NSLocalizedString("Scan Camera", comment: ""), systemImage: "camera.fill")
                    }
                    Button {
                        viewModel.readingToEdit = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            viewModel.showingManualEntry = true
                        }
                    } label: {
                        Label(NSLocalizedString("Manual Entry", comment: ""), systemImage: "keyboard")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                }
            }
        }
        .sheet(isPresented: $viewModel.showingScanner) {
            ScannerView(scannedText: $viewModel.scannedText, isScanning: $viewModel.isScanning)
                .onAppear { viewModel.isScanning = true }
                .onChange(of: viewModel.scannedText) {
                    if let value = Double(viewModel.scannedText.filter("0123456789.".contains)) {
                        saveReading(value: value)
                    }
                    viewModel.showingScanner = false
                }
        }
        .sheet(item: $viewModel.readingToEdit) { reading in
            ManualEntryView(meterId: meter.meterNumber, readingToEdit: reading)
        }
        .sheet(isPresented: $viewModel.showingManualEntry) {
            if viewModel.readingToEdit == nil {
                ManualEntryView(meterId: meter.meterNumber, readingToEdit: nil)
            }
        }
        .onAppear {
            firebaseService.listenToReadings(for: meter.meterNumber)
        }
    }
    
    private var content: some View {
        VStack(spacing: 24) {
            VStack(spacing: 0) {
                StatsSection(readings: firebaseService.readings)
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 0.95, green: 0.97, blue: 1.0), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal)

            ChartSection(readings: firebaseService.readings)

            HistorySection(
                readings: firebaseService.readings,
                onEdit: { reading in
                    viewModel.readingToEdit = reading
                },
                onDelete: deleteReading
            )
        }
        .padding(.vertical, 16)
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

