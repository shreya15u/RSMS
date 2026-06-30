//
//  PurchaseHistoryService.swift
//  luxury
//
//  Created by Nalinish Ranjan on 22/05/26.
//

import Foundation
import Supabase

final class PurchaseHistoryService {
    static let shared = PurchaseHistoryService()
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    private func localKey(for clientId: UUID) -> String {
        return "luxury_purchases_\(clientId.uuidString)"
    }
    
    func fetchPurchases(clientId: UUID) -> [ClientPurchase] {
        let key = localKey(for: clientId)
        
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                return try JSONDecoder().decode([ClientPurchase].self, from: data)
            } catch {
                print("Error decoding local purchases: \(error)")
            }
        }
        
        return []
    }
    
    func savePurchases(_ purchases: [ClientPurchase], for clientId: UUID) {
        let key = localKey(for: clientId)
        do {
            let data = try JSONEncoder().encode(purchases)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Error encoding local purchases: \(error)")
        }
    }
    
    func syncPurchases(clientId: UUID) async {
        do {
            let dbItems: [PurchasedItem] = try await client
                .from("purchased_items")
                .select()
                .eq("uid", value: clientId.uuidString)
                .execute()
                .value
            
            if !dbItems.isEmpty {
                let productIds = dbItems.map { $0.productId }
                let boutiqueIds = dbItems.compactMap { $0.boutiqueId?.uuidString }
                let saIds = dbItems.compactMap { $0.salesAssociateId?.uuidString }
                
                let dbCatalogs: [CatalogEntity] = try await client
                    .from("catalogs")
                    .select()
                    .in("id", values: productIds.map { $0.uuidString })
                    .execute()
                    .value
                
                struct MinimalBoutique: Codable {
                    let id: UUID
                    let name: String
                    let city: String?
                }
                struct MinimalCorporateAdmin: Codable {
                    let id: UUID
                    let name: String?
                }
                
                var dbBoutiques: [MinimalBoutique] = []
                if !boutiqueIds.isEmpty {
                    dbBoutiques = (try? await client
                        .from("boutiques")
                        .select("id, name, city")
                        .in("id", values: boutiqueIds)
                        .execute()
                        .value) ?? []
                }
                
                var dbAdvisors: [MinimalCorporateAdmin] = []
                if !saIds.isEmpty {
                    dbAdvisors = (try? await client
                        .from("corporate_admins")
                        .select("id, name")
                        .in("id", values: saIds)
                        .execute()
                        .value) ?? []
                }
                
                let formatter = DateFormatter()
                formatter.dateFormat = "d MMM yyyy"
                
                let purchases = dbItems.compactMap { item in
                    if let cat = dbCatalogs.first(where: { $0.id == item.productId }) {
                        let itemDate = item.reservedDate ?? item.createdAt ?? Date()
                        let dateStr = formatter.string(from: itemDate)
                        let imageUrl = cat.productImages?.first ?? ""
                        
                        let bq = dbBoutiques.first(where: { $0.id == item.boutiqueId })
                        let sa = dbAdvisors.first(where: { $0.id == item.salesAssociateId })
                        
                        return ClientPurchase(
                            id: item.id, 
                            name: cat.name, 
                            price: cat.amount, 
                            date: dateStr, 
                            productId: cat.id, 
                            imageUrl: imageUrl,
                            boutiqueId: bq?.id.uuidString,
                            boutiqueName: bq?.name,
                            boutiqueLocation: bq?.city,
                            advisorId: sa?.id.uuidString,
                            advisorName: sa?.name
                        )
                    }
                    return nil
                }
                savePurchases(purchases, for: clientId)
            } else {
                // Do not clear local cache if no records exist on Supabase (e.g. mock clients)
            }
        } catch {
            print("Supabase fetch purchased_items warning: \(error.localizedDescription)")
        }
    }
    
    func addPurchase(clientId: UUID, name: String, price: Double, date: String = "") {
        var current = fetchPurchases(clientId: clientId)
        
        let displayDate: String
        if date.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            displayDate = formatter.string(from: Date())
        } else {
            displayDate = date
        }
        
        let newPurchase = ClientPurchase(id: UUID(), name: name, price: price, date: displayDate)
        current.insert(newPurchase, at: 0)
        savePurchases(current, for: clientId)
        
        // Sync to Supabase in background
        Task {
            do {
                let dbCatalogs: [CatalogEntity] = try await client
                    .from("catalogs")
                    .select()
                    .execute()
                    .value
                
                let matchingCatalog = dbCatalogs.first { cat in
                    name.lowercased().contains(cat.name.lowercased()) || cat.name.lowercased().contains(name.lowercased())
                }
                
                guard let targetCatalog = matchingCatalog ?? dbCatalogs.first else {
                    print("No catalogs available to map purchase.")
                    return
                }
                
                let piPayload: [String: AnyJSON] = [
                    "id": .string(newPurchase.id.uuidString),
                    "uid": .string(clientId.uuidString),
                    "product_id": .string(targetCatalog.id.uuidString),
                    "transaction_id": .string(UUID().uuidString),
                    "status": .string("Completed")
                ]
                
                try await client
                    .from("purchased_items")
                    .insert(piPayload)
                    .execute()
                print("Successfully synced purchase to purchased_items on Supabase.")
            } catch {
                print("Supabase purchased_items sync warning: \(error.localizedDescription)")
            }
        }
    }
}
