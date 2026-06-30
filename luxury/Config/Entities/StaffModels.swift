import Foundation

enum StaffRole: String, Codable, Hashable {
    case salesAssociate = "sales_associate"
    case inventoryController = "inventory_controller"
    
    var displayName: String {
        switch self {
        case .salesAssociate: return "Sales Associate"
        case .inventoryController: return "Inventory Controller"
        }
    }
}

struct StaffModel: Identifiable, Hashable, Codable, Equatable {
    let id: UUID
    let authUserId: UUID?
    let boutiqueId: UUID?
    let employeeId: String
    let role: StaffRole
    let name: String
    let email: String
    let phone: String
    let address: String
    let location: String
    let city: String
    let pinCode: String
    let resumeUrl: String
    let provider: String
    let avatarUrl: String
    let certificationUrl: String?
    let status: EntityStatus
    let createdAt: Date
    let updatedAt: Date
    let lastLoginAt: Date?
    let onBoardingCompleted: Bool
    let dailySalesTarget: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, address, location, city, status, provider, role
        case authUserId = "auth_user_id"
        case boutiqueId = "boutique_id"
        case employeeId = "employee_id"
        case pinCode = "pin_code"
        case resumeUrl = "resume_url"
        case avatarUrl = "avatar_url"
        case certificationUrl = "certification_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastLoginAt = "last_login_at"
        case onBoardingCompleted = "on_boarding_completed"
        case dailySalesTarget = "daily_sales_target"
    }
    
    var isRegistrationIncomplete: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        pinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        resumeUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        avatarUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        boutiqueId == nil
    }
    
    var isSalesAssociate: Bool { role == .salesAssociate }
    var isInventoryController: Bool { role == .inventoryController }
}
