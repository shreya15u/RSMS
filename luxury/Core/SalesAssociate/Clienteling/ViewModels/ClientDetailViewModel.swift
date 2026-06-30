//
//  ClientDetailViewModel.swift
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
final class ClientDetailViewModel {
    static let defaultClient = Client(name: "Unknown", tier: .silver, lastVisit: "Unknown", ltv: 0.0, initial: "U", isHot: false)
    
    var client: Client {
        didSet {
            refreshWishlist()
            refreshSizes()
            refreshPurchases()
            refreshNotes()
            refreshActiveServices()
        }
    }
    var selectedTab: String = "overview"
    let tabs = [("overview", "Overview"), ("appointments", "Appts"), ("history", "History"), ("wishlist", "Wishlist"), ("recommendations", "AI Picks"), ("notes", "Notes")]
    
    var wishlistItems: [ClientWishlistItem] = []
    var wishlistCatalogs: [CatalogItem] = []
    var sizes: ClientSizePreference = ClientSizePreference()
    var purchases: [ClientPurchase] = []
    var appointments: [AppointmentEntity] = []
    var notes: [ClientNote] = []
    var activeServices: [ASTDetails] = []
    var boutiqueName: String = "Maison Mumbai"
    
    
    var joinedDateText: String {
        let dateToUse = client.createdAt ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        let dateStr = formatter.string(from: dateToUse)
        return "\(boutiqueName) · Since \(dateStr)"
    }
    
    var stats: [(String, String)] {
        let countText = String(wishlistItems.count)
        let purchaseCountText = String(purchases.count)
        let calculatedLtv = purchases.reduce(0.0) { $0 + $1.price }
        return [
            (CurrencyManager.shared.formatCompact(amount: calculatedLtv), "Lifetime Value"),
            (purchaseCountText, "Purchases"),
            (countText, "Wishlist")
        ]
    }
    
    init(client: Client = ClientDetailViewModel.defaultClient) {
        self.client = client
        refreshWishlist()
        refreshSizes()
        refreshPurchases()
        refreshAppointments()
        refreshNotes()
        refreshActiveServices()
        fetchBoutiqueName()
    }
    
    func fetchBoutiqueName() {
        Task {
            do {
                if let (_, profileAny) = try await ProfileService().fetchCurrentProfile() {
                    if let staff = profileAny as? StaffModel, let bId = staff.boutiqueId {
                        if let bq = try await ProfileService().fetchBoutique(id: bId) {
                            await MainActor.run { self.boutiqueName = bq.name }
                        }
                    } else if let manager = profileAny as? CorporateBoutique {
                        await MainActor.run { self.boutiqueName = manager.name }
                    }
                }
            } catch {
                print("Failed to fetch boutique name: \(error)")
            }
        }
    }
    
    func refreshWishlist() {
        self.wishlistItems = WishlistService.shared.fetchWishlist(clientId: client.id)
        Task {
            await WishlistService.shared.syncWishlist(clientId: client.id)
            let updated = WishlistService.shared.fetchWishlist(clientId: client.id)
            
            // Fetch full CatalogItems for the updated wishlist
            let productIds = updated.map { $0.id }
            var fullItems: [CatalogItem] = []
            if !productIds.isEmpty {
                do {
                    let dbCatalogs: [CatalogEntity] = try await SupabaseManager.shared.client
                        .from("catalogs")
                        .select()
                        .in("id", values: productIds.map { $0.uuidString })
                        .execute()
                        .value
                    
                    fullItems = dbCatalogs.map { cat in
                        CatalogItem(
                            id: cat.id,
                            catalogId: cat.catalogId,
                            name: cat.name,
                            description: cat.description,
                            brand: cat.brand,
                            category: cat.category.rawValue,
                            amount: cat.amount,
                            barCode: cat.barCode,
                            status: cat.status.rawValue,
                            createdAt: nil,
                            productImages: cat.productImages
                        )
                    }
                } catch {
                    print("Error fetching full catalog items for wishlist: \(error)")
                }
            }
            
            await MainActor.run {
                self.wishlistItems = updated
                self.wishlistCatalogs = fullItems
            }
        }
    }
    
    func refreshSizes() {
        self.sizes = SizePreferenceService.shared.fetchSizePreference(clientId: client.id)
    }
    
    func refreshPurchases() {
        self.purchases = PurchaseHistoryService.shared.fetchPurchases(clientId: client.id)
        Task {
            await PurchaseHistoryService.shared.syncPurchases(clientId: client.id)
            let updated = PurchaseHistoryService.shared.fetchPurchases(clientId: client.id)
            await MainActor.run {
                self.purchases = updated
            }
        }
    }
    
    func refreshAppointments() {
        Task {
            do {
                let fetched: [AppointmentEntity] = try await SupabaseManager.shared.client
                    .from("appointment")
                    .select()
                    .eq("client_id", value: client.id)
                    .order("timestamp", ascending: false)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.appointments = fetched
                }
            } catch {
                print("Failed to fetch client appointments: \(error)")
            }
        }
    }
    
    func refreshActiveServices() {
        Task {
            do {
                let fetched: [ASTDetails] = try await SupabaseManager.shared.client
                    .from("ast")
                    .select("*, catalogs(*), client(*)")
                    .eq("client_id", value: client.id)
                    .order("id", ascending: false)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.activeServices = fetched
                }
            } catch {
                print("Failed to fetch active services: \(error)")
            }
        }
    }
    
    func saveSizes(_ newSizes: ClientSizePreference) {
        SizePreferenceService.shared.saveSizePreference(newSizes, for: client.id)
        self.sizes = newSizes
    }
    
    private func parsePrice(_ priceStr: String) -> Int {
        let cleanStr = priceStr.filter { $0.isNumber }
        return Int(cleanStr) ?? 0
    }
    
    private func formatIndianCurrency(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_IN")
        if let formatted = formatter.string(from: NSNumber(value: value)) {
            return "\(CurrencyManager.shared.symbol)\(formatted)"
        }
        return "\(CurrencyManager.shared.symbol)\(value)"
    }
    
    func addClientPurchase(brand: String, name: String, price: Double) {
        let fullName = brand.isEmpty ? name : "\(brand) \(name)"
        PurchaseHistoryService.shared.addPurchase(clientId: client.id, name: fullName, price: price)
        
        // Refresh purchases so stats recalculate correctly
        self.refreshPurchases()
        
        let updatedClient = Client(
            id: client.id,
            name: client.name,
            tier: client.tier,
            lastVisit: "Today",
            ltv: client.ltv,
            initial: client.initial,
            isHot: client.isHot,
            phone: client.phone,
            email: client.email,
            dob: client.dob,
            maritalStatus: client.maritalStatus,
            dateOfAnniversary: client.dateOfAnniversary
        )
        self.client = updatedClient
        
        NotificationCenter.default.post(name: NSNotification.Name("RefreshClients"), object: nil)
    }
    
    func addProductToWishlist(productId: UUID = UUID(), brand: String, name: String, price: Double) async throws {
        let catalogs: [CatalogEntity] = (try? await SupabaseManager.shared.client.from("catalogs").select().eq("id", value: productId.uuidString).execute().value) ?? []
        let images = catalogs.first?.productImages
        let newItem = ClientWishlistItem(id: productId, brand: brand, name: name, price: price, productImages: images)
        try await WishlistService.shared.addToWishlist(clientId: client.id, item: newItem)
        await MainActor.run {
            self.refreshWishlist()
        }
    }
    
    func removeProductFromWishlist(itemId: UUID) async {
        await WishlistService.shared.removeFromWishlist(clientId: client.id, itemId: itemId)
        await MainActor.run {
            self.refreshWishlist()
        }
    }
    
    var preferences: [String] {
        return []
    }
    
    // purchases is now stored and updated dynamically in the purchases array property
    
    var wishlist: [GroupedWishlistItem] {
        var groups: [String: [ClientWishlistItem]] = [:]
        var uniqueKeys: [String] = []
        
        for item in wishlistItems {
            let key = "\(item.brand.lowercased())-\(item.name.lowercased())"
            if groups[key] == nil {
                groups[key] = []
                uniqueKeys.append(key)
            }
            groups[key]?.append(item)
        }
        
        return uniqueKeys.compactMap { key in
            guard let items = groups[key], let first = items.first else { return nil }
            return GroupedWishlistItem(
                id: first.id,
                brand: first.brand,
                name: first.name,
                price: first.price,
                quantity: items.count,
                originalItems: items
            )
        }
    }
    
    func refreshNotes() {
        self.notes = NotesService.shared.fetchNotes(clientId: client.id)
        Task {
            await NotesService.shared.syncNotes(clientId: client.id)
            let updated = NotesService.shared.fetchNotes(clientId: client.id)
            await MainActor.run {
                self.notes = updated
            }
        }
    }
    
    func addNote(text: String) async {
        await NotesService.shared.addNote(clientId: client.id, noteText: text)
        await MainActor.run {
            self.refreshNotes()
        }
    }
    
    func deleteNote(noteId: UUID) async {
        await NotesService.shared.deleteNote(clientId: client.id, noteId: noteId)
        await MainActor.run {
            self.refreshNotes()
        }
    }
    
    func updateNote(noteId: UUID, text: String) async {
        await NotesService.shared.updateNote(clientId: client.id, noteId: noteId, noteText: text)
        await MainActor.run {
            self.refreshNotes()
        }
    }
    
    var tickets: [ClientTicket] {
        var generatedTickets: [ClientTicket] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        
        // Map purchases
        for purchase in purchases {
            generatedTickets.append(ClientTicket(title: "Purchase - \(purchase.name)", status: "Completed", date: purchase.date, isActive: false))
        }
        
        // Map appointments
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        for appt in appointments {
            let apptDate = isoFormatter.date(from: appt.formattedDate) ?? Date()
            let dateStr = formatter.string(from: apptDate)
            let isActive = appt.status != .completed && appt.status != .cancelled
            generatedTickets.append(ClientTicket(title: "Appointment - \(appt.displayAppointmentType)", status: appt.status.displayStatus, date: dateStr, isActive: isActive))
        }
        
        return generatedTickets
    }
    
    // MARK: - Remote Consultation
    var isGeneratingMeetLink = false
    var generatedMeetUrl: URL? = nil
    var meetLinkAlertMessage: String? = nil
    
    func startRemoteConsultation(salesAssociateName: String) async {
        await MainActor.run { 
            isGeneratingMeetLink = true 
            meetLinkAlertMessage = nil
        }
        

        struct Params: Encodable {
            let clientEmail: String
            let salesAssociateName: String
            let meetLink: String
        }
        
        do {
            let roomName = "RSMS-Consultation-\(UUID().uuidString.prefix(8))"
            let roomUrl = "https://meet.element.io/\(roomName)#config.prejoinPageEnabled=false&config.disableDeepLinking=true"
            
            let params = Params(clientEmail: client.email ?? "", salesAssociateName: salesAssociateName, meetLink: roomUrl)
            struct ResponseData: Decodable { let success: Bool? }
            _ = try await SupabaseManager.shared.client.functions.invoke(
                "create-remote-consultation",
                options: FunctionInvokeOptions(body: params)
            )
            
            await MainActor.run {
                isGeneratingMeetLink = false
                if let url = URL(string: roomUrl) {
                    self.generatedMeetUrl = url
                } else {
                    meetLinkAlertMessage = "Invalid URL generated"
                }
            }
        } catch {
            await MainActor.run {
                isGeneratingMeetLink = false
                meetLinkAlertMessage = error.localizedDescription
            }
        }
    }
}

struct GroupedWishlistItem: Identifiable, Hashable {
    let id: UUID
    let brand: String
    let name: String
    let price: Double
    let quantity: Int
    let originalItems: [ClientWishlistItem]
    
    var productImages: [String]? {
        return originalItems.first?.productImages
    }
}
