import SwiftUI

struct DashboardView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var showingAddMeter = false
    @State private var newMeterNumber = ""
    @State private var newMeterName = ""
    @State private var meterToEdit: Meter? = nil
    @State private var meterToDelete: Meter? = nil
    @State private var editMeterName = ""
    @State private var editMeterNumber = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Abstand nach Titel
                    Color.clear.frame(height: 16)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            if firebaseService.meters.isEmpty {
                                // Empty State
                                VStack(spacing: 20) {
                                    Spacer()
                                    Image(systemName: "bolt.circle.fill")
                                        .font(.system(size: 70))
                                        .foregroundStyle(.blue)
                                    Text(NSLocalizedString("No Meters Yet", comment: ""))
                                        .font(.title2)
                                        .bold()
                                    Text(NSLocalizedString("Tap the button below to add your first electricity meter.", comment: ""))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 400)
                            } else {
                                ForEach(firebaseService.meters) { meter in
                                    NavigationLink(destination: MeterDetailView(meter: meter)) {
                                        HStack(spacing: 16) {
                                            // Icon
                                            ZStack {
                                                Circle()
                                                    .fill(Color.blue.opacity(0.1))
                                                    .frame(width: 50, height: 50)
                                                Image(systemName: "bolt.fill")
                                                    .font(.system(size: 22))
                                                    .foregroundColor(.blue)
                                            }
                                            
                                            // Text Content
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(meter.name)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                Text(String(format: NSLocalizedString("Meter #: %@", comment: ""), meter.meterNumber))
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            // Chevron
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.secondary.opacity(0.5))
                                        }
                                        .padding(16)
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button {
                                            meterToEdit = meter
                                        } label: {
                                            Label(NSLocalizedString("Edit", comment: ""), systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive) {
                                            meterToDelete = meter
                                        } label: {
                                            Label(NSLocalizedString("Delete", comment: ""), systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100) // Platz für Button
                    }
                }
                .background(Color(UIColor.systemGroupedBackground))
                .navigationTitle(NSLocalizedString("EnergyLens", comment: ""))
                .toolbar {
                }
                
                // Add Meter Button (Fixed at bottom)
                VStack {
                    Spacer()
                    Button(action: {
                        Haptics.shared.play(.light)
                        showingAddMeter = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                            Text(NSLocalizedString("Add Meter", comment: ""))
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .sheet(isPresented: $showingAddMeter) {
                NavigationView {
                    Form {
                        Section(header: Text(NSLocalizedString("New Meter Details", comment: ""))) {
                            TextField(NSLocalizedString("Meter Name (e.g. Home)", comment: ""), text: $newMeterName)
                            TextField(NSLocalizedString("Meter Number", comment: ""), text: $newMeterNumber)
                                .keyboardType(.numberPad)
                        }
                    }
                    .navigationTitle(NSLocalizedString("Add Meter", comment: ""))
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(NSLocalizedString("Cancel", comment: "")) {
                                showingAddMeter = false
                                newMeterName = ""
                                newMeterNumber = ""
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(NSLocalizedString("Save", comment: "")) {
                                addMeter()
                            }
                            .disabled(newMeterNumber.isEmpty || newMeterName.isEmpty)
                        }
                    }
                }
            }
            .sheet(item: $meterToEdit) { meter in
                NavigationView {
                    Form {
                        Section(header: Text(NSLocalizedString("Edit Meter Details", comment: ""))) {
                            TextField(NSLocalizedString("Meter Name", comment: ""), text: $editMeterName)
                            TextField(NSLocalizedString("Meter Number", comment: ""), text: $editMeterNumber)
                                .keyboardType(.numberPad)
                        }
                    }
                    .navigationTitle(NSLocalizedString("Edit Meter", comment: ""))
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(NSLocalizedString("Cancel", comment: "")) {
                                meterToEdit = nil
                                editMeterName = ""
                                editMeterNumber = ""
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(NSLocalizedString("Save", comment: "")) {
                                updateMeter(meter)
                            }
                            .disabled(editMeterNumber.isEmpty || editMeterName.isEmpty)
                        }
                    }
                    .onAppear {
                        editMeterName = meter.name
                        editMeterNumber = meter.meterNumber
                    }
                }
            }
            .alert(NSLocalizedString("Delete Meter", comment: ""), isPresented: Binding(
                get: { meterToDelete != nil },
                set: { if !$0 { meterToDelete = nil } }
            )) {
                Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {
                    meterToDelete = nil
                }
                Button(NSLocalizedString("Delete", comment: ""), role: .destructive) {
                    if let meter = meterToDelete {
                        deleteMeter(meter)
                    }
                }
            } message: {
                Text(NSLocalizedString("Are you sure you want to delete this meter? All readings associated with this meter will also be deleted. This action cannot be undone.", comment: ""))
            }
            .onAppear {
                firebaseService.listenToMeters()
            }
        }
    }
    
    private func addMeter() {
        let newMeter = Meter(name: newMeterName, meterNumber: newMeterNumber, createdAt: Date())
        do {
            try firebaseService.addMeter(newMeter)
            Haptics.shared.play(.success)
            showingAddMeter = false
            newMeterName = ""
            newMeterNumber = ""
        } catch {
            Haptics.shared.play(.error)
            print("Error adding meter: \(error)")
        }
    }
    
    private func updateMeter(_ meter: Meter) {
        do {
            try firebaseService.updateMeter(
                oldMeterNumber: meter.meterNumber,
                newName: editMeterName,
                newMeterNumber: editMeterNumber
            )
            Haptics.shared.play(.success)
            meterToEdit = nil
            editMeterName = ""
            editMeterNumber = ""
        } catch {
            Haptics.shared.play(.error)
            print("Error updating meter: \(error)")
        }
    }
    
    private func deleteMeter(_ meter: Meter) {
        do {
            try firebaseService.deleteMeter(meter)
            Haptics.shared.play(.success)
            meterToDelete = nil
        } catch {
            Haptics.shared.play(.error)
            print("Error deleting meter: \(error)")
        }
    }
}

#Preview {
    DashboardView()
}
