//
//  SizePreferenceService.swift
//  luxury
//
//  Created by Nalinish Ranjan on 22/05/26.
//

import Foundation
import Supabase

struct DBSizePreference: Codable {
    let clientId: UUID
    var salesAssociateId: UUID?
    let ringSize: String
    let wristSize: String
    let apparelSize: String
    let shoeSize: String
    
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case salesAssociateId = "sales_associate_id"
        case ringSize = "ring_size"
        case wristSize = "wrist_size"
        case apparelSize = "apparel_size"
        case shoeSize = "shoe_size"
    }
}

final class SizePreferenceService {
    static let shared = SizePreferenceService()
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    private func localKey(for clientId: UUID) -> String {
        return "luxury_sizes_\(clientId.uuidString)"
    }
    
    func fetchSizePreference(clientId: UUID) -> ClientSizePreference {
        let key = localKey(for: clientId)
        
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                return try JSONDecoder().decode(ClientSizePreference.self, from: data)
            } catch {
                print("Error decoding local sizes: \(error)")
            }
        }
        
        // Default empty preferences for new clients
        return ClientSizePreference(id: clientId)
    }
    
    func saveSizePreference(_ sizes: ClientSizePreference, for clientId: UUID) {
        let key = localKey(for: clientId)
        do {
            let data = try JSONEncoder().encode(sizes)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Error encoding local sizes: \(error)")
        }
        
        // Sync to Supabase in background
        Task {
            do {
                let session = try? await client.auth.session
                let saId = session?.user.id
                let dbSize = DBSizePreference(
                    clientId: clientId,
                    salesAssociateId: saId,
                    ringSize: sizes.ringSize,
                    wristSize: sizes.wristSize,
                    apparelSize: sizes.apparelSize,
                    shoeSize: sizes.shoeSize
                )
                try await client
                    .from("size_preferences")
                    .upsert(dbSize, onConflict: "client_id")
                    .execute()
                print("Successfully synced size preferences to Supabase.")
            } catch {
                print("Supabase size preference upsert warning: \(error.localizedDescription)")
            }
        }
    }
    
    func syncSizePreference(clientId: UUID) async {
        do {
            let response: [DBSizePreference] = try await client
                .from("size_preferences")
                .select()
                .eq("client_id", value: clientId.uuidString)
                .execute()
                .value
            
            if let first = response.first {
                let local = ClientSizePreference(
                    id: clientId,
                    ringSize: first.ringSize,
                    wristSize: first.wristSize,
                    apparelSize: first.apparelSize,
                    shoeSize: first.shoeSize
                )
                
                // Save locally without triggering background sync recursively
                let key = localKey(for: clientId)
                if let data = try? JSONEncoder().encode(local) {
                    UserDefaults.standard.set(data, forKey: key)
                }
            }
        } catch {
            print("Supabase fetch size_preferences warning: \(error.localizedDescription)")
        }
    }
}
