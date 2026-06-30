import Foundation

struct Order: Codable, Identifiable {
    let id: UUID
    var cartId: UUID?
    var dateOfPurchase: Date?
    var transactionId: UUID?
    var rsmsUserId: UUID
    var totalPrice: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case cartId = "cart_id"
        case dateOfPurchase = "date_of_purchase"
        case transactionId = "transaction_id"
        case rsmsUserId = "rsms_user_id"
        case totalPrice = "total_price"
    }
}
