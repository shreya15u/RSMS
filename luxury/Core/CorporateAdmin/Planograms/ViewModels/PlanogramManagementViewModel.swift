import Foundation
import Observation
import Supabase
import SwiftUI
import PhotosUI

@Observable
final class PlanogramManagementViewModel {
    var planograms: [PlanogramEntity] = []
    var boutiques: [CorporateBoutique] = []
    
    var isLoading = false
    var isUploading = false
    var errorMessage: String?
    
    private let client = SupabaseManager.shared.client
    
    @MainActor
    func fetchData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchPlanograms: [PlanogramEntity] = client.from("planogram").select().order("created_at", ascending: false).execute().value
            async let fetchBoutiques: [CorporateBoutique] = client.from("boutiques").select().execute().value
            
            let (pData, bData) = try await (fetchPlanograms, fetchBoutiques)
            self.planograms = pData
            self.boutiques = bData
        } catch {
            self.errorMessage = error.localizedDescription
            print("Failed to fetch planogram data: \(error)")
        }
        isLoading = false
    }
    
    @MainActor
    func uploadPlanogram(title: String, description: String, boutiqueId: UUID?, validFrom: Date, validUntil: Date, imageData: Data) async -> Bool {
        isUploading = true
        errorMessage = nil
        
        do {
            guard let session = try? await client.auth.session else {
                throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])
            }
            
            // 1. Fetch staff ID for created_by (Optional since Corporate Admins might not be in the staff table)
            let staff: StaffModel? = try? await client.from("staff")
                .select()
                .eq("auth_user_id", value: session.user.id)
                .single()
                .execute()
                .value
            
            // 2. Upload image to Storage
            let fileName = "\(UUID().uuidString).jpg"
            let filePath = "public/\(fileName)"
            
            try await client.storage
                .from("planograms")
                .upload(
                    filePath,
                    data: imageData,
                    options: FileOptions(contentType: "image/jpeg")
                )
            
            // Generate public URL
            let fileUrl = try client.storage.from("planograms").getPublicURL(path: filePath).absoluteString
            
            // 3. Insert into Database
            struct CreatePlanogramRequest: Encodable {
                let title: String
                let description: String?
                let file_url: String
                let boutique_id: UUID?
                let valid_from: String
                let valid_until: String
                let created_by: UUID?
            }
            
            let isoFormatter = ISO8601DateFormatter()
            let request = CreatePlanogramRequest(
                title: title,
                description: description.isEmpty ? nil : description,
                file_url: fileUrl,
                boutique_id: boutiqueId,
                valid_from: isoFormatter.string(from: validFrom),
                valid_until: isoFormatter.string(from: validUntil),
                created_by: staff?.id
            )
            
            try await client.from("planogram")
                .insert(request)
                .execute()
            
            await fetchData()
            isUploading = false
            return true
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("Failed to upload planogram: \(error)")
            isUploading = false
            return false
        }
    }
    
    @MainActor
    func updatePlanogram(id: UUID, title: String, description: String, boutiqueId: UUID?, validFrom: Date, validUntil: Date, imageData: Data?, existingFileUrl: String) async -> Bool {
        isUploading = true
        errorMessage = nil
        
        do {
            var finalFileUrl = existingFileUrl
            
            if let imageData = imageData {
                let fileName = "\(UUID().uuidString).jpg"
                let filePath = "public/\(fileName)"
                
                try await client.storage
                    .from("planograms")
                    .upload(
                        filePath,
                        data: imageData,
                        options: FileOptions(contentType: "image/jpeg")
                    )
                
                finalFileUrl = try client.storage.from("planograms").getPublicURL(path: filePath).absoluteString
            }
            
            struct UpdatePlanogramRequest: Encodable {
                let title: String
                let description: String?
                let file_url: String
                let boutique_id: UUID?
                let valid_from: String
                let valid_until: String
            }
            
            let isoFormatter = ISO8601DateFormatter()
            let request = UpdatePlanogramRequest(
                title: title,
                description: description.isEmpty ? nil : description,
                file_url: finalFileUrl,
                boutique_id: boutiqueId,
                valid_from: isoFormatter.string(from: validFrom),
                valid_until: isoFormatter.string(from: validUntil)
            )
            
            try await client.from("planogram")
                .update(request)
                .eq("id", value: id.uuidString)
                .execute()
            
            await fetchData()
            isUploading = false
            return true
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("Failed to update planogram: \(error)")
            isUploading = false
            return false
        }
    }
    
    @MainActor
    func deletePlanogram(id: UUID) async {
        do {
            try await client.from("planogram").delete().eq("id", value: id).execute()
            await fetchData()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
