import SwiftUI
import Observation
import Supabase

@Observable
final class BarcodeLookupViewModel {
    var isLoading = false
    var errorMessage: String?
    var scannedItem: CatalogEntity?
    var liveStockCount: Int = 0
    
    // Scan session states
    var expectedItems: [CatalogEntity] = []
    var expectedBarcodes: [String] = []
    var scannedBarcodes: [String] = []
    var scannedItems: [CatalogEntity] = []
    var unexpectedBarcodes: [String] = []
    
    private let profileService = ProfileService()
    
    var missingItems: [CatalogEntity] {
        return expectedItems.filter { item in
            let code = item.barCode.trimmingCharacters(in: .whitespacesAndNewlines)
            return !code.isEmpty && !scannedBarcodes.contains(code)
        }
    }
    
    func loadExpectedItems() {
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
                    self.expectedItems = fetched
                    self.expectedBarcodes = fetched.map { $0.barCode.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to load expected products: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
    
    func addScannedBarcode(_ barcode: String) {
        let trimmed = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if !scannedBarcodes.contains(trimmed) {
            scannedBarcodes.append(trimmed)
            
            if let matched = expectedItems.first(where: { $0.barCode.lowercased() == trimmed.lowercased() }) {
                if !scannedItems.contains(where: { $0.id == matched.id }) {
                    scannedItems.append(matched)
                }
            } else {
                if !unexpectedBarcodes.contains(trimmed) {
                    unexpectedBarcodes.append(trimmed)
                }
            }
        }
    }
    
    func resetSession() {
        scannedBarcodes.removeAll()
        scannedItems.removeAll()
        unexpectedBarcodes.removeAll()
        scannedItem = nil
        liveStockCount = 0
    }
    
    func lookupItem(by code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        scannedItem = nil
        liveStockCount = 0
        
        Task {
            do {
                let item: CatalogEntity
                do {
                    item = try await SupabaseManager.shared.client
                        .from("catalogs")
                        .select()
                        .ilike("bar_code", pattern: trimmed)
                        .single()
                        .execute()
                        .value
                } catch {
                    item = try await SupabaseManager.shared.client
                        .from("catalogs")
                        .select()
                        .ilike("catalog_id", pattern: trimmed)
                        .single()
                        .execute()
                        .value
                }
                
                var boutiqueId: UUID? = nil
                if let profileTuple = try? await profileService.fetchCurrentProfile(),
                   let staff = profileTuple.1 as? StaffModel {
                    boutiqueId = staff.boutiqueId
                }
                
                var localizedStockCount = 0
                if let storeId = boutiqueId {
                    if let inventory = try? await InventoryService.shared.fetchInventory(forCatalog: item.id, boutiqueId: storeId) {
                        localizedStockCount = inventory.filter { $0.status == .available }.count
                    }
                }
                
                await MainActor.run {
                    self.scannedItem = item
                    self.liveStockCount = localizedStockCount
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Item not found for barcode: \(trimmed)")
                    self.isLoading = false
                }
            }
        }
    }
}
