//
//  TransferItemSearchViewModel.swift
//  luxury
//

import SwiftUI
import Observation
import Supabase

@Observable
final class TransferItemSearchViewModel {
    var searchText: String = ""
    var searchResults: [CatalogEntity] = []
    var isLoading: Bool = false
    
    func search() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        isLoading = true
        Task {
            do {
                let request = SupabaseManager.shared.client
                    .from("catalogs")
                    .select()
                
                let results: [CatalogEntity]
                if query.isEmpty {
                    results = try await request.limit(50).execute().value
                } else {
                    results = try await request.or("name.ilike.%\(query)%,bar_code.ilike.%\(query)%").limit(50).execute().value
                }
                
                await MainActor.run {
                    self.searchResults = results
                    self.isLoading = false
                }
            } catch {
                print("Error searching catalogs: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}
