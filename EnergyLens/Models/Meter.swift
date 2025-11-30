import Foundation
import FirebaseFirestore

struct Meter: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var meterNumber: String
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case meterNumber
        case createdAt
    }
}
