import Foundation
import Combine
import FirebaseFirestore

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    @Published var meters: [Meter] = []
    @Published var readings: [Reading] = []
    
    private init() {}
    
    // MARK: - Meters
    
    func addMeter(_ meter: Meter) throws {
        try db.collection("meters").document(meter.meterNumber).setData(from: meter)
    }
    
    func updateMeter(oldMeterNumber: String, newName: String, newMeterNumber: String) throws {
        let batch = db.batch()
        
        // Wenn sich die Meter-Nummer geändert hat
        if oldMeterNumber != newMeterNumber {
            // 1. Hole das alte Meter-Dokument
            let oldMeterRef = db.collection("meters").document(oldMeterNumber)
            
            // 2. Erstelle neues Meter-Dokument mit neuer ID
            let newMeterRef = db.collection("meters").document(newMeterNumber)
            let updatedMeter = Meter(name: newName, meterNumber: newMeterNumber, createdAt: Date())
            try batch.setData(from: updatedMeter, forDocument: newMeterRef)
            
            // 3. Lösche altes Meter-Dokument
            batch.deleteDocument(oldMeterRef)
            
            // 4. Update alle zugehörigen Readings
            db.collection("readings")
                .whereField("meterId", isEqualTo: oldMeterNumber)
                .getDocuments { [weak self] snapshot, error in
                    guard let documents = snapshot?.documents else { return }
                    
                    let updateBatch = self?.db.batch()
                    for document in documents {
                        let ref = self?.db.collection("readings").document(document.documentID)
                        updateBatch?.updateData(["meterId": newMeterNumber], forDocument: ref!)
                    }
                    
                    updateBatch?.commit { error in
                        if let error = error {
                            print("Error updating readings: \(error)")
                        }
                    }
                }
        } else {
            // Nur Name wurde geändert
            let meterRef = db.collection("meters").document(oldMeterNumber)
            batch.updateData(["name": newName], forDocument: meterRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error committing meter update batch: \(error)")
            }
        }
    }
    
    func deleteMeter(_ meter: Meter) throws {
        let batch = db.batch()
        
        // 1. Lösche das Meter
        let meterRef = db.collection("meters").document(meter.meterNumber)
        batch.deleteDocument(meterRef)
        
        // 2. Lösche alle zugehörigen Readings
        db.collection("readings")
            .whereField("meterId", isEqualTo: meter.meterNumber)
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let deleteBatch = self?.db.batch()
                for document in documents {
                    let ref = self?.db.collection("readings").document(document.documentID)
                    deleteBatch?.deleteDocument(ref!)
                }
                
                deleteBatch?.commit { error in
                    if let error = error {
                        print("Error deleting readings: \(error)")
                    }
                }
            }
        
        batch.commit { error in
            if let error = error {
                print("Error committing meter delete batch: \(error)")
            }
        }
    }
    
    func listenToMeters() {
        db.collection("meters")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching meters: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                self?.meters = documents.compactMap { try? $0.data(as: Meter.self) }
            }
    }
    
    // MARK: - Readings
    
    func addReading(_ reading: Reading) throws {
        try db.collection("readings").addDocument(from: reading)
    }
    
    func updateReading(_ reading: Reading) throws {
        guard let id = reading.id else { return }
        try db.collection("readings").document(id).setData(from: reading)
    }
    
    func deleteReading(_ reading: Reading) throws {
        guard let id = reading.id else { return }
        db.collection("readings").document(id).delete()
    }
    
    func listenToReadings(for meterId: String) {
        db.collection("readings")
            .whereField("meterId", isEqualTo: meterId)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching readings: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                self?.readings = documents.compactMap { try? $0.data(as: Reading.self) }
            }
    }
}

