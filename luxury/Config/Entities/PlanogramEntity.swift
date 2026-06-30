import Foundation

struct PlanogramEntity: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var description: String?
    var fileUrl: String
    var boutiqueId: UUID?
    var validFrom: String
    var validUntil: String
    var createdAt: String?
    var createdBy: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case fileUrl = "file_url"
        case boutiqueId = "boutique_id"
        case validFrom = "valid_from"
        case validUntil = "valid_until"
        case createdAt = "created_at"
        case createdBy = "created_by"
    }
}
