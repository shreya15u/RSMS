//
//  BoutiqueConfigViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 18/05/26.
//

import SwiftUI
import Observation
import Supabase

@Observable
final class BoutiqueConfigViewModel {
    var searchText: String = ""
    var isLoading = false
    var errorMessage: String?
    
    var boutiques: [CorporateBoutique] = []
    
    private let client = SupabaseManager.shared.client
    
    var filteredBoutiques: [CorporateBoutique] {
        if searchText.isEmpty {
            return boutiques
        }
        return boutiques.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.city.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetched: [CorporateBoutique] = try await client.from("boutiques").select().eq("status", value: "approved").execute().value
                await MainActor.run {
                    self.boutiques = fetched
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to fetch boutiques: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
    
    func updateBoutique(_ boutique: CorporateBoutique) {
        Task {
            do {
                try await client.from("boutiques").update(boutique).eq("id", value: boutique.id).execute()
                await MainActor.run {
                    fetchData()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to update boutique: \(error.localizedDescription)")
                }
            }
        }
    }
}
