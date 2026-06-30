import Foundation
import Supabase

struct InsertSystemLogEntry: Codable {
    let category: LogCategory
    let severity: LogSeverity
    let message: String
    let boutiqueName: String?
    
    enum CodingKeys: String, CodingKey {
        case category, severity, message
        case boutiqueName = "boutique_name"
    }
}

final class SystemLogService {
    static let shared = SystemLogService()
    
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    func logAction(category: LogCategory, severity: LogSeverity, message: String, boutiqueName: String? = nil) {
        let entry = InsertSystemLogEntry(
            category: category,
            severity: severity,
            message: message,
            boutiqueName: boutiqueName
        )
        
        Task {
            do {
                try await client.from("audit_logs")
                    .insert(entry)
                    .execute()
                print("System Log recorded: [\(category.rawValue)] \(message)")
            } catch {
                print("Failed to record system log: \(error.localizedDescription)")
            }
        }
    }
}
