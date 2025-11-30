import SwiftUI
import Charts

struct MeterDetailView: View {
    let meter: Meter
    @ObservedObject private var firebaseService = FirebaseService.shared
    
    @State private var showingScanner = false
    @State private var showingManualEntry = false
    @State private var scannedText = ""
    @State private var isScanning = false
    @State private var readingToEdit: Reading? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Stats Section with gradient background
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
                
                // Chart Section
                ChartSection(readings: firebaseService.readings)
                
                // History Section
                HistorySection(
                    readings: firebaseService.readings,
                    onEdit: { reading in
                        readingToEdit = reading
                    },
                    onDelete: deleteReading
                )
            }
            .padding(.vertical, 16)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(meter.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingScanner = true
                    } label: {
                        Label(NSLocalizedString("Scan Camera", comment: ""), systemImage: "camera.fill")
                    }
                    Button {
                        readingToEdit = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            showingManualEntry = true
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
        .sheet(isPresented: $showingScanner) {
            ScannerView(scannedText: $scannedText, isScanning: $isScanning)
                .onAppear { isScanning = true }
                .onChange(of: scannedText) { newValue in
                    if let value = Double(newValue.filter("0123456789.".contains)) {
                        saveReading(value: value)
                    }
                    showingScanner = false
                }
        }
        .sheet(item: $readingToEdit) { reading in
            ManualEntryView(meterId: meter.meterNumber, readingToEdit: reading)
        }
        .sheet(isPresented: $showingManualEntry) {
            if readingToEdit == nil {
                ManualEntryView(meterId: meter.meterNumber, readingToEdit: nil)
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
