//
//  FulfillmentViewModel.swift
//  luxury
//
//  Created by Nalinish Ranjan on 22/05/26.
//

import Foundation
import Observation
import Supabase

@Observable
final class FulfillmentViewModel {
    var orders: [PurchasedItemEntity] = []
    var isLoading = false
    var errorMessage: String?
    var selectedSegment = 0
    
    private let client = SupabaseManager.shared.client
    
    @ObservationIgnored var fetchPurchasedItemsHandler: () async throws -> [PurchasedItemEntity]
    @ObservationIgnored var fetchCatalogsHandler: () async throws -> [CatalogEntity]
    @ObservationIgnored var fetchProfileHandler: () async throws -> (UserRole, Any)?
    @ObservationIgnored var fetchBoutiqueHandler: (UUID) async throws -> CorporateBoutique?
    @ObservationIgnored var fetchInventoryHandler: (UUID, UUID) async throws -> [InventoryUnitEntity]
    @ObservationIgnored var fetchGlobalInventoryHandler: (UUID) async throws -> [InventoryUnitEntity]
    @ObservationIgnored var updateInventoryHandler: (String, InventoryUnitStatus) async throws -> Void
    @ObservationIgnored var updatePurchasedItemHandler: (UUID, String, Date?) async throws -> Void
    
    init() {
        self.fetchPurchasedItemsHandler = {
            if let (_, profile) = try? await ProfileService().fetchCurrentProfile(),
               let staff = profile as? StaffModel, let bId = staff.boutiqueId {
                return try await SupabaseManager.shared.client.from("purchased_items").select().eq("boutique_id", value: bId.uuidString).execute().value
            }
            return try await SupabaseManager.shared.client.from("purchased_items").select().execute().value
        }
        self.fetchCatalogsHandler = {
            try await SupabaseManager.shared.client.from("catalogs").select().execute().value
        }
        self.fetchProfileHandler = {
            try await ProfileService().fetchCurrentProfile()
        }
        self.fetchBoutiqueHandler = { id in
            try await ProfileService().fetchBoutique(id: id)
        }
        self.fetchInventoryHandler = { skuId, storeId in
            try await InventoryService.shared.fetchInventory(forCatalog: skuId, boutiqueId: storeId)
        }
        self.fetchGlobalInventoryHandler = { skuId in
            try await InventoryService.shared.fetchInventory(forCatalog: skuId)
        }
        self.updateInventoryHandler = { serialNumber, status in
            try await InventoryService.shared.updateInventoryStatus(serials: [serialNumber], newStatus: status)
        }
        self.updatePurchasedItemHandler = { id, status, deliveryDate in
            let payload: [String: String] = {
                var dict = ["status": status]
                if let date = deliveryDate {
                    dict["delivery_date"] = ISO8601DateFormatter().string(from: date)
                }
                return dict
            }()
            try await SupabaseManager.shared.client.from("purchased_items")
                .update(payload)
                .eq("id", value: id.uuidString)
                .execute()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("SFSOrderReceived"), object: nil, queue: .main) { [weak self] _ in
            self?.fetchOrders()
        }
    }
    
    var filteredOrders: [PurchasedItemEntity] {
        if selectedSegment == 0 {
            return orders.filter { $0.status.lowercased() == "pending" }
        } else {
            return orders.filter { 
                let status = $0.status.lowercased()
                return status == "secured" || status == "ready to pick" || status == "delivered" 
            }
        }
    }
    
    func fetchOrders() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let itemsResponse = try await fetchPurchasedItemsHandler()
                let products = try await fetchCatalogsHandler()
                
                let profileTuple = try? await fetchProfileHandler()
                let staff = profileTuple?.1 as? StaffModel
                let boutiqueId = staff?.boutiqueId
                var boutiqueName = "Store"
                if let bId = boutiqueId, let boutique = try? await fetchBoutiqueHandler(bId) {
                    boutiqueName = boutique.name
                }
                
                var resolved: [PurchasedItemEntity] = []
                for var item in itemsResponse {
                    if let product = products.first(where: { $0.id == item.productId }) {
                        item.productName = product.name
                        item.productBrand = product.brand
                        item.productSku = product.catalogId
                        item.productImages = product.productImages
                        
                        let firstChar = product.brand.first ?? "A"
                        let shelfNum = (abs(product.id.hashValue) % 5) + 1
                        let section = product.category == .watches ? "Vault" : "Aisle \(firstChar)"
                        item.storeLocation = "\(boutiqueName) - \(section), Shelf \(shelfNum)"
                    }
                    resolved.append(item)
                }
                
                await MainActor.run {
                    self.orders = resolved.sorted(by: { $0.reservedDate > $1.reservedDate })
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func verifyScannedSku(orderSku: String?, scannedCode: String) -> Result<Void, Error> {
        let trimmedScanned = scannedCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let orderSku = orderSku?.trimmingCharacters(in: .whitespacesAndNewlines), !orderSku.isEmpty else {
            return .failure(NSError(domain: "Fulfillment", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid order SKU"]))
        }
        if trimmedScanned.lowercased() == orderSku.lowercased() {
            return .success(())
        } else {
            return .failure(NSError(domain: "Fulfillment", code: 2, userInfo: [NSLocalizedDescriptionKey: "SKU mismatch. Expected \(orderSku), got \(trimmedScanned)"]))
        }
    }
    
    func secureItem(orderId: UUID) async -> Result<Void, Error> {
        do {
            let profileTuple = try? await fetchProfileHandler()
            guard let profile = profileTuple else {
                return .failure(NSError(domain: "Fulfillment", code: 3, userInfo: [NSLocalizedDescriptionKey: "User profile not found."]))
            }
            guard profile.0 == .inventoryController else {
                return .failure(NSError(domain: "Fulfillment", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unauthorized: Action is restricted to Inventory Controllers."]))
            }
            guard let staff = profile.1 as? StaffModel, let storeId = staff.boutiqueId else {
                return .failure(NSError(domain: "Fulfillment", code: 3, userInfo: [NSLocalizedDescriptionKey: "Boutique association not found for user profile."]))
            }
            let icId = staff.id.uuidString

            let item: PurchasedItemEntity
            if let existing = orders.first(where: { $0.id == orderId }) {
                item = existing
            } else {
                let items = try await fetchPurchasedItemsHandler()
                guard let found = items.first(where: { $0.id == orderId }) else {
                    return .failure(NSError(domain: "Fulfillment", code: 7, userInfo: [NSLocalizedDescriptionKey: "Order not found."]))
                }
                item = found
            }
            
            if item.status.lowercased() == "ready to pick" {
                return .failure(NSError(domain: "Fulfillment", code: 4, userInfo: [NSLocalizedDescriptionKey: "Conflict: This item has already been marked as Ready."]))
            }
            
            let allPurchasedItems = try await fetchPurchasedItemsHandler()
            let conflictingItem = allPurchasedItems.first { otherItem in
                otherItem.productId == item.productId &&
                otherItem.id != orderId &&
                (otherItem.status.lowercased() == "secured" || otherItem.status.lowercased() == "ready to pick")
            }
            
            if let conflict = conflictingItem {
                var orderIdString = String(conflict.transactionId.prefix(8)).uppercased()
                do {
                    let conflictingOrders: [OrderEntity] = try await SupabaseManager.shared.client
                        .from("order")
                        .select()
                        .eq("transaction_id", value: conflict.transactionId)
                        .execute()
                        .value
                    if let firstOrder = conflictingOrders.first {
                        orderIdString = String(firstOrder.id.uuidString.prefix(8)).uppercased()
                    }
                } catch {}
                return .failure(NSError(domain: "Fulfillment", code: 8, userInfo: [NSLocalizedDescriptionKey: "Item already reserved for Order #\(orderIdString) — please verify."]))
            }
            
            if item.status.lowercased() == "pending" {
                let inventoryList = try await fetchInventoryHandler(item.productId, storeId)
                guard let unit = inventoryList.first(where: { $0.status == .available }) else {
                    return .failure(NSError(domain: "Fulfillment", code: 6, userInfo: [NSLocalizedDescriptionKey: "Conflict: The item is already reserved or out of stock at this boutique."]))
                }
                try await updateInventoryHandler(unit.serialNumber, .reserved)
            }

            let payload: [String: String] = [
                "status": "Ready to Pick",
                "delivery_date": ISO8601DateFormatter().string(from: Date()),
                "inventory_manager_id": icId
            ]
            
            let updatedItems: [PurchasedItemEntity] = try await SupabaseManager.shared.client
                .from("purchased_items")
                .update(payload)
                .eq("id", value: orderId.uuidString)
                .eq("status", value: item.status)
                .select()
                .execute()
                .value

            guard !updatedItems.isEmpty else {
                return .failure(NSError(domain: "Fulfillment", code: 9, userInfo: [NSLocalizedDescriptionKey: "Conflict: The item status has been modified by another process. Please retry."]))
            }

            Task {
                do {
                    let ordersRes: [OrderEntity] = try await SupabaseManager.shared.client
                        .from("order")
                        .select()
                        .eq("transaction_id", value: item.transactionId)
                        .execute()
                        .value

                    if let firstOrder = ordersRes.first {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("SalesAssociateNotification"),
                            object: nil,
                            userInfo: [
                                "salesAssociateId": firstOrder.rsmsUserId.uuidString,
                                "orderId": orderId.uuidString,
                                "status": "Ready to Pick"
                            ]
                        )
                    }
                } catch {
                    print("Sales Associate notification failed: \(error.localizedDescription)")
                }
            }
            
            await MainActor.run {
                if let index = self.orders.firstIndex(where: { $0.id == orderId }) {
                    self.orders[index].status = "Ready to Pick"
                    self.orders[index].deliveryDate = Date()
                    self.orders[index].inventoryManagerId = UUID(uuidString: icId)
                }
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    func performFlagItemAsMissing(orderId: UUID) async -> Result<Void, Error> {
        do {
            let item: PurchasedItemEntity
            if let existing = orders.first(where: { $0.id == orderId }) {
                item = existing
            } else {
                let items = try await fetchPurchasedItemsHandler()
                guard let found = items.first(where: { $0.id == orderId }) else {
                    return .failure(NSError(domain: "Fulfillment", code: 7, userInfo: [NSLocalizedDescriptionKey: "Order not found."]))
                }
                item = found
            }
            
            if item.status.lowercased() != "pending" {
                return .failure(NSError(domain: "Fulfillment", code: 5, userInfo: [NSLocalizedDescriptionKey: "Cannot flag a non-pending item as missing."]))
            }
            
            try await updatePurchasedItemHandler(orderId, "Missing", nil)
            
            let inventoryList = try await fetchGlobalInventoryHandler(item.productId)
            let availableQtyList = inventoryList.filter { $0.status == .available }
            
            var targetBoutiqueName = "No alternative stores available"
            if let nextInventory = availableQtyList.first {
                let boutique = try? await fetchBoutiqueHandler(nextInventory.boutiqueId)
                if let bName = boutique?.name {
                    targetBoutiqueName = "Reassigned to \(bName)"
                }
            }
            
            SystemLogService.shared.logAction(
                category: .inventory,
                severity: .warning,
                message: "Order \(orderId.uuidString.prefix(8)) flagged as missing. Reassignment status: \(targetBoutiqueName)"
            )
            
            await MainActor.run {
                if let index = self.orders.firstIndex(where: { $0.id == orderId }) {
                    self.orders[index].status = "Missing"
                }
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    func updateStatusToSecured(orderId: UUID) async -> Bool {
        let result = await secureItem(orderId: orderId)
        switch result {
        case .success:
            return true
        case .failure(let error):
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    func flagItemAsMissing(orderId: UUID) async -> Bool {
        let result = await performFlagItemAsMissing(orderId: orderId)
        switch result {
        case .success:
            return true
        case .failure(let error):
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    func updateStatusToReadyToPick(orderId: UUID) async -> Bool {
        do {
            let profileTuple = try? await fetchProfileHandler()
            var icId: String? = nil
            if let staff = profileTuple?.1 as? StaffModel {
                icId = staff.id.uuidString
            }
            
            let payload: [String: String] = {
                var dict = ["status": "Ready to Pick"]
                if let id = icId {
                    dict["inventory_manager_id"] = id
                }
                return dict
            }()
            
            try await SupabaseManager.shared.client.from("purchased_items")
                .update(payload)
                .eq("id", value: orderId.uuidString)
                .execute()
            
            await MainActor.run {
                if let index = self.orders.firstIndex(where: { $0.id == orderId }) {
                    self.orders[index].status = "Ready to Pick"
                    if let newId = icId {
                        self.orders[index].inventoryManagerId = UUID(uuidString: newId)
                    }
                }
            }
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    func dispatchOrder(order: PurchasedItemEntity, expectedQty: Int, deliveredQty: Int) async -> Bool {
        do {
            let profileService = ProfileService()
            var staffName = "Inventory Controller"
            var boutiqueId: UUID? = nil
            var boutiqueName = "Main Vault"
            
            if let profileTuple = try? await profileService.fetchCurrentProfile(),
               let staff = profileTuple.1 as? StaffModel {
                staffName = staff.name
                boutiqueId = staff.boutiqueId
                if let bId = boutiqueId, let boutique = try? await profileService.fetchBoutique(id: bId) {
                    boutiqueName = boutique.name
                }
            }
            
            let catalog: CatalogEntity = try await client
                .from("catalogs")
                .select()
                .eq("id", value: order.productId.uuidString)
                .single()
                .execute()
                .value
            
            if let storeId = boutiqueId {
                let units = try await InventoryService.shared.fetchInventory(forBoutique: storeId)
                let matchingUnits = units.filter { $0.catalogId == catalog.id && ($0.status == .available || $0.status == .reserved) }
                
                let unitsToSell = matchingUnits.prefix(deliveredQty).map { $0.serialNumber }
                if !unitsToSell.isEmpty {
                    try await InventoryService.shared.updateInventoryStatus(serials: Array(unitsToSell), newStatus: .sold)
                }
            }
            
            try await client
                .from("purchased_items")
                .update([
                    "status": "Delivered",
                    "delivery_date": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: order.id.uuidString)
                .execute()
            
            let logMsg = "Order \(order.id.uuidString.prefix(8).uppercased()) Dispatched: SKU \(catalog.catalogId), Expected: \(expectedQty), Delivered: \(deliveredQty). Confirmed by: \(staffName)."
            SystemLogService.shared.logAction(
                category: .inventory,
                severity: .info,
                message: logMsg,
                boutiqueName: boutiqueName
            )
            
            await MainActor.run {
                if let idx = self.orders.firstIndex(where: { $0.id == order.id }) {
                    self.orders[idx].status = "Delivered"
                    self.orders[idx].deliveryDate = Date()
                }
            }
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
}
