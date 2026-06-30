import Foundation

struct OrderEntity: Identifiable, Codable, Hashable {
    let id: UUID
    let cartId: UUID?
    let dateOfPurchase: Date?
    let transactionId: UUID?
    let rsmsUserId: UUID
    let totalPrice: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case cartId = "cart_id"
        case dateOfPurchase = "date_of_purchase"
        case transactionId = "transaction_id"
        case rsmsUserId = "rsms_user_id"
        case totalPrice = "total_price"
    }
}

struct SATransactionEntity: Identifiable, Codable, Hashable {
    let id: UUID
    let transactionAmount: Double
    let dateOfTransaction: Date?
    let purpose: String
    let clientId: UUID?
    let boutiqueId: UUID?
    let staffId: UUID?
    let client: ClientEntity?
    let paymentGatewayId: String?
    let isGift: Bool?
    let isTax: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case transactionAmount = "transaction_amount"
        case dateOfTransaction = "date_of_transaction"
        case purpose
        case clientId = "client_id"
        case boutiqueId = "boutique_id"
        case staffId = "staff_id"
        case client
        case paymentGatewayId = "payment_gateway_id"
        case isGift = "is_gift"
        case isTax = "is_tax"
    }
}
