//
//  TicketsService.swift
//  luxury
//
//  Created by Nalinish Ranjan on 26/05/26.
//

import Foundation
import Supabase

struct DBClientTicket: Codable {
    let id: UUID
    let clientId: UUID
    let title: String
    let status: String
    let date: String
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case title
        case status
        case date
        case isActive = "is_active"
    }
}

final class TicketsService {
    static let shared = TicketsService()
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    private func localKey(for clientId: UUID) -> String {
        return "luxury_tickets_\(clientId.uuidString)"
    }
    
    func fetchTickets(clientId: UUID) -> [ClientTicket] {
        let key = localKey(for: clientId)
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                return try JSONDecoder().decode([ClientTicket].self, from: data)
            } catch {
                print("Error decoding local tickets: \(error)")
            }
        }
        return []
    }
    
    func saveLocalTickets(_ tickets: [ClientTicket], for clientId: UUID) {
        let key = localKey(for: clientId)
        do {
            let data = try JSONEncoder().encode(tickets)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Error encoding local tickets: \(error)")
        }
    }
    
    func syncTickets(clientId: UUID) async {
        do {
            let dbTickets: [DBClientTicket] = try await client
                .from("client_tickets")
                .select()
                .eq("client_id", value: clientId.uuidString)
                .execute()
                .value
            
            let tickets = dbTickets.map {
                ClientTicket(id: $0.id, title: $0.title, status: $0.status, date: $0.date, isActive: $0.isActive)
            }
            saveLocalTickets(tickets, for: clientId)
        } catch {
            print("Supabase fetch client_tickets warning: \(error.localizedDescription)")
        }
    }
}
