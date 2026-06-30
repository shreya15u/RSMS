import Foundation

struct Cart: Codable, Identifiable {
    let id: UUID
    var clientId: UUID?
    var boutiqueId: UUID
    var status: String
    var totalPrice: Double
    var productIds: [UUID]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case boutiqueId = "boutique_id"
        case status
        case totalPrice = "total_price"
        case productIds = "product_ids"
    }
}
