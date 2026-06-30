import Foundation

enum AppointmentStatus: String, Codable, Hashable, CaseIterable {
    case pending = "pending"
    case upcoming = "upcoming"
    case completed = "completed"
    case cancelled = "cancelled"
    case noShow = "no_show"
}

import SwiftUI

extension AppointmentStatus {
    var color: Color {
        switch self {
        case .pending: return .orange
        case .upcoming: return .blue
        case .completed: return .green
        case .cancelled: return .red
        case .noShow: return .gray
        }
    }
    
    var displayStatus: String {
        return self.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

enum AppointmentType: String, Codable, Hashable, CaseIterable {
    case online = "online"
    case inStore = "in_store"
    
    public var displayName: String {
        switch self {
        case .online: return "ONLINE"
        case .inStore: return "INSTORE"
        }
    }
}

struct AppointmentEntity: Codable, Identifiable, Hashable {
    var id: UUID
    var clientId: UUID?
    var boutiqueId: UUID
    var timestamp: String
    var appointmentType: AppointmentType
    var assignedTo: UUID?
    var createdBy: UUID
    var status: AppointmentStatus
    var createdAt: String?
    var remarks: String?
    var client: ClientEntity?
    
    var displayAppointmentType: String {
        return appointmentType.displayName
    }
    
    var formattedTime: String {
        guard let date = ISO8601DateFormatter().date(from: timestamp) else { return timestamp }
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
    
    var formattedDate: String {
        guard let date = ISO8601DateFormatter().date(from: timestamp) else { return timestamp }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case boutiqueId = "boutique_id"
        case timestamp = "timestamp"
        case appointmentType = "appointment_type"
        case assignedTo = "assigned_to"
        case createdBy = "created_by"
        case status
        case createdAt = "created_at"
        case remarks
        case client
    }
}


