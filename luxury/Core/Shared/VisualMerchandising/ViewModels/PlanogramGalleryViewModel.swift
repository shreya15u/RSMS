import Foundation
import Observation
import Supabase

@Observable
final class PlanogramGalleryViewModel {
    var activePlanograms: [PlanogramEntity] = []
    var isLoading = false
    var errorMessage: String?
    
    private let client = SupabaseManager.shared.client
    
    @MainActor
    func fetchPlanograms(for boutiqueId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched: [PlanogramEntity] = try await client.from("planogram")
                .select()
                .or("boutique_id.eq.\(boutiqueId),boutique_id.is.null")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            let currentDate = Date()
            let isoFormatter = ISO8601DateFormatter()
            
            self.activePlanograms = fetched.filter { p in
                guard let from = isoFormatter.date(from: p.validFrom), 
                      let until = isoFormatter.date(from: p.validUntil) else { return true }
                return currentDate >= from && currentDate <= until
            }
        } catch {
            print("Failed to fetch gallery planograms: \(error)")
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
