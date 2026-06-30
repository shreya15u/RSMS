//
//  StockSearchViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation
import Supabase
import PostgREST

@Observable
final class StockSearchViewModel {
    var searchText: String = ""
    var stockItems: [StockItem] = []
    
    func fetchItems() {
        Task {
            do {
                let catalogs = try await CatalogService().fetchCatalogs()
                
                var stockDict: [UUID: Int] = [:]
                if let profileTuple = try? await ProfileService().fetchCurrentProfile(),
                   let staff = profileTuple.1 as? StaffModel,
                   let boutiqueId = staff.boutiqueId {
                    stockDict = try await InventoryService.shared.fetchAvailableStockDictionary(forBoutique: boutiqueId)
                }
                
                var newItems: [StockItem] = []
                for catalog in catalogs {
                    let available = stockDict[catalog.id] ?? 0
                    
                    newItems.append(StockItem(
                        brand: catalog.brand,
                        name: catalog.name,
                        qty: available,
                        rfid: true,
                        alert: available < 3
                    ))
                }
                
                await MainActor.run {
                    self.stockItems = newItems
                }
            } catch {
                print("Failed to fetch stock items: \(error)")
            }
        }
    }
    
    var filteredItems: [StockItem] {
        if searchText.isEmpty {
            return stockItems
        }
        return stockItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.brand.localizedCaseInsensitiveContains(searchText) }
    }
}
