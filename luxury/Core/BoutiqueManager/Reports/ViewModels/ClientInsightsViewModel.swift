//
//  ClientInsightsViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation
import Supabase

@Observable
final class ClientInsightsViewModel {
    var totalClients: Int = 0
    var avgLTV: String = "\(CurrencyManager.shared.symbol)0"
    var tierBreakdown: [TierMetric] = []
    var clients: [ClientEntity] = []
    
    var isLoading = false
    
    func fetchData() {
        isLoading = true
        Task {
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
                
                let client = SupabaseManager.shared.client
                let clients: [ClientEntity] = try await client.from("client").select().execute().value
                var query = client.from("transaction").select()
                if let boutiqueId = bId {
                    query = query.eq("boutique_id", value: boutiqueId)
                }
                let txs: [SATransactionEntity] = try await query.execute().value
                
                let boutiqueClientIds = Set(txs.compactMap { $0.clientId })
                let boutiqueClients: [ClientEntity]
                if bId == nil {
                    boutiqueClients = clients
                } else {
                    boutiqueClients = clients.filter { boutiqueClientIds.contains($0.id) }
                }
                
                var platinumCount = 0
                var goldCount = 0
                var silverCount = 0
                
                var platinumRevenue = 0.0
                var goldRevenue = 0.0
                var silverRevenue = 0.0
                
                for c in boutiqueClients {
                    let clientTxs = txs.filter { $0.clientId == c.id }
                    let clientTotal = clientTxs.reduce(0.0) { $0 + $1.transactionAmount }
                    
                    let tierString = (c.tier ?? "Silver").lowercased()
                    if tierString.contains("platinum") {
                        platinumCount += 1
                        platinumRevenue += clientTotal
                    } else if tierString.contains("gold") {
                        goldCount += 1
                        goldRevenue += clientTotal
                    } else {
                        silverCount += 1
                        silverRevenue += clientTotal
                    }
                }
                
                let totalClientsCount = boutiqueClients.count
                let overallRevenue = txs.reduce(0.0) { $0 + $1.transactionAmount }
                let avg = totalClientsCount > 0 ? overallRevenue / Double(totalClientsCount) : 0.0
                
                let newTierBreakdown = [
                    TierMetric(tier: "Platinum", count: platinumCount, revenue: CurrencyManager.shared.format(amount: platinumRevenue)),
                    TierMetric(tier: "Gold", count: goldCount, revenue: CurrencyManager.shared.format(amount: goldRevenue)),
                    TierMetric(tier: "Silver", count: silverCount, revenue: CurrencyManager.shared.format(amount: silverRevenue))
                ]
                
                await MainActor.run {
                    self.totalClients = totalClientsCount
                    self.avgLTV = CurrencyManager.shared.format(amount: avg)
                    self.tierBreakdown = newTierBreakdown
                    self.clients = boutiqueClients
                    self.isLoading = false
                }
            } catch {
                print("Failed to fetch client insights: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}
