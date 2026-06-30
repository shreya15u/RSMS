//
//  SalesProductDetailViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation

@Observable
final class SalesProductDetailViewModel {
    var recommendations: [CatalogEntity] = []
    var isLoadingRecommendations = false
    var stockCount: Int = 0
    var isStockLoading = true
    
    private let catalogService = CatalogService()
    
    func fetchRecommendations(for catalog: CatalogEntity) {
        isLoadingRecommendations = true
        isStockLoading = true
        Task {
            do {
                let allCatalogs = try await catalogService.fetchCatalogs()
                
                let profileTuple = try? await ProfileService().fetchCurrentProfile()
                guard let staff = profileTuple?.1 as? StaffModel, let boutiqueId = staff.boutiqueId else { return }
                let stockDict = try await InventoryService.shared.fetchAvailableStockDictionary(forBoutique: boutiqueId)
                
                let recommended = await RecommendationEngine.shared.suggestRelatedProducts(for: catalog, catalog: allCatalogs, availableStock: stockDict, limit: 3)
                
                await MainActor.run {
                    self.stockCount = stockDict[catalog.id] ?? 0
                    self.isStockLoading = false
                    self.recommendations = recommended
                    self.isLoadingRecommendations = false
                }
            } catch {
                print("Failed to fetch recommendations: \(error)")
                await MainActor.run {
                    self.isLoadingRecommendations = false
                }
            }
        }
    }
}
