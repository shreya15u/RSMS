//
//  NewTransferViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation
import Supabase
import PostgREST

@Observable
final class NewTransferViewModel {
    var sourceStore: CorporateBoutique?
    var destinationStore: CorporateBoutique?
    var availableBoutiques: [CorporateBoutique] = []
    
    var items: [TransferItem] = []
    var approvalState: ApprovalState = .waiting
    var packingSlipGenerated: Bool = false
    
    var showAlert: Bool = false
    var alertMessage: String = ""
    var alertTitle: String = ""
    
    var availableProducts: [CatalogEntity] = []
    
    @ObservationIgnored var fetchBoutiquesHandler: () async throws -> [CorporateBoutique]
    @ObservationIgnored var fetchProfileHandler: () async throws -> (UserRole, Any)?
    @ObservationIgnored var fetchCatalogsHandler: () async throws -> [CatalogEntity]
    @ObservationIgnored var fetchInventoryHandler: (UUID, UUID) async throws -> [InventoryUnitEntity]
    
    init() {
        self.fetchBoutiquesHandler = {
            try await SupabaseManager.shared.client
                .from("boutiques")
                .select()
                .eq("status", value: "approved")
                .execute()
                .value
        }
        self.fetchProfileHandler = {
            try await ProfileService().fetchCurrentProfile()
        }
        self.fetchCatalogsHandler = {
            try await SupabaseManager.shared.client
                .from("catalogs")
                .select()
                .execute()
                .value
        }
        self.fetchInventoryHandler = { skuId, storeId in
            try await InventoryService.shared.fetchInventory(forCatalog: skuId, boutiqueId: storeId)
        }
    }
    
    var hasStockError: Bool {
        items.contains(where: { $0.qty > $0.availableQty })
    }
    
    func fetchBoutiques() {
        Task {
            do {
                let boutiques = try await fetchBoutiquesHandler()
                let profileTuple = try? await fetchProfileHandler()
                var storeId: UUID? = nil
                if let staff = profileTuple?.1 as? StaffModel {
                    storeId = staff.boutiqueId
                } else if let managerBoutique = profileTuple?.1 as? CorporateBoutique {
                    storeId = managerBoutique.id
                }
                
                await MainActor.run {
                    if let sId = storeId {
                        self.sourceStore = boutiques.first(where: { $0.id == sId })
                    } else {
                        self.sourceStore = boutiques.first
                    }
                    self.availableBoutiques = boutiques.filter { $0.id != self.sourceStore?.id }
                    self.destinationStore = nil
                }
            } catch {
                print("Error fetching boutiques for transfer: \(error)")
            }
        }
    }
    
    func fetchAvailableProducts() {
        Task {
            do {
                let products = try await fetchCatalogsHandler()
                await MainActor.run {
                    self.availableProducts = products
                }
            } catch {}
        }
    }
    
    func scanItem(barcode: String) async -> Result<Void, Error> {
        guard let sourceId = sourceStore?.id else {
            return .failure(NSError(domain: "Transfer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Source boutique not set."]))
        }
        
        do {
            let trimmedBarcode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
            let catalogs = try await fetchCatalogsHandler()
            guard let catalogItem = catalogs.first(where: { 
                $0.barCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedBarcode.lowercased() || 
                $0.catalogId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedBarcode.lowercased() 
            }) else {
                return .failure(NSError(domain: "Transfer", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid SKU/Barcode scanned."]))
            }
            
            if items.contains(where: { $0.sku.lowercased() == catalogItem.barCode.lowercased() }) {
                return .failure(NSError(domain: "Transfer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Duplicate Scan: \(catalogItem.name) is already in the transfer list."]))
            }
            
            let inventoryList = try await fetchInventoryHandler(catalogItem.id, sourceId)
            let availableCount = inventoryList.filter { $0.status == .available }.count

            guard availableCount > 0 else {
                return .failure(NSError(domain: "Transfer", code: 3, userInfo: [NSLocalizedDescriptionKey: "Warning: \(catalogItem.name) is not available at the source location."]))
            }
            
            await MainActor.run {
                let newItem = TransferItem(
                    sku: catalogItem.barCode,
                    name: catalogItem.name,
                    qty: 1,
                    availableQty: availableCount
                )
                self.items.append(newItem)
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    func confirmTransfer() async -> Result<Void, Error> {
        guard !items.isEmpty else {
            return .failure(NSError(domain: "Transfer", code: 5, userInfo: [NSLocalizedDescriptionKey: "Block: Cannot confirm transfer with zero items."]))
        }
        guard let sourceId = sourceStore?.id, let destId = destinationStore?.id else {
            return .failure(NSError(domain: "Transfer", code: 6, userInfo: [NSLocalizedDescriptionKey: "Source or Destination store not selected."]))
        }
        
        do {
            let boutiques = try await fetchBoutiquesHandler()
            guard boutiques.contains(where: { $0.id == destId }) else {
                return .failure(NSError(domain: "Transfer", code: 7, userInfo: [NSLocalizedDescriptionKey: "Error: Destination boutique is no longer available."]))
            }
            
            let catalogs = try await fetchCatalogsHandler()
            
            for item in items {
                guard let catalogItem = catalogs.first(where: { $0.barCode.lowercased() == item.sku.lowercased() }) else {
                    throw NSError(domain: "Transfer", code: 8, userInfo: [NSLocalizedDescriptionKey: "No stock record found for \(item.name)."])
                }
                
                let inventoryList = try await fetchInventoryHandler(catalogItem.id, sourceId)
                let availableCount = inventoryList.filter { $0.status == .available }.count

                guard availableCount > 0 else {
                    throw NSError(domain: "Transfer", code: 8, userInfo: [NSLocalizedDescriptionKey: "No stock record found for \(item.name)."])
                }

                if availableCount < item.qty {
                    throw NSError(domain: "Transfer", code: 9, userInfo: [NSLocalizedDescriptionKey: "Insufficient stock for \(item.name) (requested: \(item.qty), available: \(availableCount))."])
                }
            }
            
            let sourceStoreName = sourceStore?.name ?? "Source Store"
            let destinationStoreName = destinationStore?.name ?? "Dest Store"
            let newRequest = try await StockTransferService.shared.createTransfer(
                reference: "TR-\(Int.random(in: 1000...9999))",
                sourceBoutiqueId: sourceId,
                destinationBoutiqueId: destId,
                source: sourceStoreName,
                destination: destinationStoreName,
                items: items
            )
            
            SystemLogService.shared.logAction(
                category: .inventory,
                severity: .info,
                message: "Stock Transfer \(newRequest.reference) initiated from \(sourceStoreName) to \(destinationStoreName) with \(newRequest.itemCount) items.",
                boutiqueName: sourceStoreName
            )
            
            NotificationCenter.default.post(
                name: NSNotification.Name("StockTransferReceived"),
                object: nil,
                userInfo: [
                    "reference": newRequest.reference,
                    "source": newRequest.source,
                    "destination": newRequest.destination,
                    "destinationBoutiqueId": destId.uuidString
                ]
            )
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    func incrementQty(for itemId: UUID) {
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            if items[index].qty < items[index].availableQty {
                items[index].qty += 1
            } else {
                alertTitle = "Stock Limit Reached"
                alertMessage = "Cannot request more than the available stock (\(items[index].availableQty) units)."
                showAlert = true
            }
        }
    }
    
    func decrementQty(for itemId: UUID) {
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            if items[index].qty > 1 {
                items[index].qty -= 1
            }
        }
    }
    
    func submit() {
        approvalState = .waiting
    }
    
    func approve() {
        approvalState = .approved
    }
    
    func completeSession() {
        packingSlipGenerated = true
    }
}
