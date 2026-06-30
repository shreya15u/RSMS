//
//  RecommendationEngine.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import NaturalLanguage
import Vision
#if canImport(LanguageModel)
import LanguageModel
#endif

actor RecommendationEngine {
    static let shared = RecommendationEngine()
    
    private let sentenceEmbedding: NLEmbedding?
    
    private init() {
        self.sentenceEmbedding = NLEmbedding.sentenceEmbedding(for: .english)
    }
    
    func suggestProducts(for client: ClientEntity, catalog: [CatalogEntity], availableStock: [UUID: Int], limit: Int = 10) async -> [CatalogEntity] {
        let activeCatalog = catalog.filter { item in
            let stock = availableStock[item.id] ?? 0
            return item.status == .active && stock > 0
        }
        guard !activeCatalog.isEmpty else { return [] }
        
        let purchasedProductIds = client.productsPurchased ?? []
        let purchasedItems = catalog.filter { purchasedProductIds.contains($0.id) }
        
        var purchasedTextVectors: [[Float]] = []
        var purchasedVisualVectors: [[Float]] = []
        
        for item in purchasedItems {
            if let tVec = await getOrComputeTextEmbedding(for: item) {
                purchasedTextVectors.append(tVec)
            }
            if let vVec = await getOrComputeVisualEmbedding(for: item) {
                purchasedVisualVectors.append(vVec)
            }
        }
        
        let tasteTextCentroid = await MathUtilities.average(of: purchasedTextVectors)
        let tasteVisualCentroid = await MathUtilities.average(of: purchasedVisualVectors)
        
        let averagePurchaseAmount = calculateAveragePurchaseAmount(purchasedItems)
        
        var scoredItems: [(item: CatalogEntity, score: Float)] = []
        
        for item in activeCatalog {
            if purchasedProductIds.contains(item.id) { continue }
            
            var score: Float = 0
            
            var textSimilarity: Float = 0
            var visualSimilarity: Float = 0
            
            if let tCentroid = tasteTextCentroid, let itemTVec = await getOrComputeTextEmbedding(for: item) {
                textSimilarity = await MathUtilities.cosineSimilarity(tCentroid, itemTVec)
            }
            
            if let vCentroid = tasteVisualCentroid, let itemVVec = await getOrComputeVisualEmbedding(for: item) {
                visualSimilarity = await MathUtilities.cosineSimilarity(vCentroid, itemVVec)
            }
            
            let similarityScore: Float = (visualSimilarity * 0.6) + (textSimilarity * 0.4)
            score = similarityScore + 1.0
            
            if let avgAmt = averagePurchaseAmount, avgAmt > 0 {
                let priceRatio = Float(item.amount / avgAmt)
                
                if client.tier != "VIP" {
                    if priceRatio > 2.0 || priceRatio < 0.3 {
                        continue
                    }
                }
                
                var penalty: Float = 0
                if priceRatio > 2.0 {
                    penalty = (priceRatio - 2.0) * 0.1
                } else if priceRatio < 0.3 {
                    penalty = (0.3 - priceRatio) * 0.1
                }
                
                if client.tier == "VIP", penalty > 0, priceRatio > 2.0 {
                    penalty *= 0.3
                }
                
                score -= penalty
            }
            
            if isEventWithin30Days(dob: client.dob, anniversary: client.dateOfAnniversary) {
                if item.category == .jewelry || item.category == .watches {
                    score += 50.0
                }
            }
            
            let purchasedCategories = Set(purchasedItems.map { $0.category })
            if purchasedCategories.contains(item.category) {
                score -= 0.15
            } else {
                score += 0.15
            }
            
            scoredItems.append((item: item, score: score))
        }
        
        let recommended = scoredItems.sorted { $0.score > $1.score }.prefix(limit).map { $0.item }
        return recommended
    }
    
    func suggestRelatedProducts(for targetItem: CatalogEntity, catalog: [CatalogEntity], availableStock: [UUID: Int], limit: Int = 3) async -> [CatalogEntity] {
        let activeCatalog = catalog.filter { item in
            let stock = availableStock[item.id] ?? 0
            return item.status == .active && stock > 0 && item.id != targetItem.id
        }
        guard !activeCatalog.isEmpty else { return [] }
        
        let targetTextVec = await getOrComputeTextEmbedding(for: targetItem)
        let targetVisualVec = await getOrComputeVisualEmbedding(for: targetItem)
        
        var scoredItems: [(item: CatalogEntity, score: Float)] = []
        
        for item in activeCatalog {
            if targetItem.amount > 0 {
                let priceRatio = Float(item.amount / targetItem.amount)
                if priceRatio > 2.0 {
                    continue
                }
            }
            
            var textSimilarity: Float = 0
            var visualSimilarity: Float = 0
            
            if let targetTVec = targetTextVec, let itemTVec = await getOrComputeTextEmbedding(for: item) {
                textSimilarity = await MathUtilities.cosineSimilarity(targetTVec, itemTVec)
            }
            
            if let targetVVec = targetVisualVec, let itemVVec = await getOrComputeVisualEmbedding(for: item) {
                visualSimilarity = await MathUtilities.cosineSimilarity(targetVVec, itemVVec)
            }
            
            var score = (visualSimilarity * 0.6) + (textSimilarity * 0.4) + 1.0
            
            if item.category == targetItem.category {
                score -= 1.0
            } else {
                score += 0.3
            }
            
            scoredItems.append((item: item, score: score))
        }
        
        return scoredItems.sorted { $0.score > $1.score }.prefix(limit).map { $0.item }
    }
    
    private func getOrComputeTextEmbedding(for item: CatalogEntity) async -> [Float]? {
        if let cached = await VectorRegistry.shared.getTextEmbedding(for: item.id) {
            return cached
        }
        
        let textToEmbed = "\(item.name) \(item.brand) \(item.category.rawValue) \(item.description)"
        guard let sentenceEmbedding = sentenceEmbedding else { return nil }
        
        if let vector = sentenceEmbedding.vector(for: textToEmbed) {
            let floatVector = vector.map { Float($0) }
            await VectorRegistry.shared.saveTextEmbedding(floatVector, for: item.id)
            return floatVector
        }
        
        return nil
    }
    
    private func getOrComputeVisualEmbedding(for item: CatalogEntity) async -> [Float]? {
        if let cached = await VectorRegistry.shared.getVisualEmbedding(for: item.id) {
            return cached
        }
        
        guard let _ = item.productImages?.first else {
            return nil
        }
        
        let vector = generateMockVector(for: item.id)
        await VectorRegistry.shared.saveVisualEmbedding(vector, for: item.id)
        return vector
    }
    
    private func calculateAveragePurchaseAmount(_ items: [CatalogEntity]) -> Double? {
        guard !items.isEmpty else { return nil }
        let sum = items.reduce(0) { $0 + $1.amount }
        return sum / Double(items.count)
    }
    
    private func isEventWithin30Days(dob: String?, anniversary: String?) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        let now = Date()
        let calendar = Calendar.current
        
        for dateStr in [dob, anniversary].compactMap({ $0 }) {
            guard let date = formatter.date(from: dateStr) else { continue }
            
            var components = calendar.dateComponents([.month, .day], from: date)
            components.year = calendar.component(.year, from: now)
            
            if let thisYearDate = calendar.date(from: components) {
                let diff = calendar.dateComponents([.day], from: now, to: thisYearDate).day ?? Int.max
                
                if diff >= 0 && diff <= 30 {
                    return true
                }
                
                components.year! += 1
                if let nextYearDate = calendar.date(from: components) {
                    let nextDiff = calendar.dateComponents([.day], from: now, to: nextYearDate).day ?? Int.max
                    if nextDiff >= 0 && nextDiff <= 30 {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func generateMockVector(for uuid: UUID) -> [Float] {
        var rng = SystemRandomNumberGenerator()
        return (0..<512).map { _ in Float.random(in: -1...1, using: &rng) }
    }
    
    @available(iOS 18.0, *)
    func generatePersonalizedInsight(client: ClientEntity, recommendations: [CatalogEntity]) async -> String? {
        guard let topItem = recommendations.first else {
            return "We have curated a selection of items matching your profile."
        }
        
        let categoryName = topItem.category.rawValue.lowercased()
        
        if client.tier == "VIP" {
            return "As an exclusive VIP, we curated these exceptional \(categoryName) specifically for your distinct taste, \(client.name)."
        } else {
            return "Based on your interest in \(categoryName), we curated this selection to complement your style."
        }
    }
}
