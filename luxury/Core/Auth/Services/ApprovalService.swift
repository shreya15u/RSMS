import Foundation
import Supabase

final class ApprovalService {
    private let client = SupabaseManager.shared.client
    
    func fetchPendingBoutiques() async throws -> [CorporateBoutique] {
        let boutiques: [CorporateBoutique] = try await client.from("boutiques").select().eq("status", value: "pending").execute().value
        return boutiques.filter { !$0.isRegistrationIncomplete }
    }
    
    func fetchApprovedBoutiques() async throws -> [CorporateBoutique] {
        let boutiques: [CorporateBoutique] = try await client.from("boutiques").select().or("status.eq.approved,status.eq.paused").execute().value
        return boutiques.filter { !$0.isRegistrationIncomplete }
    }
    
    func fetchPendingStaff(for boutiqueId: UUID) async throws -> [StaffModel] {
        let staff: [StaffModel] = try await client.from("staff").select().eq("boutique_id", value: boutiqueId).eq("status", value: "pending").execute().value
        return staff.filter { !$0.isRegistrationIncomplete }
    }
    
    func approveBoutique(id: UUID) async throws {
        try await updateBoutiqueStatus(id: id, status: .approved)
    }
    
    func rejectBoutique(id: UUID) async throws {
        try await updateBoutiqueStatus(id: id, status: .rejected)
    }
    
    func disableBoutique(id: UUID) async throws {
        try await updateBoutiqueStatus(id: id, status: .paused)
    }
    
    func enableBoutique(id: UUID) async throws {
        try await updateBoutiqueStatus(id: id, status: .approved)
    }
    
    func removeBoutique(id: UUID) async throws {
        try await client.from("boutiques").delete().eq("id", value: id).execute()
    }
    
    func approveStaff(id: UUID) async throws {
        try await updateStaffStatus(id: id, status: .approved)
    }
    
    func rejectStaff(id: UUID) async throws {
        try await updateStaffStatus(id: id, status: .rejected)
    }
    
    private func updateBoutiqueStatus(id: UUID, status: EntityStatus) async throws {
        try await client.from("boutiques").update(["status": status.rawValue]).eq("id", value: id).execute()
    }
    
    private func updateStaffStatus(id: UUID, status: EntityStatus) async throws {
        try await client.from("staff").update(["status": status.rawValue]).eq("id", value: id).execute()
    }
}

extension ApprovalService {
    func fetchApprovedStaff(for boutiqueId: UUID) async throws -> [StaffModel] {
        let staff: [StaffModel] = try await client.from("staff").select().eq("boutique_id", value: boutiqueId).eq("status", value: "approved").execute().value
        return staff.filter { !$0.isRegistrationIncomplete }
    }
}
