//
//  CatalogService.swift
//  luxury
//
//  Created by Nalinish Ranjan on 21/05/26.
//

import Foundation
import Supabase

final class CatalogService {
    private let client = SupabaseManager.shared.client
    
    func fetchCatalogs() async throws -> [CatalogEntity] {
        let cacheBucket = "catalog"
        let cacheKey = "all_catalogs"
        
        do {
            let response: [CatalogEntity] = try await client
                .from("catalogs")
                .select()
                .execute()
                .value
            
            await CacheManager.shared.storeObject(response, bucket: cacheBucket, key: cacheKey)
            return response
        } catch {
            if let cached = await CacheManager.shared.getObject([CatalogEntity].self, bucket: cacheBucket, key: cacheKey) {
                return cached
            }
            throw error
        }
    }
    
    func addCatalog(_ catalog: CatalogEntity) async throws {
        try await client
            .from("catalogs")
            .insert(catalog)
            .execute()
    }
    
    func updateCatalog(_ catalog: CatalogEntity) async throws {
        try await client
            .from("catalogs")
            .update(catalog)
            .eq("id", value: catalog.id.uuidString)
            .execute()
    }
    
    func deleteCatalog(id: UUID) async throws {
        try await client
            .from("catalogs")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
