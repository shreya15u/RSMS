//
//  POSViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation
import UIKit

struct POSCartRow: Identifiable, Codable {
    var id = UUID()
    let product: CatalogItem
    var qty: Int
}

@Observable
final class POSViewModel {
    static let shared = POSViewModel()
    
    var availableProducts: [CatalogItem] = []
    
    var clientCarts: [UUID: [POSCartRow]] = [:] {
        didSet { saveCarts() }
    }
    var guestCart: [POSCartRow] = [] {
        didSet { saveCarts() }
    }
    
    var cartItems: [POSCartRow] {
        get {
            if let client = selectedClient {
                return clientCarts[client.id] ?? []
            } else {
                return guestCart
            }
        }
        set {
            if let client = selectedClient {
                clientCarts[client.id] = newValue
            } else {
                guestCart = newValue
            }
        }
    }
    
    var selectedClient: StoreClient? = nil
    
    private init() {
        loadCarts()
    }
    
    private func saveCarts() {
        if let encoded = try? JSONEncoder().encode(clientCarts) {
            UserDefaults.standard.set(encoded, forKey: "savedClientCarts")
        }
        if let encoded = try? JSONEncoder().encode(guestCart) {
            UserDefaults.standard.set(encoded, forKey: "savedGuestCart")
        }
    }

    private func loadCarts() {
        if let savedClientCartsData = UserDefaults.standard.data(forKey: "savedClientCarts"),
           let decoded = try? JSONDecoder().decode([UUID: [POSCartRow]].self, from: savedClientCartsData) {
            self.clientCarts = decoded
        }
        if let savedGuestCartData = UserDefaults.standard.data(forKey: "savedGuestCart"),
           let decoded = try? JSONDecoder().decode([POSCartRow].self, from: savedGuestCartData) {
            self.guestCart = decoded
        }
    }
    
    var taxFree: Bool = false
    var isGiftInvoice: Bool = false
    var offlineCartQueued: Bool = true
    
    var isProcessingPayment: Bool = false
    var paymentError: String? = nil
    var lastTransactionId: String? = nil
    var lastTotalPaid: Int? = nil
    var lastPurchasedItems: [POSCartRow] = []
    var lastClient: StoreClient? = nil
    var lastBoutique: CorporateBoutique? = nil
    
    var activeCampaigns: [PricingCampaign] = []
    var appliedCampaign: PricingCampaign? = nil
    
    var isLoadingProducts = false
    var errorMessage: String? = nil
    
    var subtotal: Int {
        Int(cartItems.reduce(0) { $0 + ($1.product.amount * Double($1.qty)) })
    }
    
    var campaignDiscountAmount: Int {
        guard let campaign = appliedCampaign else { return 0 }
        let eligibleSubtotal = cartItems.filter { item in
            campaign.affectedCategories.contains("All") || campaign.affectedCategories.contains(item.product.category)
        }.reduce(0) { $0 + ($1.product.amount * Double($1.qty)) }
        return Int(Double(eligibleSubtotal) * (campaign.discountPercentage / 100.0))
    }
    
    var tax: Int {
        taxFree ? 0 : Int(Double(subtotal - campaignDiscountAmount) * 0.03)
    }
    
    var total: Int {
        subtotal - campaignDiscountAmount + tax
    }
    
    func fetchProducts() {
        isLoadingProducts = true
        Task {
            do {
                let products = try await POSDataService.shared.fetchCatalogs()
                let campaigns = try? await POSDataService.shared.fetchActiveCampaigns()
                await MainActor.run {
                    self.availableProducts = products
                    self.activeCampaigns = campaigns ?? []
                    self.isLoadingProducts = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoadingProducts = false
                }
            }
        }
    }
    
    func addToCart(_ item: CatalogItem) {
        if let index = cartItems.firstIndex(where: { $0.product.id == item.id }) {
            cartItems[index].qty += 1
        } else {
            cartItems.append(POSCartRow(product: item, qty: 1))
        }
    }
    
    func increaseQty(of id: UUID) {
        if let index = cartItems.firstIndex(where: { $0.id == id }) {
            cartItems[index].qty += 1
        }
    }
    
    func decreaseQty(of id: UUID) {
        if let index = cartItems.firstIndex(where: { $0.id == id }) {
            if cartItems[index].qty > 1 {
                cartItems[index].qty -= 1
            } else {
                cartItems.remove(at: index)
            }
        }
    }
    
    func attachClient(_ client: StoreClient) {
        if !guestCart.isEmpty {
            var currentClientCart = clientCarts[client.id] ?? []
            for item in guestCart {
                if let index = currentClientCart.firstIndex(where: { $0.id == item.id }) {
                    currentClientCart[index].qty += item.qty
                } else {
                    currentClientCart.append(item)
                }
            }
            clientCarts[client.id] = currentClientCart
            guestCart.removeAll()
        }
        self.selectedClient = client
    }
    
    @MainActor
    func processPayment(presentingViewController: UIViewController) async -> Bool {
        guard selectedClient != nil else {
            self.paymentError = "A client must be attached to the cart before processing payment."
            return false
        }
        
        isProcessingPayment = true
        paymentError = nil
        
        do {
            guard let result = try await ProfileService().fetchCurrentProfile() else {
                self.paymentError = "Could not find your user profile in the system."
                self.isProcessingPayment = false
                return false
            }
            
            guard let staff = result.1 as? StaffModel else {
                self.paymentError = "Only Sales Associates can process checkouts."
                self.isProcessingPayment = false
                return false
            }
            
            guard let validBoutiqueId = staff.boutiqueId else {
                self.paymentError = "You are not assigned to a boutique yet."
                self.isProcessingPayment = false
                return false
            }
            
            let staffId = staff.id
            let boutiqueId = validBoutiqueId
            
            // 1. Process payment gateway
            let transactionIdStr = try await PaymentService.shared.processPayment(
                amount: Double(total),
                description: "POS Checkout",
                presentingViewController: presentingViewController
            )
            
            // 2. Create Transaction in DB
            let transaction = try await POSDataService.shared.createTransaction(
                amount: Double(total),
                purpose: TransactionPurpose.purchase.rawValue,
                clientId: selectedClient?.id,
                boutiqueId: boutiqueId,
                staffId: staffId,
                paymentGatewayId: transactionIdStr,
                isGift: isGiftInvoice,
                isTax: taxFree
            )
            
            // Extract product IDs multiplied by qty
            var productIds: [UUID] = []
            for item in cartItems {
                for _ in 0..<item.qty {
                    productIds.append(item.product.id)
                }
            }
            
            // 3. Create Cart in DB
            let cart = try await POSDataService.shared.createCart(
                clientId: selectedClient?.id,
                boutiqueId: boutiqueId,
                total: Double(total),
                productIds: productIds
            )
            
            // 4. Complete Checkout in DB
            try await POSDataService.shared.checkout(
                cartId: cart.id,
                transactionId: transaction.id,
                staffId: staffId,
                boutiqueId: boutiqueId,
                total: Double(total),
                productIds: productIds,
                clientId: selectedClient?.id
            )
            
            self.lastTotalPaid = self.total
            self.lastTransactionId = transaction.id.uuidString
            self.lastPurchasedItems = self.cartItems
            self.lastBoutique = try? await ProfileService().fetchBoutique(id: boutiqueId)
            self.lastClient = self.selectedClient
            self.offlineCartQueued = false
            self.isProcessingPayment = false
            self.cartItems.removeAll()
            self.selectedClient = nil
            return true
        } catch {
            self.paymentError = error.localizedDescription
            self.isProcessingPayment = false
            return false
        }
    }
    
    func formatCurrency(_ amount: Int) -> String {
        return CurrencyManager.shared.format(amount: Double(amount))
    }
}

