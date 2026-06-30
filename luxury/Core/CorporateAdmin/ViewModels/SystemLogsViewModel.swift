//
//  SystemLogsViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 18/05/26.
//

import SwiftUI
import Observation
import Supabase

@Observable
final class SystemLogsViewModel {
    var selectedCategory: LogCategory?
    var isLoading = false
    var errorMessage: String?
    
    var logs: [SystemLogEntry] = []
    
    private let client = SupabaseManager.shared.client
    
    var filteredLogs: [SystemLogEntry] {
        if let category = selectedCategory {
            return logs.filter { $0.category == category }
        }
        return logs
    }
    
    func fetchData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response: [SystemLogEntry] = try await client.from("audit_logs")
                    .select()
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                await MainActor.run {
                    self.logs = response
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to fetch logs: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
}
