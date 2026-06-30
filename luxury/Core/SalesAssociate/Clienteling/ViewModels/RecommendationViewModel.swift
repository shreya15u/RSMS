//
//  RecommendationViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import SwiftUI
import Observation
import Supabase
import PostgREST

@Observable
final class RecommendationViewModel {
    var recommendations: [CatalogEntity] = []
    var insight: String = ""
    var isLoading: Bool = false
    var error: String? = nil
    
    private let client: Client
    
    init(client: Client) {
        self.client = client
    }
    
    @MainActor
    func loadRecommendations() async {
        guard recommendations.isEmpty else { return }
        
        isLoading = true
        error = nil
        
        do {
            let catalogs = try await CatalogService().fetchCatalogs()
            
            let profileTuple = try? await ProfileService().fetchCurrentProfile()
            guard let staff = profileTuple?.1 as? StaffModel, let boutiqueId = staff.boutiqueId else {
                throw NSError(domain: "RecommendationViewModel", code: 401, userInfo: [NSLocalizedDescriptionKey: "No boutique assigned to current user."])
            }
            let stockDict = try await InventoryService.shared.fetchAvailableStockDictionary(forBoutique: boutiqueId)
            
            let purchases = PurchaseHistoryService.shared.fetchPurchases(clientId: client.id)
            let productIds = purchases.compactMap { $0.productId }
            
            let clientEntity = ClientEntity(
                id: client.id,
                name: client.name,
                email: client.email ?? "",
                phone: client.phone,
                dob: client.dob,
                tier: client.tier.rawValue,
                productsPurchased: productIds,
                createdAt: client.createdAt ?? Date(),
                updatedAt: Date(),
                maritalStatus: client.maritalStatus,
                dateOfAnniversary: client.dateOfAnniversary
            )
            
            let engine = RecommendationEngine.shared
            let results = await engine.suggestProducts(for: clientEntity, catalog: catalogs, availableStock: stockDict, limit: 10)
            
            let generatedInsight: String
            if #available(iOS 18.0, *) {
                generatedInsight = await engine.generatePersonalizedInsight(client: clientEntity, recommendations: results) ?? "Curated picks based on their profile."
            } else {
                generatedInsight = "Curated picks based on their profile."
            }
            
            self.recommendations = results
            self.insight = generatedInsight
            self.isLoading = false
            
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }
}
