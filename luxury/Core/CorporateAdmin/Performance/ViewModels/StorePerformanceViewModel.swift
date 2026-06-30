//
//  StorePerformanceViewModel.swift
//  luxury
//
//  Created by Kaushiki Rai on 26/05/26.
//

//
//  StorePerformanceViewModel.swift
//  luxury
//
//  Created by Kaushiki Rai on 26/05/26.
//

import Foundation
import Observation
import Supabase

struct BoutiquePerformance: Identifiable, Hashable {
    static func == (lhs: BoutiquePerformance, rhs: BoutiquePerformance) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: UUID
    let boutiqueName: String
    let city: String
    let totalSales: Double
    let salesTarget: Double
    let totalWalkIns: Int
    let convertedCustomers: Int
    let totalTransactions: Int
    let associates: [AssociatePerformance]

    var achievementPct: Double   { salesTarget > 0 ? (totalSales / salesTarget) * 100 : 0 }
    var conversionRate: Double   { totalWalkIns > 0 ? (Double(convertedCustomers) / Double(totalWalkIns)) * 100 : 0 }
    var atv: Double              { totalTransactions > 0 ? totalSales / Double(totalTransactions) : 0 }
    var isUnderperforming: Bool  { achievementPct < 80 }
}

struct AssociatePerformance: Identifiable, Hashable {
    static func == (lhs: AssociatePerformance, rhs: AssociatePerformance) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: UUID
    let name: String
    let totalSales: Double
    let transactions: Int
    let walkIns: Int
    let converted: Int

    var conversionRate: Double { walkIns > 0 ? (Double(converted) / Double(walkIns)) * 100 : 0 }
    var abv: Double            { transactions > 0 ? totalSales / Double(transactions) : 0 }
}

@Observable
final class StorePerformanceViewModel {
    var boutiques: [BoutiquePerformance] = []
    var isLoading = false

    func fetchData() {
        isLoading = true
        Task {
            do {
                let client = SupabaseManager.shared.client
                
                // Fetch boutiques
                let boutiquesResponse: [CorporateBoutique] = try await client.from("boutiques").select().eq("status", value: "approved").execute().value
                
                // Fetch staff
                let staffResponse: [StaffModel] = try await client.from("staff").select().execute().value
                
                // Fetch transactions
                let txs: [SATransactionEntity] = try await client.from("transaction").select().execute().value
                
                // Fetch appointments
                let appointments: [AppointmentEntity] = try await client.from("appointment").select().execute().value
                
                var newBoutiques: [BoutiquePerformance] = []
                
                for b in boutiquesResponse {
                    let boutiqueStaff = staffResponse.filter { $0.boutiqueId == b.id }
                    let boutiqueTxs = txs.filter { $0.boutiqueId == b.id }
                    
                    let totalSales = boutiqueTxs.reduce(0.0) { $0 + $1.transactionAmount }
                    let totalTransactions = boutiqueTxs.count
                    
                    // For converted customers, count unique clients in transactions for this boutique
                    let uniqueClients = Set(boutiqueTxs.compactMap { $0.clientId })
                    let convertedCustomers = uniqueClients.count
                    
                    // Walk-ins can be considered in_store appointments at this boutique
                    let boutiqueAppts = appointments.filter { $0.boutiqueId == b.id && $0.appointmentType == .inStore }
                    let totalWalkIns = boutiqueAppts.count
                    
                    var associatePerformances: [AssociatePerformance] = []
                    
                    for staff in boutiqueStaff {
                        let staffTxs = boutiqueTxs.filter { $0.staffId == staff.id }
                        let staffTotalSales = staffTxs.reduce(0.0) { $0 + $1.transactionAmount }
                        let staffTxCount = staffTxs.count
                        
                        let staffAppts = appointments.filter { $0.assignedTo == staff.id && $0.appointmentType == .inStore }
                        let staffWalkIns = staffAppts.count
                        
                        let staffUniqueClients = Set(staffTxs.compactMap { $0.clientId })
                        let staffConverted = staffUniqueClients.count
                        
                        associatePerformances.append(
                            AssociatePerformance(
                                id: staff.id,
                                name: staff.name,
                                totalSales: staffTotalSales,
                                transactions: staffTxCount,
                                walkIns: staffWalkIns,
                                converted: staffConverted
                            )
                        )
                    }
                    
                    let salesTarget = b.dailySalesTarget ?? 500000.0 // fallback if no target set
                    
                    newBoutiques.append(
                        BoutiquePerformance(
                            id: b.id,
                            boutiqueName: b.name,
                            city: b.city,
                            totalSales: totalSales,
                            salesTarget: salesTarget,
                            totalWalkIns: totalWalkIns,
                            convertedCustomers: convertedCustomers,
                            totalTransactions: totalTransactions,
                            associates: associatePerformances
                        )
                    )
                }
                
                await MainActor.run {
                    self.boutiques = newBoutiques
                    self.isLoading = false
                }
            } catch {
                print("Failed to fetch store performance: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }

    private static func mockData() -> [BoutiquePerformance] {
        [
            BoutiquePerformance(
                id: UUID(), boutiqueName: "Maison Mumbai", city: "Mumbai",
                totalSales: 4_20_000, salesTarget: 5_00_000,
                totalWalkIns: 120, convertedCustomers: 46,
                totalTransactions: 46,
                associates: [
                    AssociatePerformance(id: UUID(), name: "Arjun Singh",   totalSales: 2_10_000, transactions: 23, walkIns: 60, converted: 26),
                    AssociatePerformance(id: UUID(), name: "Priya Sharma",  totalSales: 1_10_000, transactions: 13, walkIns: 34, converted: 12),
                    AssociatePerformance(id: UUID(), name: "Rahul Mehta",   totalSales: 1_00_000, transactions: 10, walkIns: 26, converted: 8)
                ]
            ),
            BoutiquePerformance(
                id: UUID(), boutiqueName: "Maison Delhi", city: "New Delhi",
                totalSales: 6_80_000, salesTarget: 7_00_000,
                totalWalkIns: 95, convertedCustomers: 52,
                totalTransactions: 52,
                associates: [
                    AssociatePerformance(id: UUID(), name: "Neha Kapoor",   totalSales: 3_40_000, transactions: 26, walkIns: 48, converted: 28),
                    AssociatePerformance(id: UUID(), name: "Unknown Client",   totalSales: 2_20_000, transactions: 16, walkIns: 30, converted: 16),
                    AssociatePerformance(id: UUID(), name: "Aditi Rao",     totalSales: 1_20_000, transactions: 10, walkIns: 17, converted: 8)
                ]
            ),
            BoutiquePerformance(
                id: UUID(), boutiqueName: "Maison Bangalore", city: "Bengaluru",
                totalSales: 2_10_000, salesTarget: 4_50_000,
                totalWalkIns: 80, convertedCustomers: 22,
                totalTransactions: 22,
                associates: [
                    AssociatePerformance(id: UUID(), name: "Karan Joshi",   totalSales: 1_20_000, transactions: 12, walkIns: 44, converted: 12),
                    AssociatePerformance(id: UUID(), name: "Sneha Pillai",  totalSales:   90_000, transactions: 10, walkIns: 36, converted: 10)
                ]
            ),
            BoutiquePerformance(
                id: UUID(), boutiqueName: "Maison Chennai", city: "Chennai",
                totalSales: 5_10_000, salesTarget: 5_00_000,
                totalWalkIns: 110, convertedCustomers: 64,
                totalTransactions: 64,
                associates: [
                    AssociatePerformance(id: UUID(), name: "Divya Menon",   totalSales: 2_60_000, transactions: 32, walkIns: 55, converted: 34),
                    AssociatePerformance(id: UUID(), name: "Arun Balaji",   totalSales: 2_50_000, transactions: 32, walkIns: 55, converted: 30)
                ]
            )
        ]
    }
}
