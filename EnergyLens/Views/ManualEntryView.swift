import SwiftUI

struct ManualEntryView: View {
    @Environment(\.dismiss) var dismiss
    let meterId: String
    var readingToEdit: Reading?
    @State private var value = ""
    @State private var date = Date()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showDeleteConfirmation = false
    @StateObject private var firebaseService = FirebaseService.shared
    
    var isEditing: Bool {
        readingToEdit != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("Reading Details", comment: ""))) {
                    TextField(NSLocalizedString("Value (kWh)", comment: ""), text: $value)
                        .keyboardType(.decimalPad)
                    DatePicker(NSLocalizedString("Date", comment: ""), selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                if showError {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // Delete Button (nur beim Bearbeiten anzeigen)
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label(NSLocalizedString("Delete Reading", comment: ""), systemImage: "trash")
                                    .font(.body)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? NSLocalizedString("Edit Reading", comment: "") : NSLocalizedString("Add Reading", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("Save", comment: "")) {
                        saveReading()
                    }
                    .disabled(value.isEmpty)
                }
            }
            .alert(NSLocalizedString("Delete Reading", comment: ""), isPresented: $showDeleteConfirmation) {
                Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) { }
                Button(NSLocalizedString("Delete", comment: ""), role: .destructive) {
                    deleteReading()
                }
            } message: {
                Text(NSLocalizedString("Are you sure you want to delete this reading? This action cannot be undone.", comment: ""))
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
        guard let doubleValue = Double(value) else {
            showError = true
            errorMessage = NSLocalizedString("Please enter a valid number", comment: "")
            Haptics.shared.play(.error)
            return
        }
        
        guard doubleValue >= 0 else {
            showError = true
            errorMessage = NSLocalizedString("Value must be positive", comment: "")
            Haptics.shared.play(.error)
            return
        }
        
        do {
            if var reading = readingToEdit {
                // Editing existing reading
                reading.value = doubleValue
                reading.date = date
                try firebaseService.updateReading(reading)
            } else {
                // Creating new reading
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
            showError = true
            errorMessage = String(format: NSLocalizedString("Failed to save: %@", comment: ""), error.localizedDescription)
            Haptics.shared.play(.error)
            print("Error saving reading: \(error)")
        }
    }
    
    private func deleteReading() {
        guard let reading = readingToEdit else { return }
        
        do {
            try firebaseService.deleteReading(reading)
            Haptics.shared.play(.success)
            dismiss()
        } catch {
            showError = true
            errorMessage = String(format: NSLocalizedString("Failed to delete: %@", comment: ""), error.localizedDescription)
            Haptics.shared.play(.error)
            print("Error deleting reading: \(error)")
        }
    }
}
