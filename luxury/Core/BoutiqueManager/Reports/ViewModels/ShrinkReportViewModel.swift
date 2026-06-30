//
//  ShrinkReportViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation
import Supabase

@Observable
final class ShrinkReportViewModel {
    var searchText: String = ""
    var filterStatus: StockAlertStatus? = nil
    
    var totalShrinkValue: String = "\(CurrencyManager.shared.symbol)0"
    var accuracy: String = (1.0).formatted(.percent.precision(.fractionLength(1)))
    var recentWriteOffs: [RSMSVarianceItem] = []
    
    var summaries: [ProductInventorySummary] = []
    
    var isLoading = false
    var errorMessage: String?
    
    private let client = SupabaseManager.shared.client
    
    var filteredSummaries: [ProductInventorySummary] {
        var result = summaries
        
        if let filterStatus = filterStatus {
            result = result.filter { $0.alertStatus == filterStatus }
        }
        
        if !searchText.isEmpty {
            result = result.filter { summary in
                summary.product.name.localizedCaseInsensitiveContains(searchText) ||
                summary.product.brand.localizedCaseInsensitiveContains(searchText) ||
                summary.product.catalogId.localizedCaseInsensitiveContains(searchText) ||
                summary.product.barCode.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    var totalItemsCount: Int {
        summaries.reduce(0) { $0 + $1.totalQuantity }
    }
    
    var totalInventoryValue: Double {
        summaries.reduce(0.0) { $0 + ($1.product.amount * Double($1.totalQuantity)) }
    }
    
    var lowStockCount: Int {
        summaries.filter { $0.alertStatus == .lowStock }.count
    }
    
    var outOfStockCount: Int {
        summaries.filter { $0.alertStatus == .outOfStock }.count
    }
    
    func fetchInventory() {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
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
                
                let catalogsResponse = try await CatalogService().fetchCatalogs()
                let boutiquesResponse: [CorporateBoutique] = try await client.from("boutiques").select().execute().value
                
                let allUnits: [InventoryUnitEntity]
                if let boutiqueId = bId {
                    allUnits = try await InventoryService.shared.fetchInventory(forBoutique: boutiqueId)
                } else {
                    allUnits = try await InventoryService.shared.fetchAllInventoryUnits()
                }
                
                let availableUnits = allUnits.filter { $0.status == .available }
                let unitsByCatalog = Dictionary(grouping: availableUnits, by: { $0.catalogId })
                let boutiqueDict = Dictionary(uniqueKeysWithValues: boutiquesResponse.map { ($0.id, $0) })
                
                var newSummaries: [ProductInventorySummary] = []
                
                for catalog in catalogsResponse {
                    let catalogUnits = unitsByCatalog[catalog.id] ?? []
                    let totalQty = catalogUnits.count
                    
                    let unitsByBoutique = Dictionary(grouping: catalogUnits, by: { $0.boutiqueId })
                    var locations: [LocationInventoryDetail] = []
                    
                    for (locId, bUnits) in unitsByBoutique {
                        locations.append(LocationInventoryDetail(
                            storeId: locId,
                            storeName: boutiqueDict[locId]?.name ?? "Unknown Boutique",
                            quantity: bUnits.count,
                            isAvailable: true
                        ))
                    }
                    
                    newSummaries.append(ProductInventorySummary(
                        product: catalog,
                        totalQuantity: totalQty,
                        locations: locations
                    ))
                }
                
                var auditsQuery = client.from("audits").select()
                if let boutiqueId = bId {
                    auditsQuery = auditsQuery.eq("boutique_id", value: boutiqueId)
                }
                
                let audits: [DBStoreAudit] = (try? await auditsQuery
                    .order("created_at", ascending: false)
                    .execute()
                    .value) ?? []
                
                let totalVariance = audits.reduce(0) { $0 + $1.variance }
                let avgPrice: Double = catalogsResponse.isEmpty ? 0 : catalogsResponse.reduce(0.0) { $0 + $1.amount } / Double(catalogsResponse.count)
                let shrinkUnits = abs(min(totalVariance, 0))
                let shrinkValue = Double(shrinkUnits) * avgPrice
                
                let completedAudits = audits.filter { $0.status == .signedOff || $0.status == .inProgress }
                let avgAccuracy: Double
                if completedAudits.isEmpty {
                    avgAccuracy = 1.0
                } else {
                    avgAccuracy = completedAudits.reduce(0.0) { $0 + $1.accuracy } / Double(completedAudits.count) / 100.0
                }
                
                var writeOffs: [RSMSVarianceItem] = []
                for audit in audits {
                    guard let discrepancies = audit.discrepancies else { continue }
                    for disc in discrepancies {
                        let isMissing = (disc.type ?? "missing").lowercased() == "missing"
                        writeOffs.append(RSMSVarianceItem(
                            name: disc.name ?? "Unknown Item",
                            expected: isMissing ? 1 : 0,
                            actual: isMissing ? 0 : 1,
                            reason: disc.detail ?? "No details provided"
                        ))
                    }
                }
                let recentItems = Array(writeOffs.prefix(10))
                
                await MainActor.run {
                    self.summaries = newSummaries.sorted(by: { $0.product.name < $1.product.name })
                    self.totalShrinkValue = CurrencyManager.shared.format(amount: shrinkValue)
                    self.accuracy = avgAccuracy.formatted(.percent.precision(.fractionLength(1)))
                    self.recentWriteOffs = recentItems
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to load inventory: \(error.localizedDescription)")
                    self.isLoading = false
                    print("Error fetching inventory: \(error)")
                }
            }
        }
    }
}
