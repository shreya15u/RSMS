import Foundation

struct PricingCampaign: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var boutique: String
    var discountPercentage: Double
    var startDate: Date
    var endDate: Date
    var status: CampaignStatus
    var affectedCategories: [String]
    var createdBy: UUID?
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, title, status
        case boutique = "region"
        case discountPercentage = "discount_percentage"
        case startDate = "start_date"
        case endDate = "end_date"
        case affectedCategories = "affected_categories"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    enum CampaignStatus: String, Codable, CaseIterable {
        case draft = "Draft"
        case scheduled = "Scheduled"
        case active = "Active"
        case completed = "Completed"
    }
    
}
