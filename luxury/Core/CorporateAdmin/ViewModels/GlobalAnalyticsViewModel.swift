//
//  GlobalAnalyticsViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 18/05/26.
//

import SwiftUI
import Observation
import Supabase

@Observable
final class GlobalAnalyticsViewModel {
    var isLoading = false
    var errorMessage: String?
    
    var kpis: [GlobalKPI] = []
    
    var revenueChartData: [RevenueData] = []
    
    var boutiquePerformance: [CorporateBoutique] = []
    var sfsFulfillments: [PurchasedItemEntity] = []
    private var sfsPollingTask: Task<Void, Never>?
    
    private let client = SupabaseManager.shared.client
    
    func fetchData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            var boutiquesResponse: [CorporateBoutique] = []
            var staffResponse: [StaffModel] = []
            var catalogs: [CatalogEntity] = []
            var transactions: [SATransactionEntity] = []
            
            do {
                boutiquesResponse = try await client.from("boutiques").select().eq("status", value: "approved").execute().value
            } catch {
                print("Boutiques fetch error: \(error)")
            }
            
            do {
                staffResponse = try await client.from("staff").select().execute().value
            } catch {
                print("Staff fetch error: \(error)")
            }
            
            do {
                catalogs = try await client.from("catalogs").select().execute().value
            } catch {
                print("Catalogs fetch error: \(error)")
            }
            
            do {
                var offset = 0
                let limit = 1000
                var hasMore = true
                while hasMore {
                    let batch: [SATransactionEntity] = try await client.from("transaction")
                        .select()
                        .range(from: offset, to: offset + limit - 1)
                        .execute()
                        .value
                    
                    transactions.append(contentsOf: batch)
                    if batch.count < limit {
                        hasMore = false
                    } else {
                        offset += limit
                    }
                }
            } catch {
                print("Transaction fetch error: \(error)")
            }
            
            // Calculate inventory value
            var totalInventoryValue = 0.0
            var stockDict: [UUID: Int] = [:]
            
            if let allUnits = try? await InventoryService.shared.fetchAllInventoryUnits() {
                for unit in allUnits where unit.status == .available {
                    stockDict[unit.catalogId, default: 0] += 1
                }
            }
            
            for item in catalogs {
                let totalStock = stockDict[item.id] ?? 0
                if totalStock > 0 {
                    totalInventoryValue += (item.amount * Double(totalStock))
                }
            }
            
            let now = Date()
            let calendar = Calendar.current
            
            var totalRevenue = 0.0
            
            for tx in transactions {
                totalRevenue += tx.transactionAmount
            }
            
            // Trend logic removed per user request
            
            // Format daily revenue chart data for dashboard glimpse
            var dailyChartData: [RevenueData] = []
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEE" // Mon, Tue...
            
            for i in (0..<7).reversed() {
                if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                    let label = dayFormatter.string(from: date)
                    let startOfDay = calendar.startOfDay(for: date)
                    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                    
                    let dailyTotal = transactions.filter { tx in
                        guard let txDate = tx.dateOfTransaction else { return false }
                        return txDate >= startOfDay && txDate < endOfDay
                    }.reduce(0.0) { $0 + $1.transactionAmount }
                    
                    dailyChartData.append(RevenueData(month: label, amount: dailyTotal))
                }
            }
            
            let newKpis = [
                GlobalKPI(label: "Global Revenue", type: .currency(totalRevenue), icon: "chart.line.uptrend.xyaxis"),
                GlobalKPI(label: "Active Boutiques", type: .string("\(boutiquesResponse.count)"), icon: "building.2.fill"),
                GlobalKPI(label: "Total Staff", type: .string("\(staffResponse.count)"), icon: "person.3.fill"),
                GlobalKPI(label: "Inventory Value", type: .currency(totalInventoryValue), icon: "shippingbox.fill")
            ]
            
            await MainActor.run {
                self.boutiquePerformance = boutiquesResponse
                self.kpis = newKpis
                self.revenueChartData = dailyChartData
                self.isLoading = false
            }
        }
    }

    func fetchSFSFulfillments() async {
        do {
            let items: [PurchasedItemEntity] = try await client
                .from("purchased_items")
                .select()
                .execute()
                .value
            
            let products: [CatalogEntity] = try await client
                .from("catalogs")
                .select()
                .execute()
                .value
            
            var resolved: [PurchasedItemEntity] = []
            for var item in items {
                if let product = products.first(where: { $0.id == item.productId }) {
                    item.productName = product.name
                    item.productBrand = product.brand
                    item.productSku = product.catalogId
                }
                resolved.append(item)
            }
            
            let sorted = resolved.sorted(by: { $0.reservedDate > $1.reservedDate })
            
            await MainActor.run {
                self.sfsFulfillments = sorted
            }
        } catch {
            print("Failed to fetch SFS fulfillments: \(error)")
        }
    }

    func startFulfillmentPolling() {
        sfsPollingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                await self?.fetchSFSFulfillments()
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    func stopFulfillmentPolling() {
        sfsPollingTask?.cancel()
        sfsPollingTask = nil
    }
}
