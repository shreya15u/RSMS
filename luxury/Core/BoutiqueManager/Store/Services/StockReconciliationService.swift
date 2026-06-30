//
//  StockReconciliationService.swift
//  luxury
//
//  Created by Codex on 27/05/26.
//

import Foundation
import PostgREST
import Supabase

final class StockReconciliationService {
    private let client = SupabaseManager.shared.client
    private let profileService = ProfileService()

    func fetchManagerContext() async throws -> StockReconciliationContext {
        guard let (_, profile) = try await profileService.fetchCurrentProfile(preferredRole: .boutiqueManager),
              let boutique = profile as? CorporateBoutique else {
            throw NSError(domain: "StockReconciliationService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to resolve the boutique manager profile."])
        }

        return StockReconciliationContext(
            boutiqueId: boutique.id,
            boutiqueName: boutique.name,
            editorName: boutique.managerName.isEmpty ? boutique.managerEmail : boutique.managerName
        )
    }

    func lookupCatalog(by code: String) async throws -> CatalogEntity {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "StockReconciliationService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Enter a valid SKU or barcode."])
        }

        do {
            return try await client
                .from("catalogs")
                .select()
                .ilike("bar_code", pattern: trimmed)
                .single()
                .execute()
                .value
        } catch {
            do {
                return try await client
                    .from("catalogs")
                    .select()
                    .ilike("catalog_id", pattern: trimmed)
                    .single()
                    .execute()
                    .value
            } catch {
                throw NSError(domain: "StockReconciliationService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Scan failed. Enter the SKU manually to continue."])
            }
        }
    }

    func fetchInventory(for skuId: UUID, storeId: UUID) async throws -> InventoryItem? {
        let items: [InventoryItem] = try await client
            .from("inventory")
            .select()
            .eq("sku_id", value: skuId)
            .eq("store_id", value: storeId)
            .limit(1)
            .execute()
            .value

        return items.first
    }

    func applyCorrection(
        inventory: InventoryItem?,
        skuId: UUID,
        storeId: UUID,
        scannedQuantity: Int
    ) async throws {
        if let inventory {
            let update = InventoryCorrectionPayload(
                quantity: scannedQuantity,
                productAvailable: scannedQuantity > 0
            )
            try await client
                .from("inventory")
                .update(update)
                .eq("id", value: inventory.id)
                .execute()
        } else {
            let newItem = InventoryInsertPayload(
                id: UUID(),
                storeId: storeId,
                skuId: skuId,
                quantity: scannedQuantity,
                productAvailable: scannedQuantity > 0
            )
            try await client
                .from("inventory")
                .insert(newItem)
                .execute()
        }
    }
}

struct StockReconciliationContext {
    let boutiqueId: UUID
    let boutiqueName: String
    let editorName: String
}

private struct InventoryCorrectionPayload: Encodable {
    let quantity: Int
    let productAvailable: Bool

    enum CodingKeys: String, CodingKey {
        case quantity
        case productAvailable = "product_available"
    }
}

private struct InventoryInsertPayload: Encodable {
    let id: UUID
    let storeId: UUID
    let skuId: UUID
    let quantity: Int
    let productAvailable: Bool

    enum CodingKeys: String, CodingKey {
        case id, quantity
        case storeId = "store_id"
        case skuId = "sku_id"
        case productAvailable = "product_available"
    }
}
