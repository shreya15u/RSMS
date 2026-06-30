//
//  EndlessAisleServices.swift
//  luxury
//
//  Created by Nalinish Ranjan on 26/05/26.
//

import Foundation
import Supabase

public enum StockResult: Sendable, Codable, Hashable {
    case localInStock
    case outOfStockLocally(alternateLocations: [EndlessAisle.BoutiqueStock])
    case noStockAnywhere
}

enum EndlessAisleStatus {
    static let pendingManagerApproval = "Endless Aisle Pending BM"
    static let requested = "Endless Aisle Requested"
    static let sourceReview = "Endless Aisle Source Review"
    static let approved = "Endless Aisle Approved"
    static let dispatched = "Endless Aisle Dispatched"
    static let arrived = "Endless Aisle Arrived"
    static let received = "Endless Aisle Received"
}

enum EndlessAisleLink {
    static let prefix = "EA"
    
    static func encode(originalOrderId: UUID, originalTransactionId: String, destinationBoutiqueId: UUID, serialNumber: String? = nil) -> String {
        var parts = [prefix, originalOrderId.uuidString, originalTransactionId, destinationBoutiqueId.uuidString]
        if let serialNumber, !serialNumber.isEmpty {
            parts.append(serialNumber)
        }
        return parts.joined(separator: "|")
    }
    
    static func decode(_ value: String) -> (originalOrderId: UUID, originalTransactionId: String, destinationBoutiqueId: UUID, serialNumber: String?)? {
        let parts = value.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 4 || parts.count == 5,
              parts[0] == prefix,
              let originalOrderId = UUID(uuidString: parts[1]),
              let destinationBoutiqueId = UUID(uuidString: parts[3]) else {
            return nil
        }
        let serialNumber = parts.count == 5 ? parts[4] : nil
        return (originalOrderId, parts[2], destinationBoutiqueId, serialNumber)
    }
}

public protocol EndlessAisleInventoryService: Sendable {
    func checkStock(itemId: UUID, currentBoutiqueId: UUID) async throws -> StockResult
}

public final class SupabaseEndlessAisleInventoryService: EndlessAisleInventoryService, @unchecked Sendable {
    private let client: SupabaseClient
    
    public init() {
        self.client = SupabaseManager.shared.client
    }
    
    public func checkStock(itemId: UUID, currentBoutiqueId: UUID) async throws -> StockResult {
        let units: [InventoryUnitEntity] = try await InventoryService.shared.fetchInventory(forCatalog: itemId)
        let available = units.filter { $0.status == .available }
        
        if available.contains(where: { $0.boutiqueId == currentBoutiqueId }) {
            return .localInStock
        }
        
        let grouped = Dictionary(grouping: available.filter { $0.boutiqueId != currentBoutiqueId }, by: \.boutiqueId)
        guard !grouped.isEmpty else {
            return .noStockAnywhere
        }
        
        var stocks: [EndlessAisle.BoutiqueStock] = []
        for (boutiqueId, boutiqueUnits) in grouped {
            if let boutique: CorporateBoutique = try? await client
                .from("boutiques")
                .select()
                .eq("id", value: boutiqueId.uuidString)
                .single()
                .execute()
                .value {
                stocks.append(
                    EndlessAisle.BoutiqueStock(
                        id: boutique.id,
                        name: boutique.name,
                        city: boutique.city,
                        quantity: boutiqueUnits.count
                    )
                )
            }
        }
        
        return stocks.isEmpty ? .noStockAnywhere : .outOfStockLocally(alternateLocations: stocks.sorted { $0.name < $1.name })
    }
}
