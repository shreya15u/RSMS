import SwiftUI
import Observation
import PhotosUI
import Supabase

@Observable
final class RegistrationViewModel {
    var name = ""
    var email = ""
    var phone = ""
    var address = ""
    var password = ""
    var acceptedTerms = false
    
    var boutiqueName = ""
    var city = ""
    var pinCode = ""
    
    var selectedBoutiqueId: UUID?
    var avatarImage: PickedImageAsset?
    var resumeImage: PickedImageAsset?
    
    var isLoading = false
    var errorMessage: String?
    
    private let authService = AuthService()
    private let storageService = StorageService()
    private let imagePickerService = ImagePickerService()
    private let client = SupabaseManager.shared.client
    
    var boutiques: [CorporateBoutique] = []
    
    private struct BoutiqueUpdate: Encodable {
        let name: String
        let manager_name: String
        let address: String
        let city: String
        let pin_code: String
        let manager_phone: String
        let provider: String
        let updated_at: Date
        let on_boarding_completed: Bool
    }
    
    private struct StaffUpdate: Encodable {
        let name: String
        let boutique_id: UUID
        let phone: String
        let address: String
        let location: String
        let city: String
        let pin_code: String
        let resume_url: String
        let avatar_url: String
        let provider: String
        let updated_at: Date
        let on_boarding_completed: Bool
    }
    
    private struct SavedApplicationID: Decodable {
        let id: UUID
    }
    
    func loadUserData() {
        Task {
            let session = await authService.getCurrentSession()
            guard let userId = session?.user.id else { return }
            
            await MainActor.run {
                self.email = session?.user.email ?? ""
                self.password = "••••••••"
                if let tempName = UserDefaults.standard.string(forKey: "temp_reg_name") {
                    self.name = tempName
                } else {
                    self.name = session?.user.userMetadata["full_name"]?.stringValue ?? ""
                }
            }
            
            do {
                let staffMembers: [StaffModel] = try await client.from("staff").select().eq("auth_user_id", value: userId).execute().value
                if let staff = staffMembers.first, let bId = staff.boutiqueId {
                    let boutique: CorporateBoutique = try await client.from("boutiques").select().eq("id", value: bId).single().execute().value
                    await MainActor.run {
                        self.selectedBoutiqueId = boutique.id
                        self.city = boutique.city
                    }
                }
            } catch {
                // Not a staff member or no boutique assigned
            }
        }
    }
    
    func fetchBoutiques() {
        Task {
            do {
                let fetched: [CorporateBoutique] = try await client.from("boutiques").select().eq("status", value: "approved").execute().value
                await MainActor.run {
                    self.boutiques = fetched
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to load approved boutiques.")
                }
            }
        }
    }
    
    func selectBoutique(_ boutique: CorporateBoutique) {
        selectedBoutiqueId = boutique.id
        city = boutique.city
    }
    
    func pickAvatar(from item: PhotosPickerItem?) {
        Task {
            do {
                let image = try await imagePickerService.loadImage(from: item)
                await MainActor.run {
                    self.avatarImage = image
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func pickResume(from item: PhotosPickerItem?) {
        Task {
            do {
                let image = try await imagePickerService.loadImage(from: item)
                await MainActor.run {
                    self.resumeImage = image
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func submitApplication(role: UserRole, completion: @escaping () -> Void) {
        guard validateApplication(role: role) else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let session = await authService.getCurrentSession()
                guard let userId = session?.user.id else {
                    throw validationError("Failed to retrieve user ID.")
                }
                guard let sessionEmail = session?.user.email?.trimmed, !sessionEmail.isEmpty else {
                    throw validationError("Failed to retrieve account email.")
                }
                
                let provider = session?.user.userMetadata["provider"]?.stringValue ?? "email"
                
                var avatarUrl = ""
                if let image = avatarImage {
                    avatarUrl = try await storageService.uploadAvatar(image: image, userId: userId)
                }
                
                var resumeUrl = ""
                if let image = resumeImage {
                    resumeUrl = try await storageService.uploadResume(image: image, userId: userId)
                }
                
                switch role {
                case .boutiqueManager:
                    _ = try await submitBoutiqueApplication(
                        sessionEmail: sessionEmail,
                        provider: provider
                    )
                    
                case .salesAssociate, .inventoryController:
                    guard let selectedBoutiqueId else {
                        throw validationError("Please select an approved boutique.")
                    }
                    _ = try await submitStaffApplication(
                        userId: userId,
                        email: sessionEmail,
                        boutiqueId: selectedBoutiqueId,
                        avatarUrl: avatarUrl,
                        resumeUrl: resumeUrl,
                        provider: provider
                    )
                    
                case .corporateAdmin:
                    throw validationError("Corporate admin registration is not available.")
                }
                
                await MainActor.run {
                    UserDefaults.standard.removeObject(forKey: "temp_reg_name")
                    isLoading = false
                    completion()
                }
            } catch {
                let message = "Application submission failed: \(error.localizedDescription)"
                await MainActor.run {
                    isLoading = false
                    errorMessage = message
                }
            }
        }
    }
    
    private func submitStaffApplication(
        userId: UUID,
        email: String,
        boutiqueId: UUID,
        avatarUrl: String,
        resumeUrl: String,
        provider: String
    ) async throws -> SavedApplicationID {
        let update = StaffUpdate(
            name: name.trimmed,
            boutique_id: boutiqueId,
            phone: phone.trimmed,
            address: address.trimmed,
            location: city.trimmed,
            city: city.trimmed,
            pin_code: pinCode.trimmed,
            resume_url: resumeUrl,
            avatar_url: avatarUrl,
            provider: provider,
            updated_at: Date(),
            on_boarding_completed: true
        )
        
        var existingId: UUID?
        if let existing = try await findStaffApplicationId(userId: userId) {
            existingId = existing.id
        } else if let existing = try await findStaffApplicationIdByEmail(email: email) {
            existingId = existing.id
        }
        
        if let id = existingId {
            return try await client.from("staff")
                .update(update)
                .eq("id", value: id)
                .select("id")
                .single()
                .execute()
                .value
        }
        
        throw validationError("No invited staff record found.")
    }
    
    private func findStaffApplicationId(userId: UUID) async throws -> SavedApplicationID? {
        let matches: [SavedApplicationID] = try await client.from("staff")
            .select("id")
            .eq("auth_user_id", value: userId)
            .limit(1)
            .execute()
            .value
        
        return matches.first
    }
    
    private func findStaffApplicationIdByEmail(email: String) async throws -> SavedApplicationID? {
        let matches: [SavedApplicationID] = try await client.from("staff")
            .select("id")
            .eq("email", value: email)
            .limit(1)
            .execute()
            .value
        
        return matches.first
    }
    
    private func submitBoutiqueApplication(sessionEmail: String, provider: String) async throws -> CorporateBoutique {
        let update = BoutiqueUpdate(
            name: boutiqueName.trimmed,
            manager_name: name.trimmed,
            address: address.trimmed,
            city: city.trimmed,
            pin_code: pinCode.trimmed,
            manager_phone: phone.trimmed,
            provider: provider,
            updated_at: Date(),
            on_boarding_completed: true
        )
        
        var existing = try await findBoutiqueApplication(email: sessionEmail)
        if existing == nil {
            existing = try await findBoutiqueApplication(email: email.trimmed)
        }
        
        if let existing {
            let updated: CorporateBoutique = try await client.from("boutiques")
                .update(update)
                .eq("id", value: existing.id)
                .select()
                .single()
                .execute()
                .value
            return updated
        }
        
        let boutique = CorporateBoutique(
            id: UUID(),
            name: boutiqueName.trimmed,
            managerName: name.trimmed,
            managerEmail: sessionEmail,
            managerPhone: phone.trimmed,
            address: address.trimmed,
            city: city.trimmed,
            pinCode: pinCode.trimmed,
            provider: provider,
            status: .pending,
            createdAt: Date(),
            updatedAt: Date(),
            onBoardingCompleted: true,
            avatarUrl: nil,
            dailySalesTarget: nil,
            currency: nil
        )
        
        let created: CorporateBoutique = try await client.from("boutiques")
            .insert(boutique)
            .select()
            .single()
            .execute()
            .value
        return created
    }
    
    private func findBoutiqueApplication(email: String) async throws -> CorporateBoutique? {
        let trimmedEmail = email.trimmed
        guard !trimmedEmail.isEmpty else { return nil }
        
        let matches: [CorporateBoutique] = try await client.from("boutiques")
            .select()
            .eq("manager_email", value: trimmedEmail)
            .limit(1)
            .execute()
            .value
        
        return matches.first
    }
    
    private func validateApplication(role: UserRole) -> Bool {
        guard acceptedTerms else {
            errorMessage = String(localized: "Please accept the terms and conditions.")
            return false
        }
        
        guard !name.trimmed.isEmpty, !email.trimmed.isEmpty, !phone.trimmed.isEmpty, !address.trimmed.isEmpty else {
            errorMessage = String(localized: "Please complete all required profile fields.")
            return false
        }
        
        switch role {
        case .boutiqueManager:
            guard !boutiqueName.trimmed.isEmpty, !city.trimmed.isEmpty, !pinCode.trimmed.isEmpty else {
                errorMessage = String(localized: "Please complete all boutique details.")
                return false
            }
        case .salesAssociate, .inventoryController:
            guard selectedBoutiqueId != nil else {
                errorMessage = String(localized: "Please select an approved boutique.")
                return false
            }
            guard !pinCode.trimmed.isEmpty else {
                errorMessage = String(localized: "Please enter your PIN code.")
                return false
            }
            guard avatarImage != nil, resumeImage != nil else {
                errorMessage = String(localized: "Please attach both profile and resume images.")
                return false
            }
        case .corporateAdmin:
            errorMessage = String(localized: "Corporate admin registration is not available.")
            return false
        }
        
        return true
    }
    
    private func validationError(_ message: String) -> NSError {
        NSError(domain: "Registration", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
