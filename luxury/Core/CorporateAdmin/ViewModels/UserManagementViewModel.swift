//
//  UserManagementViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 18/05/26.
//

import SwiftUI
import Observation
import Supabase

@Observable
final class UserManagementViewModel {
    var searchText: String = ""
    var isLoading = false
    var actionBoutiqueId: UUID?
    var actionErrorMessage: String?
    var errorMessage: String?
    
    var pendingBoutiques: [CorporateBoutique] = []
    var approvedBoutiques: [CorporateBoutique] = []
    
    private let approvalService = ApprovalService()
    
    var filteredApprovedBoutiques: [CorporateBoutique] {
        if searchText.isEmpty {
            return approvedBoutiques
        }
        return approvedBoutiques.filter { boutique in
            boutique.name.localizedCaseInsensitiveContains(searchText) ||
            boutique.managerName.localizedCaseInsensitiveContains(searchText) ||
            boutique.managerPhone.localizedCaseInsensitiveContains(searchText) ||
            boutique.city.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func fetchData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                async let pendingTask = approvalService.fetchPendingBoutiques()
                async let approvedTask = approvalService.fetchApprovedBoutiques()
                
                let (pending, approved) = try await (pendingTask, approvedTask)
                
                await MainActor.run {
                    self.pendingBoutiques = pending
                    self.approvedBoutiques = approved
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to fetch user management data: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
    
    func approveBoutique(_ boutique: CorporateBoutique, completion: @escaping () -> Void = {}) {
        actionBoutiqueId = boutique.id
        actionErrorMessage = nil
        errorMessage = nil
        
        Task {
            do {
                try await approvalService.approveBoutique(id: boutique.id)
                SystemLogService.shared.logAction(category: .access, severity: .info, message: "Approved boutique: \(boutique.name)", boutiqueName: boutique.name)
                await MainActor.run {
                    self.pendingBoutiques.removeAll { $0.id == boutique.id }
                    self.actionBoutiqueId = nil
                    fetchData()
                    completion()
                }
            } catch {
                await MainActor.run {
                    self.actionBoutiqueId = nil
                    self.actionErrorMessage = "Approval failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func rejectBoutique(_ boutique: CorporateBoutique, completion: @escaping () -> Void = {}) {
        actionBoutiqueId = boutique.id
        actionErrorMessage = nil
        errorMessage = nil

        Task {
            do {
                try await approvalService.rejectBoutique(id: boutique.id)
                SystemLogService.shared.logAction(category: .access, severity: .warning, message: "Rejected boutique: \(boutique.name)", boutiqueName: boutique.name)
                await MainActor.run {
                    self.pendingBoutiques.removeAll { $0.id == boutique.id }
                    self.actionBoutiqueId = nil
                    fetchData()
                    completion()
                }
            } catch {
                await MainActor.run {
                    self.actionBoutiqueId = nil
                    self.actionErrorMessage = "Rejection failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func disableBoutique(_ boutique: CorporateBoutique, completion: @escaping () -> Void = {}) {
        actionBoutiqueId = boutique.id
        actionErrorMessage = nil
        errorMessage = nil

        Task {
            do {
                try await approvalService.disableBoutique(id: boutique.id)
                SystemLogService.shared.logAction(category: .access, severity: .warning, message: "Disabled boutique: \(boutique.name)", boutiqueName: boutique.name)
                await MainActor.run {
                    self.actionBoutiqueId = nil
                    fetchData()
                    completion()
                }
            } catch {
                await MainActor.run {
                    self.actionBoutiqueId = nil
                    self.actionErrorMessage = "Disable failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func enableBoutique(_ boutique: CorporateBoutique, completion: @escaping () -> Void = {}) {
        actionBoutiqueId = boutique.id
        actionErrorMessage = nil
        errorMessage = nil

        Task {
            do {
                try await approvalService.enableBoutique(id: boutique.id)
                SystemLogService.shared.logAction(category: .access, severity: .info, message: "Enabled boutique: \(boutique.name)", boutiqueName: boutique.name)
                await MainActor.run {
                    self.actionBoutiqueId = nil
                    fetchData()
                    completion()
                }
            } catch {
                await MainActor.run {
                    self.actionBoutiqueId = nil
                    self.actionErrorMessage = "Enable failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func removeBoutique(_ boutique: CorporateBoutique, completion: @escaping () -> Void = {}) {
        actionBoutiqueId = boutique.id
        actionErrorMessage = nil
        errorMessage = nil

        Task {
            do {
                try await approvalService.removeBoutique(id: boutique.id)
                SystemLogService.shared.logAction(category: .security, severity: .critical, message: "Removed boutique: \(boutique.name)", boutiqueName: boutique.name)
                await MainActor.run {
                    self.approvedBoutiques.removeAll { $0.id == boutique.id }
                    self.actionBoutiqueId = nil
                    fetchData()
                    completion()
                }
            } catch {
                await MainActor.run {
                    self.actionBoutiqueId = nil
                    self.actionErrorMessage = "Removal failed: \(error.localizedDescription)"
                }
            }
        }
    }

    func inviteBoutique(email: String, password: String) async throws {
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
        
        let metadata: [String: AnyJSON] = [
            "role": .string(UserRole.boutiqueManager.rawValue),
            "provider": .string("email")
        ]
        
        let response = try await ephemeralClient.auth.signUp(email: trimmedEmail, password: trimmedPassword, data: metadata)
        let newUserId = response.user.id
        
        let profileService = ProfileService()
        try await profileService.createSkeletonProfile(
            userId: newUserId,
            role: .boutiqueManager,
            name: "",
            email: trimmedEmail,
            provider: "email"
        )
        
        SystemLogService.shared.logAction(category: .access, severity: .info, message: "Invited new boutique manager: \(trimmedEmail)")
    }
}
