//
//  StockViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation
import Supabase

@Observable
final class StockViewModel {
    var totalItems: String = "0"
    var lowStockCount: String = "0"
    var outOfStockCount: String = "0"
    
    var sfsOrdersCount: String = "0"
    
    var resolvedSkus: Set<String> = []
    var alerts: [InventoryAlert] = []
    
    init() {
        if let array = UserDefaults.standard.stringArray(forKey: "luxury_resolved_skus") {
            self.resolvedSkus = Set(array)
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("SFSOrderReceived"), object: nil, queue: .main) { [weak self] _ in
            self?.fetchSFSCount()
            self?.fetchInventoryStats()
        }
    }
    
    func fetchInventoryStats() {
        Task {
            do {
                let catalogs = try await CatalogService().fetchCatalogs()
                
                var stockDict: [UUID: Int] = [:]
                if let profileTuple = try? await ProfileService().fetchCurrentProfile(),
                   let staff = profileTuple.1 as? StaffModel,
                   let boutiqueId = staff.boutiqueId {
                    stockDict = try await InventoryService.shared.fetchAvailableStockDictionary(forBoutique: boutiqueId)
                }
                
                var total = 0
                var lowStock = 0
                var outOfStock = 0
                var newAlerts: [InventoryAlert] = []
                
                for catalog in catalogs {
                    let available = stockDict[catalog.id] ?? 0
                    
                    total += available
                    
                    if resolvedSkus.contains(catalog.catalogId) {
                        continue
                    }
                    
                    if available == 0 {
                        outOfStock += 1
                        newAlerts.append(InventoryAlert(
                            itemName: catalog.name,
                            sku: catalog.catalogId,
                            currentQty: available,
                            status: .error,
                            location: "Vault Room A",
                            alertType: "Out of Stock",
                            timeRaised: "10 mins ago",
                            urgency: .critical
                        ))
                    } else if available < 3 {
                        lowStock += 1
                        newAlerts.append(InventoryAlert(
                            itemName: catalog.name,
                            sku: catalog.catalogId,
                            currentQty: available,
                            status: .warning,
                            location: "Showcase C",
                            alertType: "Low Stock",
                            timeRaised: "1 hour ago",
                            urgency: .warning
                        ))
                    }
                }
                
                let finalTotal = total
                let finalLowStock = lowStock
                let finalOutOfStock = outOfStock
                let finalAlerts = newAlerts.sorted(by: { $0.urgency < $1.urgency })
                
                await MainActor.run {
                    self.totalItems = "\(finalTotal)"
                    self.lowStockCount = "\(finalLowStock)"
                    self.outOfStockCount = "\(finalOutOfStock)"
                    self.alerts = finalAlerts
                }
            } catch {
                print("Failed to fetch inventory stats: \(error)")
            }
        }
    }
    
    func resolveAlert(_ alert: InventoryAlert) {
        resolvedSkus.insert(alert.sku)
        UserDefaults.standard.set(Array(resolvedSkus), forKey: "luxury_resolved_skus")
        alerts.removeAll { $0.id == alert.id }
        
        if alert.currentQty == 0 {
            if let count = Int(outOfStockCount), count > 0 {
                outOfStockCount = "\(count - 1)"
            }
        } else if alert.currentQty < 3 {
            if let count = Int(lowStockCount), count > 0 {
                lowStockCount = "\(count - 1)"
            }
        }
    }
    
    func fetchSFSCount() {
        Task {
            do {
                var query = SupabaseManager.shared.client
                    .from("purchased_items")
                    .select()
                    .eq("status", value: "Pending")
                
                if let profileTuple = try? await ProfileService().fetchCurrentProfile(),
                   let staff = profileTuple.1 as? StaffModel,
                   let boutiqueId = staff.boutiqueId {
                    query = query.eq("boutique_id", value: boutiqueId.uuidString)
                }
                
                let items: [PurchasedItemEntity] = try await query.execute().value
                
                await MainActor.run {
                    self.sfsOrdersCount = "\(items.count)"
                }
            } catch {
            }
        }
    }
}
