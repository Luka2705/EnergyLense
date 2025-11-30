import Foundation
import FirebaseFirestore

struct Reading: Identifiable, Codable {
    @DocumentID var id: String?
    var meterId: String
    var value: Double
    var date: Date
    var imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case meterId
        case value
        case date
        case imageUrl
    }
}
