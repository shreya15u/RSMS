//
//  StaffPerformanceViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation
import Supabase

@Observable
final class StaffPerformanceViewModel {
    var staffMetrics: [StaffMetric] = []
    var isLoading = false
    
    func fetchData() async {
        await MainActor.run { isLoading = true }
        do {
            guard let profileTuple = try? await ProfileService().fetchCurrentProfile() else {
                await MainActor.run { isLoading = false }
                return
            }
            
            let bId: UUID?
            if let staff = profileTuple.1 as? StaffModel, let boutiqueId = staff.boutiqueId {
                bId = boutiqueId
            } else if let boutique = profileTuple.1 as? CorporateBoutique {
                bId = boutique.id
            } else if profileTuple.0 == .corporateAdmin {
                bId = nil
            } else {
                await MainActor.run { isLoading = false }
                return
            }
            
            // Fetch all staff in this boutique
            var staffQuery = SupabaseManager.shared.client.from("staff").select()
            if let boutiqueId = bId {
                staffQuery = staffQuery.eq("boutique_id", value: boutiqueId)
            }
            let allStaff: [StaffModel] = (try? await staffQuery.execute().value) ?? []
                
            // Fetch all transactions for this boutique
            var txQuery = SupabaseManager.shared.client.from("transaction").select()
            if let boutiqueId = bId {
                txQuery = txQuery.eq("boutique_id", value: boutiqueId)
            }
            let txs: [SATransactionEntity] = (try? await txQuery.execute().value) ?? []
                
            // Fetch appointments and filter by staff in this boutique
            let staffIds = Set(allStaff.map { $0.id })
            let appts: [AppointmentEntity] = try await SupabaseManager.shared.client
                .from("appointment")
                .select()
                .execute()
                .value
            let boutiqueAppts = appts.filter { appt in
                if let assignedTo = appt.assignedTo {
                    return staffIds.contains(assignedTo)
                }
                return false
            }
                
            var newMetrics: [StaffMetric] = []
            
            for s in allStaff {
                if s.role != .salesAssociate { continue }
                let sTxs = txs.filter { $0.staffId == s.id }
                let sAppts = boutiqueAppts.filter { $0.assignedTo == s.id }
                
                let revenue = sTxs.reduce(0.0) { $0 + $1.transactionAmount }
                
                // Commission: derive from target achievement percentage
                // If staff has a daily sales target, commission scales with performance
                let target = s.dailySalesTarget ?? 0
                let commission: Double
                if target > 0 {
                    let achievement = min(revenue / target, 2.0)  // Cap at 200%
                    commission = revenue * (0.03 + achievement * 0.02) // 3-7% sliding scale
                } else {
                    commission = revenue * 0.05 // Default 5% if no target set
                }
                
                let interactions = sAppts.count + sTxs.count
                let conversion = interactions > 0 ? Double(sTxs.count) / Double(interactions) : 0.0
                
                newMetrics.append(StaffMetric(
                    name: s.name,
                    commission: CurrencyManager.shared.format(amount: commission),
                    conversion: "\(Int(round(conversion * 100.0)))%",
                    interactions: interactions
                ))
            }
            
            await MainActor.run {
                self.staffMetrics = newMetrics.sorted { $0.interactions > $1.interactions }
                self.isLoading = false
            }
        } catch {
            print("Failed to fetch StaffPerformance: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
}
