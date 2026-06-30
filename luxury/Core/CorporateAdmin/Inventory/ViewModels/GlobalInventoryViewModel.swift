//
//  GlobalInventoryViewModel.swift
//  luxury
//
//  Created by Nalinish Ranjan on 22/05/26.
//

import Foundation
import Observation
import PostgREST
import Supabase

@Observable
final class GlobalInventoryViewModel {
    var searchText: String = ""
    var filterStatus: StockAlertStatus? = nil
    
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
    
    func fetchData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let catalogsResponse = try await CatalogService().fetchCatalogs()
                let boutiquesResponse: [CorporateBoutique] = try await client.from("boutiques").select().execute().value
                let units = try await InventoryService.shared.fetchAllInventoryUnits()
                
                // Precompute grouped units
                let availableUnits = units.filter { $0.status == .available }
                let unitsByCatalog = Dictionary(grouping: availableUnits, by: { $0.catalogId })
                let boutiqueDict = Dictionary(uniqueKeysWithValues: boutiquesResponse.map { ($0.id, $0) })
                
                var newSummaries: [ProductInventorySummary] = []
                
                for catalog in catalogsResponse {
                    let catalogUnits = unitsByCatalog[catalog.id] ?? []
                    let totalQty = catalogUnits.count
                    
                    let unitsByBoutique = Dictionary(grouping: catalogUnits, by: { $0.boutiqueId })
                    var locations: [LocationInventoryDetail] = []
                    
                    for (bId, bUnits) in unitsByBoutique {
                        locations.append(LocationInventoryDetail(
                            storeId: bId,
                            storeName: boutiqueDict[bId]?.name ?? "Unknown Boutique",
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
                
                await MainActor.run {
                    self.summaries = newSummaries.sorted(by: { $0.product.name < $1.product.name })
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to load inventory: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
}
