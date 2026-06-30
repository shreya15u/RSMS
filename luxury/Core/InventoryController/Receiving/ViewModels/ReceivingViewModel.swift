//
//  ReceivingViewModel.swift
//  luxury
//
//  Created by Kaushiki Rai on 29/05/26.
//

import Foundation
import Observation
import Supabase

@Observable
final class ReceivingViewModel {
    var purchaseOrders: [PurchaseOrder] = []
    var isLoading = false
    var errorMessage: String?
    var matchedCatalogs: [CatalogEntity] = []
    
    private let profileService = ProfileService()
    
    func loadPurchaseOrders() {
        if let data = UserDefaults.standard.data(forKey: "luxury_purchase_orders"),
           let decoded = try? JSONDecoder().decode([PurchaseOrder].self, from: data) {
            self.purchaseOrders = decoded
            return
        }
        fetchCatalogsAndSeed()
    }
    
    func fetchCatalogsAndSeed() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetched: [CatalogEntity] = try await SupabaseManager.shared.client
                    .from("catalogs")
                    .select()
                    .execute()
                    .value
                
                await MainActor.run {
                    self.matchedCatalogs = fetched
                    self.seedMockOrders(with: fetched)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.seedMockOrders(with: [])
                    self.isLoading = false
                }
            }
        }
    }
    
    private func seedMockOrders(with catalogs: [CatalogEntity]) {
        var items1: [POItem] = []
        var items2: [POItem] = []
        
        if catalogs.count >= 2 {
            let cat1 = catalogs[0]
            let cat2 = catalogs[1]
            items1.append(POItem(brand: cat1.brand, name: cat1.name, sku: cat1.catalogId, expectedQty: 2))
            items1.append(POItem(brand: cat2.brand, name: cat2.name, sku: cat2.catalogId, expectedQty: 1))
        } else {
            items1.append(POItem(brand: "ROLEX", name: "Submariner Date", sku: "W-SUB-01", expectedQty: 2))
            items1.append(POItem(brand: "AUDEMARS PIGUET", name: "Royal Oak", sku: "W-RO-02", expectedQty: 1))
        }
        
        if catalogs.count >= 4 {
            let cat3 = catalogs[2]
            let cat4 = catalogs[3]
            items2.append(POItem(brand: cat3.brand, name: cat3.name, sku: cat3.catalogId, expectedQty: 1))
            items2.append(POItem(brand: cat4.brand, name: cat4.name, sku: cat4.catalogId, expectedQty: 3))
        } else {
            items2.append(POItem(brand: "CHANEL", name: "Classic Flap Bag", sku: "B-CF-03", expectedQty: 1))
            items2.append(POItem(brand: "LOUIS VUITTON", name: "Speedy 30", sku: "B-SP-04", expectedQty: 3))
        }
        
        let po1 = PurchaseOrder(poNumber: "PO-2026-001", supplier: "Rolex Distributor Ltd", items: items1)
        let po2 = PurchaseOrder(poNumber: "PO-2026-002", supplier: "Luxury Goods Corp", items: items2)
        
        self.purchaseOrders = [po1, po2]
        saveToUserDefaults()
    }
    
    func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(purchaseOrders) {
            UserDefaults.standard.set(encoded, forKey: "luxury_purchase_orders")
        }
    }
    
    func processScan(poId: UUID, code: String) -> ScanResult {
        guard let index = purchaseOrders.firstIndex(where: { $0.id == poId }) else {
            return .error("Purchase Order not found")
        }
        
        var po = purchaseOrders[index]
        if po.status == .fullyReceived {
            return .error("This Purchase Order is already fully received")
        }
        
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        var matchedCatalog: CatalogEntity? = matchedCatalogs.first { 
            $0.catalogId.lowercased() == trimmed.lowercased() || $0.barCode.lowercased() == trimmed.lowercased()
        }
        
        if matchedCatalog == nil {
            matchedCatalog = matchedCatalogs.first { 
                $0.name.lowercased().contains(trimmed.lowercased()) 
            }
        }
        
        guard let catalog = matchedCatalog else {
            return .unexpected(trimmed)
        }
        
        guard let itemIndex = po.items.firstIndex(where: { $0.sku.lowercased() == catalog.catalogId.lowercased() }) else {
            return .unexpected(catalog.name)
        }
        
        var item = po.items[itemIndex]
        item.receivedQty += 1
        let generatedSerial = "SR-\(catalog.catalogId)-\(UUID().uuidString.prefix(6).uppercased())"
        item.scannedSerials.append(generatedSerial)
        po.items[itemIndex] = item
        
        let isOvercount = item.receivedQty > item.expectedQty
        
        let allItemsMet = po.items.allSatisfy { $0.receivedQty >= $0.expectedQty }
        if allItemsMet {
            po.status = .fullyReceived
            po.receivedAt = Date()
            purchaseOrders[index] = po
            saveToUserDefaults()
            updateDatabaseStock(for: po)
            return .completed(catalog.name, isOvercount)
        } else {
            purchaseOrders[index] = po
            saveToUserDefaults()
            return .success(catalog.name, isOvercount)
        }
    }
    
    func forceAddUnexpectedItem(poId: UUID, itemName: String) {
        guard let index = purchaseOrders.firstIndex(where: { $0.id == poId }) else { return }
        var po = purchaseOrders[index]
        
        let sku = "UNEXPECTED-\(UUID().uuidString.prefix(6))"
        let newItem = POItem(brand: "UNEXPECTED", name: itemName, sku: sku, expectedQty: 0, receivedQty: 1, scannedSerials: ["SR-\(sku)"])
        po.items.append(newItem)
        
        let allItemsMet = po.items.allSatisfy { $0.receivedQty >= $0.expectedQty }
        if allItemsMet {
            po.status = .fullyReceived
            po.receivedAt = Date()
            updateDatabaseStock(for: po)
        }
        
        purchaseOrders[index] = po
        saveToUserDefaults()
    }
    
    private func updateDatabaseStock(for po: PurchaseOrder) {
        Task {
            var boutiqueId: UUID? = nil
            if let profileTuple = try? await profileService.fetchCurrentProfile(),
               let staff = profileTuple.1 as? StaffModel {
                boutiqueId = staff.boutiqueId
            }
            
            for item in po.items {
                guard let catalog = matchedCatalogs.first(where: { $0.catalogId.lowercased() == item.sku.lowercased() }) else {
                    continue
                }
                
                if let storeId = boutiqueId {
                    let newUnits = item.scannedSerials.map { serial in
                        InventoryUnitEntity(
                            id: UUID(),
                            catalogId: catalog.id,
                            boutiqueId: storeId,
                            serialNumber: serial,
                            status: .available,
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                    }
                    try? await InventoryService.shared.createInventoryUnits(newUnits)
                }
            }
        }
    }
    
    func resetMockData() {
        UserDefaults.standard.removeObject(forKey: "luxury_purchase_orders")
        loadPurchaseOrders()
    }
}

enum ScanResult {
    case success(String, Bool)
    case completed(String, Bool)
    case unexpected(String)
    case error(String)
}
