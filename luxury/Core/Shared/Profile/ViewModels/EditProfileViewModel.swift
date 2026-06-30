import Foundation
import Observation
import Supabase
import _PhotosUI_SwiftUI

@Observable
final class EditProfileViewModel {
    var name: String = ""
    var email: String = ""
    var phone: String = ""
    var avatarUrl: String?
    
    var selectedPhotoItem: PhotosPickerItem? = nil {
        didSet {
            if selectedPhotoItem != nil {
                Task {
                    await loadPhotoAsset()
                }
            }
        }
    }
    
    var selectedPhotoAsset: PickedImageAsset?
    
    var isLoading = false
    var errorMessage: String? = nil
    var successMessage: String? = nil
    
    var boutiqueName: String = ""
    var boutiqueAddress: String = ""
    var boutiqueCity: String = ""
    var boutiquePinCode: String = ""
    
    var isBoutiqueManager: Bool { currentUserRole == .boutiqueManager }
    
    private let profileService = ProfileService()
    private let storageService = StorageService()
    private let imagePickerService = ImagePickerService()
    
    private var currentUserRole: UserRole?
    private var currentUserId: UUID?
    
    func fetchProfile() async {
        isLoading = true
        do {
            if let (role, profile) = try await profileService.fetchCurrentProfile() {
                await MainActor.run {
                    self.currentUserRole = role
                    if let admin = profile as? CorporateAdmin {
                        self.name = admin.name
                        self.email = admin.email
                        self.phone = admin.phone
                        self.currentUserId = admin.id
                        self.avatarUrl = admin.avatarUrl
                    } else if let bm = profile as? CorporateBoutique {
                        self.name = bm.managerName
                        self.email = bm.managerEmail
                        self.phone = bm.managerPhone
                        self.currentUserId = bm.id
                        self.avatarUrl = bm.avatarUrl
                        self.boutiqueName = bm.name
                        self.boutiqueAddress = bm.address
                        self.boutiqueCity = bm.city
                        self.boutiquePinCode = bm.pinCode
                    } else if let staff = profile as? StaffModel {
                        self.name = staff.name
                        self.email = staff.email
                        self.phone = staff.phone
                        self.currentUserId = staff.id
                        self.avatarUrl = staff.avatarUrl
                    }
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func loadPhotoAsset() async {
        guard let item = selectedPhotoItem else { return }
        do {
            let asset = try await imagePickerService.loadImage(from: item)
            await MainActor.run {
                self.selectedPhotoAsset = asset
            }
        } catch {
            await MainActor.run {
                self.errorMessage = String(localized: "Failed to load image.")
            }
        }
    }
    
    func saveProfile(onSuccess: @escaping () -> Void) async {
        guard let role = currentUserRole, let userId = currentUserId else { return }
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let client = SupabaseManager.shared.client
            let session = try await client.auth.session
            let authUserId = session.user.id
            
            var newAvatarUrl = self.avatarUrl
            if let newAsset = selectedPhotoAsset {
                newAvatarUrl = try await storageService.uploadAvatar(image: newAsset, userId: authUserId)
            }
            
            // Depending on role, update the correct table
            if role == .corporateAdmin {
                let updates: [String: AnyJSON] = [
                    "name": .string(name),
                    "phone": .string(phone),
                    "avatar_url": .string(newAvatarUrl ?? "")
                ]
                try await client.from("corporate_admins")
                    .update(updates)
                    .eq("id", value: userId.uuidString)
                    .execute()
            } else if role == .boutiqueManager {
                let updates: [String: AnyJSON] = [
                    "manager_name": .string(name),
                    "manager_phone": .string(phone),
                    "avatar_url": .string(newAvatarUrl ?? ""),
                    "name": .string(boutiqueName),
                    "address": .string(boutiqueAddress),
                    "city": .string(boutiqueCity),
                    "pin_code": .string(boutiquePinCode)
                ]
                try await client.from("boutiques")
                    .update(updates)
                    .eq("id", value: userId.uuidString)
                    .execute()
            } else {
                let updates: [String: AnyJSON] = [
                    "name": .string(name),
                    "phone": .string(phone),
                    "avatar_url": .string(newAvatarUrl ?? "")
                ]
                try await client.from("staff")
                    .update(updates)
                    .eq("id", value: userId.uuidString)
                    .execute()
            }
            
            await MainActor.run {
                self.isLoading = false
                onSuccess()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
