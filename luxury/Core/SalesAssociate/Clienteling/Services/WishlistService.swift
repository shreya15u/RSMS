//
//  WishlistService.swift
//  luxury
//
//  Created by Nalinish Ranjan on 22/05/26.
//

import Foundation
import Supabase

struct DBWishlist: Codable {
    let id: UUID
    let clientId: UUID
    let products: [UUID]
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case products
    }
}

final class WishlistService {
    static let shared = WishlistService()
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    private func localKey(for clientId: UUID) -> String {
        return "luxury_wishlist_\(clientId.uuidString)"
    }
    
    private var localEncoder: JSONEncoder {
        return JSONEncoder()
    }
    
    private var localDecoder: JSONDecoder {
        return JSONDecoder()
    }
    
    func fetchWishlist(clientId: UUID) -> [ClientWishlistItem] {
        let key = localKey(for: clientId)
        
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                return try localDecoder.decode([ClientWishlistItem].self, from: data)
            } catch {
                print("Error decoding local wishlist: \(error)")
            }
        }
        
        return []
    }
    
    func syncWishlist(clientId: UUID) async {
        do {
            let dbWishlists: [DBWishlist] = try await client
                .from("wishlist")
                .select()
                .eq("client_id", value: clientId.uuidString)
                .execute()
                .value
            
            if let record = dbWishlists.first {
                let productIds = record.products
                if !productIds.isEmpty {
                    // Fetch catalogs matching these IDs
                    let dbCatalogs: [CatalogEntity] = try await client
                        .from("catalogs")
                        .select()
                        .in("id", values: productIds.map { $0.uuidString })
                        .execute()
                        .value
                    
                    // Map back to ClientWishlistItem
                    let items = productIds.compactMap { pid in
                        if let cat = dbCatalogs.first(where: { $0.id == pid }) {
                            return ClientWishlistItem(id: cat.id, brand: cat.brand, name: cat.name, price: cat.amount, productImages: cat.productImages)
                        }
                        return nil
                    }
                    saveLocalWishlist(items, for: clientId)
                } else {
                    saveLocalWishlist([], for: clientId)
                }
            } else {
                // Do not clear local cache if no record exists on Supabase (e.g. mock clients)
            }
        } catch {
            print("Supabase fetch wishlist warning: \(error.localizedDescription)")
        }
    }
    
    func saveLocalWishlist(_ items: [ClientWishlistItem], for clientId: UUID) {
        let key = localKey(for: clientId)
        do {
            let data = try localEncoder.encode(items)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Error encoding local wishlist: \(error)")
        }
    }
    
    func addToWishlist(clientId: UUID, item: ClientWishlistItem) async throws {
        do {
            let dbWishlists: [DBWishlist] = try await client
                .from("wishlist")
                .select()
                .eq("client_id", value: clientId.uuidString)
                .execute()
                .value
            
            if let record = dbWishlists.first {
                var updatedProducts = record.products
                if !updatedProducts.contains(item.id) {
                    updatedProducts.append(item.id)
                    
                    try await client
                        .from("wishlist")
                        .update(["products": updatedProducts.map { $0.uuidString }])
                        .eq("client_id", value: clientId.uuidString)
                        .execute()
                    print("Successfully updated existing wishlist row on Supabase.")
                }
            } else {
                let payload: [String: AnyJSON] = [
                    "client_id": .string(clientId.uuidString),
                    "products": .array([.string(item.id.uuidString)])
                ]
                try await client
                    .from("wishlist")
                    .insert(payload)
                    .execute()
                print("Successfully created new wishlist row on Supabase.")
            }
            
            // Force an immediate structural refetch to sync local cache
            await syncWishlist(clientId: clientId)
        } catch {
            print("Wishlist Remote Sync Error: \(error)")
            throw error
        }
    }
    
    func removeFromWishlist(clientId: UUID, itemId: UUID) async {
        // 1. Update local storage immediately for responsive UI
        var currentItems = fetchWishlist(clientId: clientId)
        currentItems.removeAll { $0.id == itemId }
        saveLocalWishlist(currentItems, for: clientId)
        
        // 2. Perform background synchronization to Supabase table "wishlist"
        do {
            let dbWishlists: [DBWishlist] = try await client
                .from("wishlist")
                .select()
                .eq("client_id", value: clientId.uuidString)
                .execute()
                .value
            
            if let record = dbWishlists.first {
                var updatedProducts = record.products
                updatedProducts.removeAll { $0 == itemId }
                
                try await client
                    .from("wishlist")
                    .update(["products": updatedProducts.map { $0.uuidString }])
                    .eq("client_id", value: clientId.uuidString)
                    .execute()
                print("Successfully updated wishlist after removing item on Supabase.")
            }
        } catch {
            print("Supabase sync wishlist remove warning: \(error.localizedDescription)")
        }
    }
}
