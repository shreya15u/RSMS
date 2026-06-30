import Foundation

/// Thread-safe actor to cache heavy embeddings (text and visual) for products.
actor VectorRegistry {
    static let shared = VectorRegistry()
    
    private var textEmbeddings: [UUID: [Float]] = [:]
    private var visualEmbeddings: [UUID: [Float]] = [:]
    
    private init() {}
    
    /// Retrieves a cached text embedding for a given CatalogEntity ID.
    func getTextEmbedding(for id: UUID) -> [Float]? {
        return textEmbeddings[id]
    }
    
    /// Retrieves a cached visual embedding for a given CatalogEntity ID.
    func getVisualEmbedding(for id: UUID) -> [Float]? {
        return visualEmbeddings[id]
    }
    
    /// Saves a text embedding to the cache.
    func saveTextEmbedding(_ embedding: [Float], for id: UUID) {
        textEmbeddings[id] = embedding
    }
    
    /// Saves a visual embedding to the cache.
    func saveVisualEmbedding(_ embedding: [Float], for id: UUID) {
        visualEmbeddings[id] = embedding
    }
    
    /// Clears all cached embeddings. Useful for memory warnings or when the user switches accounts.
    func clearCache() {
        textEmbeddings.removeAll(keepingCapacity: false)
        visualEmbeddings.removeAll(keepingCapacity: false)
    }
}
