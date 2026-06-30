import Foundation
import Observation

@Observable
final class ASTViewModel {
    var selectedClient: StoreClient?
    var purchasedItems: [PurchasedItem] = []
    
    var selectedProductId: UUID?
    var warrantyStatus: String = "valid"
    var description: String = ""
    var remark: String = ""
    
    var isLoading = false
    var errorMessage: String? = nil
    var successMessage: String? = nil
    
    func fetchPurchasedItems(for client: StoreClient) {
        self.selectedClient = client
        self.isLoading = true
        self.errorMessage = nil
        
        Task {
            do {
                let items = try await ASTService.shared.fetchPurchasedItems(for: client.id)
                await MainActor.run {
                    self.purchasedItems = items
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to load purchased items: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
    
    func submitAST(boutiqueId: UUID) {
        guard let productId = selectedProductId else {
            self.errorMessage = String(localized: "Please select a product")
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        self.successMessage = nil
        
        Task {
            do {
                _ = try await ASTService.shared.createAST(
                    id: UUID(),
                    productId: productId,
                    clientId: selectedClient?.id,
                    boutiqueId: boutiqueId,
                    warrantyStatus: warrantyStatus,
                    description: description,
                    remark: remark,
                    photoUrls: []
                )
                
                await MainActor.run {
                    self.successMessage = String(localized: "After Sales Ticket submitted successfully.")
                    self.isLoading = false
                    // Reset form
                    self.description = ""
                    self.remark = ""
                    self.selectedProductId = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to submit ticket: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
}
