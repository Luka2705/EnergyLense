import SwiftUI

struct ManualEntryView: View {
    @Environment(\.dismiss) var dismiss
    let meterId: String
    var readingToEdit: Reading?
    @State private var value = ""
    @State private var date = Date()
    @StateObject private var firebaseService = FirebaseService.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reading Details")) {
                    TextField("Value (kWh)", text: $value)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle(readingToEdit == nil ? "Add Reading" : "Edit Reading")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReading()
                    }
                    .disabled(value.isEmpty)
                }
            }
        }
        .onAppear {
            if let reading = readingToEdit {
                value = String(reading.value)
                date = reading.date
            }
        }
    }
    
    private func saveReading() {
        guard let doubleValue = Double(value) else { return }
        
        do {
            if var reading = readingToEdit {
                reading.value = doubleValue
                reading.date = date
                try firebaseService.updateReading(reading)
            } else {
                let reading = Reading(
                    meterId: meterId,
                    value: doubleValue,
                    date: date
                )
                try firebaseService.addReading(reading)
            }
            Haptics.shared.play(.success)
            dismiss()
        } catch {
            Haptics.shared.play(.error)
            print("Error saving reading: \(error)")
        }
    }
}
