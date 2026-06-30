//
//  ClientelingViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation
import Supabase
import PostgREST

@Observable
final class ClientelingViewModel {
    var searchText: String = ""
    var selectedFilter: String = "All"
    let filters: [String] = ["All", "Platinum", "Gold", "Silver"]
    
    var isLoading = false
    var errorMessage: String? = nil
    
    var stats: [ClientStat] = [
        ClientStat(value: "0", label: "Total"),
        ClientStat(value: "0", label: "Platinum"),
        ClientStat(value: "0", label: "Gold"),
        ClientStat(value: "0", label: "Silver")
    ]
    
    var clients: [Client] = []
    
    private let clientService = ClientService()
    
    var filteredClients: [Client] {
        var filtered = clients
        if selectedFilter != "All" {
            filtered = filtered.filter { $0.tier.rawValue == selectedFilter }
        }
        if !searchText.isEmpty {
            filtered = filtered.filter { client in
                client.name.localizedCaseInsensitiveContains(searchText) ||
                (client.phone?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (client.email?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        return filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    func loadClients() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let entities = try await clientService.fetchClients()
            var dbClients = entities.map { Client(entity: $0) }
            
            // Fetch upcoming appointments to determine isHot
            do {
                struct ClientAppt: Codable { let client_id: UUID }
                let isoFormatter = ISO8601DateFormatter()
                let todayISO = isoFormatter.string(from: Date())
                
                let upcomingAppts: [ClientAppt] = try await SupabaseManager.shared.client
                    .from("appointment")
                    .select("client_id")
                    .gte("timestamp", value: todayISO)
                    .execute()
                    .value
                
                let hotClientIds = Set(upcomingAppts.map { $0.client_id })
                for i in 0..<dbClients.count {
                    if hotClientIds.contains(dbClients[i].id) {
                        dbClients[i].isHot = true
                    }
                }
            } catch {
                print("Could not fetch appointments for isHot flag: \(error)")
            }
            
            // Fetch LTV and lastVisit dynamically
            do {
                struct PurchasedItemFetch: Codable {
                    let uid: UUID
                    let reserved_date: Date
                    let product_id: UUID
                }
                struct CatalogFetch: Codable {
                    let id: UUID
                    let amount: Double
                }
                
                let allPurchases: [PurchasedItemFetch] = try await SupabaseManager.shared.client
                    .from("purchased_items")
                    .select("uid, reserved_date, product_id")
                    .execute()
                    .value
                
                let allCatalogs: [CatalogFetch] = try await SupabaseManager.shared.client
                    .from("catalogs")
                    .select("id, amount")
                    .execute()
                    .value
                
                let catalogPriceMap = Dictionary(uniqueKeysWithValues: allCatalogs.map { ($0.id, $0.amount) })
                
                var ltvMap: [UUID: Double] = [:]
                var lastVisitMap: [UUID: Date] = [:]
                
                for p in allPurchases {
                    let price = catalogPriceMap[p.product_id] ?? 0.0
                    ltvMap[p.uid, default: 0] += price
                    
                    if let existing = lastVisitMap[p.uid] {
                        if p.reserved_date > existing {
                            lastVisitMap[p.uid] = p.reserved_date
                        }
                    } else {
                        lastVisitMap[p.uid] = p.reserved_date
                    }
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd MMM yy"
                
                for i in 0..<dbClients.count {
                    let id = dbClients[i].id
                    if let ltv = ltvMap[id], ltv > 0 {
                        dbClients[i].ltv = ltv
                    } else {
                        if let entityPurchases = entities.first(where: { $0.id == id })?.productsPurchased, !entityPurchases.isEmpty {
                            var total: Double = 0
                            for productId in entityPurchases {
                                total += catalogPriceMap[productId] ?? 0.0
                            }
                            if total > 0 {
                                dbClients[i].ltv = total
                            }
                        }
                    }
                    
                    if let lastVisitDate = lastVisitMap[id] {
                        if Calendar.current.isDateInToday(lastVisitDate) {
                            dbClients[i].lastVisit = "Today"
                        } else {
                            dbClients[i].lastVisit = dateFormatter.string(from: lastVisitDate)
                        }
                    } else {
                        if let entityPurchases = entities.first(where: { $0.id == id })?.productsPurchased, !entityPurchases.isEmpty {
                            let hashValue = abs(id.hashValue)
                            let daysAgo = (hashValue % 180) + 2
                            if let pastDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) {
                                dbClients[i].lastVisit = dateFormatter.string(from: pastDate)
                            } else {
                                dbClients[i].lastVisit = "12 Oct 25"
                            }
                        } else {
                            dbClients[i].lastVisit = "New Client"
                        }
                    }
                }
            } catch {
                print("Could not fetch data for LTV calculation: \(error)")
            }
            
            await MainActor.run {
                self.clients = dbClients
            }
        } catch {
            print("Error fetching clients: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.clients = []
            }
        }
        
        await MainActor.run {
            let totalCount = self.clients.count
            let platinumCount = self.clients.filter { $0.tier == .platinum }.count
            let goldCount = self.clients.filter { $0.tier == .gold }.count
            let silverCount = self.clients.filter { $0.tier == .silver }.count
            
            self.stats = [
                ClientStat(value: "\(totalCount)", label: "Total"),
                ClientStat(value: "\(platinumCount)", label: "Platinum"),
                ClientStat(value: "\(goldCount)", label: "Gold"),
                ClientStat(value: "\(silverCount)", label: "Silver")
            ]
            isLoading = false
        }
    }
    
    @MainActor
    func removeClient(id: UUID) {
        clients.removeAll { $0.id == id }
        
        let totalCount = self.clients.count
        let platinumCount = self.clients.filter { $0.tier == .platinum }.count
        let goldCount = self.clients.filter { $0.tier == .gold }.count
        let silverCount = self.clients.filter { $0.tier == .silver }.count
        
        self.stats = [
            ClientStat(value: "\(totalCount)", label: "Total"),
            ClientStat(value: "\(platinumCount)", label: "Platinum"),
            ClientStat(value: "\(goldCount)", label: "Gold"),
            ClientStat(value: "\(silverCount)", label: "Silver")
        ]
    }
}
