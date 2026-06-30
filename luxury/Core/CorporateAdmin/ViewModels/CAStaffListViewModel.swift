//
//  CAStaffListViewModel.swift
//  luxury
//

import SwiftUI
import Observation
import Supabase

@Observable
final class CAStaffListViewModel {
    var staffMembers: [StaffModel] = []
    var boutiques: [UUID: CorporateBoutique] = [:]
    var isLoading = false
    var errorMessage: String?
    
    private let client = SupabaseManager.shared.client
    
    func fetchStaff() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                async let staffTask: [StaffModel] = try client.from("staff").select().execute().value
                async let boutiquesTask: [CorporateBoutique] = try client.from("boutiques").select().execute().value
                
                let (staffResponse, boutiquesResponse) = try await (staffTask, boutiquesTask)
                
                let boutiqueDict = Dictionary(uniqueKeysWithValues: boutiquesResponse.map { ($0.id, $0) })
                
                await MainActor.run {
                    self.staffMembers = staffResponse
                    self.boutiques = boutiqueDict
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to fetch staff: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
}
