//
//  ClientService.swift
//  luxury
//
//  Created by Nalinish Ranjan on 21/05/26.
//

import Foundation
import Supabase

final class ClientService {
    private let client = SupabaseManager.shared.client
    private let localClientsKey = "luxury_local_clients_v2"
    
    private var localEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
    private var localDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            
            if let dateString = try? container.decode(String.self) {
                let formatters = [
                    "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ",
                    "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
                    "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
                    "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
                    "yyyy-MM-dd HH:mm:ss"
                ]
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                for format in formatters {
                    formatter.dateFormat = format
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
                if let date = ISO8601DateFormatter().date(from: dateString) {
                    return date
                }
            } else if let doubleValue = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: doubleValue)
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date"
            )
        }
        return decoder
    }
    
    private func getLocalClients() -> [ClientEntity] {
        guard let data = UserDefaults.standard.data(forKey: localClientsKey) else {
            return []
        }
        do {
            return try localDecoder.decode([ClientEntity].self, from: data)
        } catch {
            print("Error decoding local clients: \(error)")
            return []
        }
    }
    
    private func saveLocalClients(_ clients: [ClientEntity]) {
        do {
            let data = try localEncoder.encode(clients)
            UserDefaults.standard.set(data, forKey: localClientsKey)
        } catch {
            print("Error encoding local clients: \(error)")
        }
    }
    
    func fetchClients() async throws -> [ClientEntity] {
        do {
            let response = try await client
                .from("client")
                .select()
                .execute()
            
            return try localDecoder.decode([ClientEntity].self, from: response.data)
        } catch {
            print("Database fetch clients failed with error: \(error). Raw error: \(String(describing: error))")
            return []
        }
    }
    
    func fetchClient(id: UUID) async throws -> ClientEntity {
        let response = try await client
            .from("client")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            
        return try localDecoder.decode(ClientEntity.self, from: response.data)
    }
    
    func createClient(_ clientEntity: ClientEntity) async throws {
        try await client
            .from("client")
            .insert(clientEntity)
            .execute()
    }
    
    func updateClient(_ clientEntity: ClientEntity) async throws {
        try await client
            .from("client")
            .update(clientEntity)
            .eq("id", value: clientEntity.id.uuidString)
            .execute()
    }
    
    func deleteClient(id: UUID) async throws {
        let uuidStr = id.uuidString
        
        _ = try? await client.from("appointment").delete().eq("client_id", value: uuidStr).execute()
        _ = try? await client.from("ast").delete().eq("client_id", value: uuidStr).execute()
        _ = try? await client.from("cart").delete().eq("client_id", value: uuidStr).execute()
        _ = try? await client.from("purchased_items").delete().eq("uid", value: uuidStr).execute()
        _ = try? await client.from("transaction").delete().eq("client_id", value: uuidStr).execute()
        _ = try? await client.from("wishlist").delete().eq("client_id", value: uuidStr).execute()
        _ = try? await client.from("tickets").delete().eq("client_id", value: uuidStr).execute()
        _ = try? await client.from("size_preferences").delete().eq("client_id", value: uuidStr).execute()
        _ = try? await client.from("client_notes").delete().eq("client_id", value: uuidStr).execute()
        
        try await client
            .from("client")
            .delete()
            .eq("id", value: uuidStr)
            .execute()
    }
}
