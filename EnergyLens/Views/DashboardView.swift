import SwiftUI

struct DashboardView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var showingAddMeter = false
    @State private var newMeterNumber = ""
    @State private var newMeterName = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(firebaseService.meters) { meter in
                    NavigationLink(destination: MeterDetailView(meter: meter)) {
                        VStack(alignment: .leading) {
                            Text(meter.name)
                                .font(.headline)
                            Text("Meter #: \(meter.meterNumber)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .overlay {
                if firebaseService.meters.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bolt.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No Meters Yet")
                            .font(.title2)
                            .bold()
                        Text("Tap + to add your first electricity meter.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("EnergyLens")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMeter = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMeter) {
                NavigationView {
                    Form {
                        Section(header: Text("New Meter Details")) {
                            TextField("Meter Name (e.g. Home)", text: $newMeterName)
                            TextField("Meter Number", text: $newMeterNumber)
                                .keyboardType(.numberPad)
                        }
                    }
                    .navigationTitle("Add Meter")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingAddMeter = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                addMeter()
                            }
                            .disabled(newMeterNumber.isEmpty || newMeterName.isEmpty)
                        }
                    }
                }
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
            showingAddMeter = false
            newMeterName = ""
            newMeterNumber = ""
        } catch {
            print("Error adding meter: \(error)")
        }
    }
}

#Preview {
    DashboardView()
}
