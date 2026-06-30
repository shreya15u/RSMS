import Foundation
import Supabase

final class ProfileService {
    private let client = SupabaseManager.shared.client
    
    func fetchCurrentProfile(preferredRole: UserRole? = nil) async throws -> (UserRole, Any)? {
        let session = try? await client.auth.session
        guard let userId = session?.user.id, let email = session?.user.email else { return nil }
        
        let roleStr = session?.user.userMetadata["role"]?.stringValue
        let metadataRole = UserRole(rawValue: roleStr ?? "")
        let role = preferredRole ?? metadataRole
        
        if role == .corporateAdmin || role == nil {
            do {
                let admin: CorporateAdmin = try await client.from("corporate_admins")
                    .select()
                    .eq("id", value: userId)
                    .single()
                    .execute()
                    .value
                return (.corporateAdmin, admin)
            } catch {}
        }
        
        if role == .boutiqueManager || role == nil {
            do {
                let manager: CorporateBoutique = try await client.from("boutiques")
                    .select()
                    .eq("manager_email", value: email)
                    .single()
                    .execute()
                    .value
                return (.boutiqueManager, manager)
            } catch {}
        }
        
        if role == .salesAssociate || role == .inventoryController || role == nil {
            do {
                let staff: StaffModel = try await client.from("staff")
                    .select()
                    .eq("auth_user_id", value: userId)
                    .single()
                    .execute()
                    .value
                let mappedRole: UserRole = staff.role == .salesAssociate ? .salesAssociate : .inventoryController
                return (mappedRole, staff)
            } catch {}
            
            do {
                let staff: StaffModel = try await client.from("staff")
                    .select()
                    .eq("email", value: email)
                    .single()
                    .execute()
                    .value
                try await client.from("staff")
                    .update(["auth_user_id": userId.uuidString])
                    .eq("id", value: staff.id)
                    .execute()
                let updatedStaff: StaffModel = try await client.from("staff")
                    .select()
                    .eq("id", value: staff.id)
                    .single()
                    .execute()
                    .value
                let mappedRole: UserRole = updatedStaff.role == .salesAssociate ? .salesAssociate : .inventoryController
                return (mappedRole, updatedStaff)
            } catch {}
        }
        
        return nil
    }
    
    func fetchBoutique(id: UUID) async throws -> CorporateBoutique? {
        try await client.from("boutiques")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }
    
    func createSkeletonProfile(userId: UUID, role: UserRole, name: String, email: String, provider: String) async throws {
        switch role {
        case .corporateAdmin:
            let admin = CorporateAdmin(
                id: userId,
                name: name,
                email: email,
                phone: "+910000000000",
                createdAt: Date(),
                avatarUrl: nil
            )
            try await client.from("corporate_admins").upsert(admin).execute()
            
        case .boutiqueManager:
            let boutique = CorporateBoutique(
                id: UUID(),
                name: "",
                managerName: name,
                managerEmail: email,
                managerPhone: "",
                address: "",
                city: "",
                pinCode: "",
                provider: provider,
                status: .pending,
                createdAt: Date(),
                updatedAt: Date(),
                onBoardingCompleted: false,
                avatarUrl: nil,
                dailySalesTarget: nil,
                currency: nil
            )
            try await client.from("boutiques").upsert(boutique, onConflict: "manager_email").execute()
            
        case .salesAssociate, .inventoryController:
            let staffRole: StaffRole = role == .salesAssociate ? .salesAssociate : .inventoryController
            let staff = StaffModel(
                id: UUID(),
                authUserId: userId,
                boutiqueId: nil,
                employeeId: "TEMP-\(userId.uuidString.prefix(6))",
                role: staffRole,
                name: name,
                email: email,
                phone: "",
                address: "",
                location: "",
                city: "",
                pinCode: "",
                resumeUrl: "",
                provider: provider,
                avatarUrl: "",
                certificationUrl: nil,
                status: .pending,
                createdAt: Date(),
                updatedAt: Date(),
                lastLoginAt: nil,
                onBoardingCompleted: false,
                dailySalesTarget: nil
            )
            try await client.from("staff").upsert(staff, onConflict: "email").execute()
        }
    }
}
