//
//  SAProfileViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation
import Supabase

@Observable
final class SAProfileViewModel {
    var store: String = ""
    var greeting: String = ""
    var name: String = ""
    var avatarUrl: String?
    var boutiqueId: UUID?
    
    var revenue: Double = 0.0
    var target: Double = 0.0
    var progress: Double { min(1.0, max(0.0, target > 0 ? revenue / target : 0)) }
    
    var statClients: String = "0"
    var statTransactions: String = "0"
    var statAppts: String { "\(appointments.count)" }
    
    var appointments: [AppointmentEntity] = []
    
    var recentClients: [SADashClient] = []
    var recentTransactions: [SATransactionEntity] = []
    
    func fetchAppointments() async {
        do {
            if let (_, profile) = try await ProfileService().fetchCurrentProfile(),
               let staff = profile as? StaffModel {
                
                await MainActor.run {
                    self.name = staff.name
                    self.greeting = self.getGreeting() + ","
                    self.target = staff.dailySalesTarget ?? 0.0
                }
                
                if let boutiqueId = staff.boutiqueId {
                    struct MinimalBoutique: Codable { 
                        let name: String 
                        let currency: String?
                    }
                    if let boutiques: [MinimalBoutique] = try? await SupabaseManager.shared.client
                        .from("boutiques")
                        .select("name, currency")
                        .eq("id", value: boutiqueId)
                        .execute()
                        .value, let b = boutiques.first {
                        await MainActor.run {
                            self.store = b.name
                            self.boutiqueId = boutiqueId
                            if let curr = b.currency, !curr.isEmpty {
                                CurrencyManager.shared.currentCurrency = curr
                            }
                        }
                    }
                }
                
                let fetched: [AppointmentEntity] = try await SupabaseManager.shared.client
                    .from("appointment")
                    .select("*, client:client_id(*)")
                    .eq("assigned_to", value: staff.id)
                    .order("timestamp", ascending: false)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.appointments = fetched
                    self.name = staff.name
                    self.avatarUrl = staff.avatarUrl
                    
                    let hour = Calendar.current.component(.hour, from: Date())
                    if hour < 12 {
                        self.greeting = "Good morning,"
                    } else if hour < 17 {
                        self.greeting = "Good afternoon,"
                    } else {
                        self.greeting = "Good evening,"
                    }
                    
                    
                }
                
                await fetchStats(staffId: staff.id)
                await fetchRecentClients()
            }
        } catch {
            print("Failed to fetch appointments for SA profile: \(error)")
        }
    }
    
    private func fetchStats(staffId: UUID) async {
        do {
            let txs: [SATransactionEntity] = try await SupabaseManager.shared.client
                .from("transaction")
                .select("*, client:client_id(*)")
                .eq("staff_id", value: staffId)
                .order("date_of_transaction", ascending: false)
                .execute()
                .value
            
            let totalRevenue = txs.reduce(0.0) { $0 + $1.transactionAmount }
            
            // Extract unique clients
            var seenClients = Set<UUID>()
            var mappedClients: [SADashClient] = []
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            
            for tx in txs {
                guard let client = tx.client else { continue }
                if !seenClients.contains(client.id) {
                    seenClients.insert(client.id)
                    let visitStr = tx.dateOfTransaction.map { formatter.string(from: $0) } ?? "Unknown"
                    let initial = String(client.name.prefix(1)).uppercased()
                    let dashClient = SADashClient(
                        name: client.name,
                        tier: client.tier ?? "Standard",
                        lastVisit: visitStr,
                        ltv: totalRevenue, // simplified, ideally from client LTV
                        initial: initial.isEmpty ? "U" : initial
                    )
                    mappedClients.append(dashClient)
                }
            }
            
            await MainActor.run {
                self.revenue = totalRevenue
                self.statTransactions = "\(txs.count)"
                self.statClients = "\(mappedClients.count)"
                self.recentClients = mappedClients
                self.recentTransactions = txs
            }
        } catch {
            print("Failed to fetch stats: \(error)")
        }
    }
    
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
    
    private func fetchRecentClients() async {
        do {
            let service = ClientService()
            let allClients = try await service.fetchClients()
            let sorted = allClients.sorted { $0.createdAt > $1.createdAt }
            let recent = Array(sorted.prefix(5))
            
            let dashClients = recent.map { c in
                SADashClient(
                    name: c.name,
                    tier: c.tier ?? "Standard",
                    lastVisit: "Unknown",
                    ltv: 0.0,
                    initial: String(c.name.prefix(1))
                )
            }
            await MainActor.run {
                self.recentClients = dashClients
                self.statClients = "\(allClients.count)"
            }
        } catch {
            print("Failed to fetch recent clients: \(error)")
        }
    }
}
