import Foundation
import Observation
import Supabase

@Observable
final class TeamViewModel {
    var searchText: String = ""
    
    var pendingStaff: [StaffModel] = []
    var approvedStaff: [StaffModel] = []
    var boutiqueId: UUID?
    
    var isLoading = false
    var actionStaffId: UUID?
    var errorMessage: String?
    
    private let profileService = ProfileService()
    private let approvalService = ApprovalService()
    
    var filteredStaff: [StaffModel] {
        if searchText.isEmpty {
            return approvedStaff
        }
        return approvedStaff.filter { emp in
            emp.name.localizedCaseInsensitiveContains(searchText) ||
            emp.employeeId.localizedCaseInsensitiveContains(searchText) ||
            emp.phone.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var pendingStaffCount: Int {
        return pendingStaff.count
    }
    
    func fetchData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                guard let (_, profile) = try await profileService.fetchCurrentProfile(),
                      let manager = profile as? CorporateBoutique else {
                    throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Manager profile not found"])
                }
                
                let bId = manager.id
                
                async let pendingTask = approvalService.fetchPendingStaff(for: bId)
                async let approvedTask = approvalService.fetchApprovedStaff(for: bId)
                
                let (pending, approved) = try await (pendingTask, approvedTask)
                
                let sortedApproved = approved.sorted { $0.name < $1.name }
                
                await MainActor.run {
                    self.boutiqueId = bId
                    self.pendingStaff = pending
                    self.approvedStaff = sortedApproved
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to fetch team data: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
    
    func approveStaffMember(_ staff: StaffModel, completion: @escaping () -> Void = {}) {
        updateStaff(id: staff.id, action: { try await self.approvalService.approveStaff(id: staff.id) }, completion: completion)
    }
    
    func rejectStaffMember(_ staff: StaffModel, completion: @escaping () -> Void = {}) {
        updateStaff(id: staff.id, action: { try await self.approvalService.rejectStaff(id: staff.id) }, completion: completion)
    }

    func inviteStaff(email: String, password: String, role: StaffRole) async throws {
        guard let boutiqueId else {
            throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Boutique ID not loaded"])
        }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Email and password are required."])
        }
        
        let ephemeralClient = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    storage: InMemoryAuthStorage(),
                    autoRefreshToken: false
                )
            )
        )
        
        let mappedRole: UserRole = role == .salesAssociate ? .salesAssociate : .inventoryController
        let metadata: [String: AnyJSON] = [
            "role": .string(mappedRole.rawValue),
            "provider": .string("email")
        ]
        
        let response = try await ephemeralClient.auth.signUp(email: trimmedEmail, password: trimmedPassword, data: metadata)
        let newUserId = response.user.id
        
        let staff = StaffModel(
            id: UUID(),
            authUserId: newUserId,
            boutiqueId: boutiqueId,
            employeeId: "TEMP-\(newUserId.uuidString.prefix(6))",
            role: role,
            name: "",
            email: trimmedEmail,
            phone: "",
            address: "",
            location: "",
            city: "",
            pinCode: "",
            resumeUrl: "",
            provider: "email",
            avatarUrl: "",
            certificationUrl: nil,
            status: .approved,
            createdAt: Date(),
            updatedAt: Date(),
            lastLoginAt: nil,
            onBoardingCompleted: false,
            dailySalesTarget: nil
        )
        try await SupabaseManager.shared.client.from("staff").upsert(staff, onConflict: "email").execute()
    }

    private func updateStaff(id: UUID, action: @escaping () async throws -> Void, completion: @escaping () -> Void) {        actionStaffId = id
        errorMessage = nil
        
        Task {
            do {
                try await action()
                await MainActor.run {
                    self.actionStaffId = nil
                    fetchData()
                    completion()
                }
            } catch {
                await MainActor.run {
                    self.actionStaffId = nil
                    self.errorMessage = String(localized: "Failed to update staff request: \(error.localizedDescription)")
                }
            }
        }
    }
}
