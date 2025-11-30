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

