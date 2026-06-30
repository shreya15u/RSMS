import Foundation
import Observation
import Supabase
import PostgREST

@Observable
final class SalesTargetsViewModel {
    var isLoading = false
    var isSaving = false
    var boutique: CorporateBoutique?
    var staffMembers: [StaffModel] = []
    var saveSuccessMessage: String?
    
    // Local edits
    var editedBoutiqueTarget: String = ""
    var editedStaffTargets: [UUID: String] = [:]
    
    func fetchData() async {
        isLoading = true
        do {
            if let (_, profile) = try await ProfileService().fetchCurrentProfile(),
               let corporateBoutique = profile as? CorporateBoutique {
                
                await MainActor.run {
                    self.boutique = corporateBoutique
                    if let target = corporateBoutique.dailySalesTarget {
                        let localTarget = CurrencyManager.shared.convertedAmount(fromINR: target)
                        self.editedBoutiqueTarget = String(format: "%.0f", localTarget)
                    } else {
                        self.editedBoutiqueTarget = ""
                    }
                }
                
                let fetchedStaff: [StaffModel] = try await SupabaseManager.shared.client
                    .from("staff")
                    .select()
                    .eq("boutique_id", value: corporateBoutique.id)
                    .execute()
                    .value
                
                let eligibleStaff = fetchedStaff.filter { $0.role != .inventoryController }
                
                await MainActor.run {
                    self.staffMembers = eligibleStaff
                    for staff in eligibleStaff {
                        if let target = staff.dailySalesTarget {
                            let localTarget = CurrencyManager.shared.convertedAmount(fromINR: target)
                            self.editedStaffTargets[staff.id] = String(format: "%.0f", localTarget)
                        } else {
                            self.editedStaffTargets[staff.id] = ""
                        }
                    }
                    self.isLoading = false
                }
            } else {
                await MainActor.run { isLoading = false }
            }
        } catch {
            print("Failed to fetch targets: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
    
    func saveTargets() async {
        guard let boutique = boutique else { return }
        isSaving = true
        
        do {
            let bTargetLocal = Double(editedBoutiqueTarget.replacingOccurrences(of: ",", with: ""))
            let bTarget = bTargetLocal != nil ? CurrencyManager.shared.baseAmount(fromConverted: bTargetLocal!) : nil
            
            struct UpdateBoutiqueTarget: Codable {
                let daily_sales_target: Double?
            }
            
            let bUpdate = UpdateBoutiqueTarget(daily_sales_target: bTarget)
            try await SupabaseManager.shared.client
                .from("boutiques")
                .update(bUpdate)
                .eq("id", value: boutique.id)
                .execute()
            
            for staff in staffMembers {
                let sTargetText = editedStaffTargets[staff.id] ?? ""
                let sTargetLocal = Double(sTargetText.replacingOccurrences(of: ",", with: ""))
                let sTarget = sTargetLocal != nil ? CurrencyManager.shared.baseAmount(fromConverted: sTargetLocal!) : nil
                
                struct UpdateStaffTarget: Codable {
                    let daily_sales_target: Double?
                }
                let sUpdate = UpdateStaffTarget(daily_sales_target: sTarget)
                
                try await SupabaseManager.shared.client
                    .from("staff")
                    .update(sUpdate)
                    .eq("id", value: staff.id)
                    .execute()
            }
            
            await MainActor.run {
                self.saveSuccessMessage = "Targets updated successfully."
                self.isSaving = false
            }
            
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run { self.saveSuccessMessage = nil }
            
        } catch {
            print("Failed to save targets: \(error)")
            await MainActor.run { isSaving = false }
        }
    }
}
