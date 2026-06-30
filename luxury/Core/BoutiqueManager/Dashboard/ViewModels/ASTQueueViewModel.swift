import Foundation
import Observation

@Observable
final class ASTQueueViewModel {
    var asts: [AST] = []
    var isLoading = false
    var errorMessage: String? = nil
    
    // For storing fetched client and product names
    var clientNames: [UUID: String] = [:]
    var productNames: [UUID: String] = [:]
    
    func fetchQueue() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                var boutiqueId: UUID? = nil
                if let (_, profile) = try await ProfileService().fetchCurrentProfile(),
                   let boutique = profile as? CorporateBoutique {
                    boutiqueId = boutique.id
                }
                
                guard let bId = boutiqueId else {
                    await MainActor.run {
                        self.errorMessage = String(localized: "No boutique ID found for current manager.")
                        self.isLoading = false
                    }
                    return
                }
                
                let fetchedASTs = try await ASTService.shared.fetchASTs(forBoutique: bId)
                
                // Fetch associated clients and products to display names
                var newClientNames: [UUID: String] = [:]
                var newProductNames: [UUID: String] = [:]
                
                let allCatalogs = try? await CatalogService().fetchCatalogs()
                var catalogDict: [UUID: String] = [:]
                if let allCatalogs = allCatalogs {
                    for cat in allCatalogs {
                        catalogDict[cat.id] = cat.name
                    }
                }
                
                // Note: In a production app with a large number of ASTs, these should be batched
                // or done via a SQL JOIN view in Supabase. We do individual fetches here for simplicity.
                for ast in fetchedASTs {
                    if let clientId = ast.clientId, newClientNames[clientId] == nil {
                        if let client = try? await ClientService().fetchClient(id: clientId) {
                            newClientNames[clientId] = client.name
                        }
                    }
                    if let cName = catalogDict[ast.productId] {
                        newProductNames[ast.productId] = cName
                    }
                }
                
                await MainActor.run {
                    self.asts = fetchedASTs
                    self.clientNames = newClientNames
                    self.productNames = newProductNames
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to load AST queue: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
}
