import Foundation
import SwiftUI
import Supabase
import PostgREST

@Observable
final class PricingCampaignViewModel {
    var campaigns: [PricingCampaign] = []
    var boutiques: [String] = []
    var isLoading = false
    var errorMessage: String?
    
    init() {
        Task {
            await fetchBoutiques()
        }
    }
    
    func fetchBoutiques() async {
        do {
            struct BoutiqueResponse: Codable {
                let name: String
            }
            let fetched: [BoutiqueResponse] = try await SupabaseManager.shared.client
                .from("boutiques")
                .select("name")
                .eq("status", value: "approved")
                .execute()
                .value
            
            await MainActor.run {
                self.boutiques = ["All Boutiques"] + fetched.map { $0.name }
            }
        } catch {
            print("Failed to fetch boutiques: \(error)")
        }
    }
    
    func fetchCampaigns() async {
        isLoading = true
        do {
            let response = try await SupabaseManager.shared.client
                .from("campaigns")
                .select()
                .order("created_at", ascending: false)
                .execute()
            
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
            
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                if let date = formatter.date(from: dateString) {
                    return date
                }
                if let date = ISO8601DateFormatter().date(from: dateString) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date")
            }
            
            let fetched = try decoder.decode([PricingCampaign].self, from: response.data)
            await MainActor.run {
                self.campaigns = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    func addCampaign(title: String, boutique: String, discountPercentage: Double, startDate: Date, endDate: Date, categories: [String]) {
        let newCampaign = PricingCampaign(
            id: UUID(),
            title: title,
            boutique: boutique,
            discountPercentage: discountPercentage,
            startDate: startDate,
            endDate: endDate,
            status: .scheduled,
            affectedCategories: categories
        )
        Task {
            do {
                _ = try await SupabaseManager.shared.client
                    .from("campaigns")
                    .insert(newCampaign)
                    .execute()
                await fetchCampaigns()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func toggleStatus(for campaign: PricingCampaign) {
        if let index = campaigns.firstIndex(where: { $0.id == campaign.id }) {
            var updated = campaigns[index]
            if updated.status == .active {
                updated.status = .completed
            } else if updated.status == .scheduled {
                updated.status = .active
            }
            
            let newStatus = updated.status
            struct UpdateStatus: Encodable { let status: String }
            Task {
                do {
                    _ = try await SupabaseManager.shared.client
                        .from("campaigns")
                        .update(UpdateStatus(status: newStatus.rawValue))
                        .eq("id", value: updated.id.uuidString)
                        .execute()
                    await fetchCampaigns()
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func badgeStatus(for status: PricingCampaign.CampaignStatus) -> BadgeStatus {
        switch status {
        case .draft: return .neutral
        case .scheduled: return .pending
        case .active: return .success
        case .completed: return .neutral
        }
    }
}
