import Foundation

enum EntityStatus: String, Codable, Hashable {
    case pending
    case approved
    case rejected
    case paused
}

struct CorporateAdmin: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let email: String
    let phone: String
    let createdAt: Date
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, phone
        case createdAt = "created_at"
        case avatarUrl = "avatar_url"
    }
}

struct CorporateBoutique: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let managerName: String
    let managerEmail: String
    let managerPhone: String
    let address: String
    let city: String
    let pinCode: String
    let provider: String
    let status: EntityStatus
    let createdAt: Date
    let updatedAt: Date
    let onBoardingCompleted: Bool
    let avatarUrl: String?
    let dailySalesTarget: Double?
    let currency: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, city, provider, status
        case managerName = "manager_name"
        case managerEmail = "manager_email"
        case managerPhone = "manager_phone"
        case pinCode = "pin_code"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case onBoardingCompleted = "on_boarding_completed"
        case avatarUrl = "avatar_url"
        case dailySalesTarget = "daily_sales_target"
        case currency
    }
}

extension CorporateBoutique {
    var isRegistrationIncomplete: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        managerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        managerEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        managerPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        pinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct SystemLogEntry: Identifiable, Hashable, Codable {
    let id: UUID
    let timestamp: Date
    let category: LogCategory
    let severity: LogSeverity
    let message: String
    let boutiqueName: String?
    
    enum CodingKeys: String, CodingKey {
        case id, category, severity, message
        case timestamp = "created_at"
        case boutiqueName = "boutique_name"
    }
}

enum LogCategory: String, Codable, CaseIterable {
    case security = "Security"
    case inventory = "Inventory"
    case access = "Access"
    case system = "System"
}

enum LogSeverity: String, Codable {
    case critical = "Critical"
    case warning = "Warning"
    case info = "Info"
}
