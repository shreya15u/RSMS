//
//  StoreViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation
import Supabase
import PostgREST

@Observable
final class StoreViewModel {
    var pendingTransfersCount: Int = 0
    var pendingCycleCountsCount: Int = 0
    var activeCampaigns: [PricingCampaign] = []
    
    var events: [StoreEvent] = []
    var boutiqueId: UUID?
    
    private let localEventsKey = "luxury_local_events"
    
    init() {
        loadLocalEvents()
        fetchPendingTransfersCount()
        Task {
            await fetchActiveCampaigns()
            await fetchPendingAuditsCount()
        }
    }
    
    func fetchActiveCampaigns() async {
        do {
            let response = try await SupabaseManager.shared.client
                .from("campaigns")
                .select()
                .eq("status", value: "Active")
                .execute()
            
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
            
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                if let date = formatter.date(from: dateString) {
                    return date
                }
                if let date = ISO8601DateFormatter().date(from: dateString) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date")
            }
            
            let fetched = try decoder.decode([PricingCampaign].self, from: response.data)
            await MainActor.run {
                self.activeCampaigns = fetched
            }
        } catch {
            print("StoreViewModel: Failed to fetch campaigns \(error)")
        }
    }
    
    func fetchPendingTransfersCount() {
        Task {
            do {
                var fetchedBoutiqueId: UUID?
                if let profile = try? await ProfileService().fetchCurrentProfile(),
                   let manager = profile.1 as? CorporateBoutique {
                    fetchedBoutiqueId = manager.id
                }
                
                await MainActor.run {
                    self.boutiqueId = fetchedBoutiqueId
                }
                
                let count = try await StockTransferService.shared.fetchPendingCount(for: fetchedBoutiqueId)
                await MainActor.run {
                    self.pendingTransfersCount = count
                }
            } catch {
                print("StoreViewModel: Failed to fetch pending transfers count: \(error)")
            }
        }
    }
    
    func fetchPendingAuditsCount() async {
        do {
            let profile = try await ProfileService().fetchCurrentProfile()
            guard let manager = profile?.1 as? CorporateBoutique else { return }
            let boutiqueId = manager.id
            
            let response = try await SupabaseManager.shared.client
                .from("audits")
                .select("id")
                .eq("boutique_id", value: boutiqueId.uuidString)
                .eq("status", value: "due")
                .execute()
            
            struct AuditID: Codable {
                let id: UUID
            }
            let decoder = JSONDecoder()
            let fetched = try decoder.decode([AuditID].self, from: response.data)
            
            await MainActor.run {
                self.pendingCycleCountsCount = fetched.count
            }
        } catch {
            print("StoreViewModel: Failed to fetch pending audits count: \(error)")
        }
    }
    
    func loadLocalEvents() {
        if let data = UserDefaults.standard.data(forKey: localEventsKey) {
            do {
                let decoded = try JSONDecoder().decode([StoreEvent].self, from: data)
                if !decoded.isEmpty {
                    self.events = decoded
                    return
                }
            } catch {
                print("Failed to decode local events: \(error)")
            }
        }
        
        // No local events found
        self.events = []
        saveLocalEvents()
    }
    
    func saveLocalEvents() {
        do {
            let data = try JSONEncoder().encode(events)
            UserDefaults.standard.set(data, forKey: localEventsKey)
        } catch {
            print("Failed to encode local events: \(error)")
        }
    }
    
    func addEvent(_ event: StoreEvent) {
        events.append(event)
        saveLocalEvents()
    }
    
    func updateEvent(_ event: StoreEvent) {
        if let idx = events.firstIndex(where: { $0.id == event.id }) {
            events[idx] = event
            saveLocalEvents()
        }
    }
    
    func deleteEvent(id: UUID) {
        events.removeAll(where: { $0.id == id })
        saveLocalEvents()
    }
}
