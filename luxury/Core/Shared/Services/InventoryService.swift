import Foundation
import Supabase

final class InventoryService {
    static let shared = InventoryService()
    private let client = SupabaseManager.shared.client
    
    private init() {}
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // 1. Standard ISO8601
            if let date = ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            
            // 2. ISO8601 with fractional seconds
            let fractionFormatter = ISO8601DateFormatter()
            fractionFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractionFormatter.date(from: dateString) {
                return date
            }
            
            // 3. Custom Formats without Z
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
                "yyyy-MM-dd'T'HH:mm:ss.SSS",
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd HH:mm:ss.SSSSSS",
                "yyyy-MM-dd HH:mm:ss"
            ]
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            for format in formats {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }
            
            print("[InventoryService] CRITICAL DECODE ERROR: Unrecognized date format -> \(dateString)")
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        return decoder
    }
    
    /// Fetches all inventory units globally (For Corporate Admin)
    func fetchGlobalInventory() async throws -> [InventoryUnitEntity] {
        return try await fetchAllInventoryUnits()
    }
    
    /// Fetches all inventory units for a specific boutique (For SA, BM, IC)
    func fetchInventory(forBoutique boutiqueId: UUID) async throws -> [InventoryUnitEntity] {
        let cacheBucket = "inventory"
        let cacheKey = "boutique_\(boutiqueId.uuidString)"
        
        do {
            var allUnits: [InventoryUnitEntity] = []
            var offset = 0
            let chunkSize = 1000
            var hasMore = true
            
            while hasMore {
                let response = try await client
                    .from("inventory_units")
                    .select()
                    .eq("boutique_id", value: boutiqueId.uuidString)
                    .range(from: offset, to: offset + chunkSize - 1)
                    .execute()
                
                let batch = try decoder.decode([InventoryUnitEntity].self, from: response.data)
                allUnits.append(contentsOf: batch)
                
                if batch.count < chunkSize {
                    hasMore = false
                } else {
                    offset += chunkSize
                }
            }
            
            await CacheManager.shared.storeObject(allUnits, bucket: cacheBucket, key: cacheKey)
            return allUnits
        } catch {
            if let cached = await CacheManager.shared.getObject([InventoryUnitEntity].self, bucket: cacheBucket, key: cacheKey) {
                return cached
            }
            throw error
        }
    }
    
    func fetchAllInventoryUnits() async throws -> [InventoryUnitEntity] {
        let cacheBucket = "inventory"
        let cacheKey = "all_inventory"
        
        do {
            var allUnits: [InventoryUnitEntity] = []
            var offset = 0
            let chunkSize = 1000
            var hasMore = true
            
            while hasMore {
                let response = try await client
                    .from("inventory_units")
                    .select()
                    .range(from: offset, to: offset + chunkSize - 1)
                    .execute()
                
                let batch = try decoder.decode([InventoryUnitEntity].self, from: response.data)
                allUnits.append(contentsOf: batch)
                
                if batch.count < chunkSize {
                    hasMore = false
                } else {
                    offset += chunkSize
                }
            }
            await CacheManager.shared.storeObject(allUnits, bucket: cacheBucket, key: cacheKey)
            return allUnits
        } catch {
            if let cached = await CacheManager.shared.getObject([InventoryUnitEntity].self, bucket: cacheBucket, key: cacheKey) {
                return cached
            }
            throw error
        }
    }
    
    /// Fetches inventory for a specific catalog item globally
    func fetchInventory(forCatalog catalogId: UUID) async throws -> [InventoryUnitEntity] {
        var allUnits: [InventoryUnitEntity] = []
        var offset = 0
        let chunkSize = 1000
        var hasMore = true
        
        while hasMore {
            let response = try await client
                .from("inventory_units")
                .select()
                .eq("catalog_id", value: catalogId.uuidString)
                .range(from: offset, to: offset + chunkSize - 1)
                .execute()
            
            let batch = try decoder.decode([InventoryUnitEntity].self, from: response.data)
            allUnits.append(contentsOf: batch)
            
            if batch.count < chunkSize {
                hasMore = false
            } else {
                offset += chunkSize
            }
        }
        return allUnits
    }
    
    /// Fetches inventory for a specific catalog item in a specific boutique
    func fetchInventory(forCatalog catalogId: UUID, boutiqueId: UUID) async throws -> [InventoryUnitEntity] {
        var allUnits: [InventoryUnitEntity] = []
        var offset = 0
        let chunkSize = 1000
        var hasMore = true
        
        while hasMore {
            let response = try await client
                .from("inventory_units")
                .select()
                .eq("catalog_id", value: catalogId.uuidString)
                .eq("boutique_id", value: boutiqueId.uuidString)
                .range(from: offset, to: offset + chunkSize - 1)
                .execute()
            
            let batch = try decoder.decode([InventoryUnitEntity].self, from: response.data)
            allUnits.append(contentsOf: batch)
            
            if batch.count < chunkSize {
                hasMore = false
            } else {
                offset += chunkSize
            }
        }
        return allUnits
    }
    
    /// Helper to fetch all available inventory units for a boutique (or globally if nil) and return a dictionary of [CatalogID : Available Count]
    func fetchAvailableStockDictionary(forBoutique boutiqueId: UUID? = nil) async throws -> [UUID: Int] {
        let inventory: [InventoryUnitEntity]
        if let bId = boutiqueId {
            inventory = try await fetchInventory(forBoutique: bId)
        } else {
            inventory = try await fetchGlobalInventory()
        }
        
        var stockDict: [UUID: Int] = [:]
        for unit in inventory where unit.status == .available {
            stockDict[unit.catalogId, default: 0] += 1
        }
        return stockDict
    }
    
    /// Bulk updates the status and/or boutique of inventory units (e.g., Stock Transfers)
    func updateInventoryStatus(serials: [String], newStatus: InventoryUnitStatus, newBoutiqueId: UUID? = nil) async throws {
        for serial in serials {
            var updateData: [String: AnyJSON] = [
                "status": .string(newStatus.rawValue),
                "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
            ]
            if let boutiqueId = newBoutiqueId {
                updateData["boutique_id"] = .string(boutiqueId.uuidString)
            }
            
            try await client
                .from("inventory_units")
                .update(updateData)
                .eq("serial_number", value: serial)
                .execute()
        }
    }
    
    /// Creates new stock units (e.g., Receiving new shipment)
    func createInventoryUnits(_ units: [InventoryUnitEntity]) async throws {
        print("[InventoryService] Attempting to insert \(units.count) units into 'inventory_units' table...")
        do {
            let response = try await client
                .from("inventory_units")
                .insert(units)
                .execute()
            print("[InventoryService] Insert successful! Response status: \(response.response.statusCode)")
        } catch {
            print("[InventoryService] Insert failed with error: \(error)")
            throw error
        }
    }
    
    /// Deletes specific inventory units
    func deleteInventoryUnits(serials: [String]) async throws {
        for serial in serials {
            try await client
                .from("inventory_units")
                .delete()
                .eq("serial_number", value: serial)
                .execute()
        }
    }
}
