//
//  RemoteConsultationViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation
import Supabase
import PostgREST
import UIKit

@Observable
final class RemoteConsultationViewModel {
    var clients: [Client] = []
    var filteredClients: [Client] = []
    var searchText: String = "" {
        didSet {
            filterClients()
        }
    }
    
    var isGeneratingLink = false
    var errorMessage: String? = nil
    var selectedClient: Client? = nil
    var generatedUrl: URL? = nil
    
    // We will track success so the view can dismiss itself
    var didSucceed = false
    
    func loadClients() async {
        do {
            let entities = try await ClientService().fetchClients()
            let fetched = entities.map { Client(entity: $0) }
            
            await MainActor.run {
                self.clients = fetched.sorted { $0.name < $1.name }
                self.filterClients()
            }
        } catch {
            print("Failed to load clients: \(error)")
        }
    }
    
    private func filterClients() {
        if searchText.isEmpty {
            filteredClients = clients
        } else {
            filteredClients = clients.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.phone?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    func startConsultation(for client: Client) async {
        await MainActor.run {
            self.isGeneratingLink = true
            self.errorMessage = nil
            self.selectedClient = client
            self.didSucceed = false
        }
        
        struct Params: Encodable {
            let clientEmail: String
            let salesAssociateName: String
            let meetLink: String
        }
        
        do {
            let roomName = "RSMS-Consultation-\(UUID().uuidString.prefix(8))"
            let roomUrl = "https://meet.element.io/\(roomName)#config.prejoinPageEnabled=false&config.disableDeepLinking=true"
            
            let params = Params(clientEmail: client.email ?? "", salesAssociateName: "Sales Associate", meetLink: roomUrl)
            struct ResponseData: Decodable { let success: Bool? }
            _ = try await SupabaseManager.shared.client.functions.invoke(
                "create-remote-consultation",
                options: FunctionInvokeOptions(body: params)
            )
            
            await MainActor.run {
                self.isGeneratingLink = false
                if let url = URL(string: roomUrl) {
                    self.generatedUrl = url
                } else {
                    self.errorMessage = "Failed to generate video link."
                }
            }
        } catch {
            print("EDGE FUNCTION FAILED WITH ERROR: \(error)")
            await MainActor.run {
                self.isGeneratingLink = false
                self.errorMessage = "Debug Error: \(error.localizedDescription)"
            }
        }
    }
}
