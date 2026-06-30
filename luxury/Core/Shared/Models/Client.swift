import Foundation

struct StoreClient: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var email: String
    var phone: String?
    var dob: Date?
    var tier: String?
    var productsPurchased: [UUID]?
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, dob, tier
        case productsPurchased = "products_purchased"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
