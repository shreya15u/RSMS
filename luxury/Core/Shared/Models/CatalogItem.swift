import Foundation

struct CatalogItem: Codable, Identifiable, Hashable {
    let id: UUID
    var catalogId: String
    var name: String
    var description: String
    var brand: String
    var category: String
    var amount: Double
    var barCode: String
    var status: String
    var createdAt: Date?
    var productImages: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case catalogId = "catalog_id"
        case name, description, brand, category, amount
        case barCode = "bar_code"
        case status
        case createdAt = "created_at"
        case productImages = "product_images"
    }
}
