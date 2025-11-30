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
            VStack(spacing: 20) {
                
                StatsSection(readings: firebaseService.readings)
                
                ChartSection(readings: firebaseService.readings)
                
                HistorySection(
                    readings: firebaseService.readings,
                    onEdit: { reading in
                        readingToEdit = reading
                        showingManualEntry = true
                    },
                    onDelete: deleteReading
                )
            }
            .padding(.vertical)
        }
        .navigationTitle(meter.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showingScanner = true } label: {
                        Label("Scan Camera", systemImage: "camera")
                    }
                    Button {
                        readingToEdit = nil
                        showingManualEntry = true
                    } label: {
                        Label("Manual Entry", systemImage: "keyboard")
                    }
                } label: {
                    Image(systemName: "plus")
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
        .sheet(isPresented: $showingManualEntry) {
            ManualEntryView(meterId: meter.meterNumber, readingToEdit: readingToEdit)
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
        try? firebaseService.addReading(reading)
    }
    
    private func deleteReading(_ reading: Reading) {
        try? firebaseService.deleteReading(reading)
    }
}

