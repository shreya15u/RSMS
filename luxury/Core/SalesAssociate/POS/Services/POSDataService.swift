import Foundation
import Supabase

final class POSDataService {
    static let shared = POSDataService()
    
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    private var posDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            
            if let dateString = try? container.decode(String.self) {
                let formatters = [
                    "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ",
                    "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
                    "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
                    "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
                    "yyyy-MM-dd HH:mm:ss",
                    "yyyy-MM-dd"
                ]
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                for format in formatters {
                    formatter.dateFormat = format
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
                if let date = ISO8601DateFormatter().date(from: dateString) {
                    return date
                }
            } else if let doubleValue = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: doubleValue)
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date"
            )
        }
        return decoder
    }
    
    func fetchCatalogs() async throws -> [CatalogItem] {
        let response = try await client
            .from("catalogs")
            .select()
            .execute()
        return try posDecoder.decode([CatalogItem].self, from: response.data)
    }
    
    func fetchActiveCampaigns() async throws -> [PricingCampaign] {
        let response = try await client
            .from("campaigns")
            .select()
            .eq("status", value: "Active")
            .execute()
        return try posDecoder.decode([PricingCampaign].self, from: response.data)
    }
    
    private struct IDResponse: Codable {
        let id: UUID
    }
    
    func createCart(clientId: UUID?, boutiqueId: UUID, total: Double, productIds: [UUID]) async throws -> Cart {
        let payload: [String: AnyJSON] = [
            "client_id": clientId.map { .string($0.uuidString) } ?? .null,
            "boutique_id": .string(boutiqueId.uuidString),
            "status": .string("active"),
            "total_price": .double(total),
            "product_ids": .array(productIds.map { .string($0.uuidString) })
        ]
        
        let response = try await client
            .from("cart")
            .insert(payload)
            .select("id")
            .execute()
        
        let idResponses = try JSONDecoder().decode([IDResponse].self, from: response.data)
        guard let first = idResponses.first else {
            throw NSError(domain: "POS", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create cart"])
        }
        
        return Cart(
            id: first.id,
            clientId: clientId,
            boutiqueId: boutiqueId,
            status: "active",
            totalPrice: total,
            productIds: productIds
        )
    }
    
    func createTransaction(amount: Double, purpose: String, clientId: UUID?, boutiqueId: UUID, staffId: UUID, paymentGatewayId: String?, isGift: Bool? = nil, isTax: Bool? = nil) async throws -> Transaction {
        var payload: [String: AnyJSON] = [
            "transaction_amount": .double(amount),
            "purpose": .string(purpose),
            "date_of_transaction": .string(ISO8601DateFormatter().string(from: Date())),
            "client_id": clientId.map { .string($0.uuidString) } ?? .null,
            "boutique_id": .string(boutiqueId.uuidString),
            "staff_id": .string(staffId.uuidString)
        ]
        if let pgId = paymentGatewayId {
            payload["payment_gateway_id"] = .string(pgId)
        }
        if let isGift = isGift {
            payload["is_gift"] = .bool(isGift)
        }
        if let isTax = isTax {
            payload["is_tax"] = .bool(isTax)
        }
        
        let response = try await client
            .from("transaction")
            .insert(payload)
            .select("id")
            .execute()
            
        let idResponses = try JSONDecoder().decode([IDResponse].self, from: response.data)
        guard let first = idResponses.first else {
            throw NSError(domain: "POS", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create transaction"])
        }
        
        return Transaction(
            id: first.id,
            transactionAmount: amount,
            dateOfTransaction: Date(),
            purpose: TransactionPurpose(rawValue: purpose) ?? .purchase,
            paymentGatewayId: paymentGatewayId,
            isGift: isGift,
            isTax: isTax
        )
    }
    
    func checkout(cartId: UUID, transactionId: UUID, staffId: UUID, boutiqueId: UUID, total: Double, productIds: [UUID], clientId: UUID?) async throws {
        // 1. Create Order
        let orderPayload: [String: AnyJSON] = [
            "cart_id": .string(cartId.uuidString),
            "transaction_id": .string(transactionId.uuidString),
            "rsms_user_id": .string(staffId.uuidString),
            "total_price": .double(total)
        ]
        
        try await client
            .from("order")
            .insert(orderPayload)
            .execute()
        
        // 2. Create Purchased Items & Update Inventory Status
        var itemsPayload: [[String: AnyJSON]] = []
        for catalogId in productIds {
            // Find an available physical unit to mark as sold
            let response = try? await client
                .from("inventory_units")
                .select("id")
                .eq("catalog_id", value: catalogId.uuidString)
                .eq("boutique_id", value: boutiqueId.uuidString)
                .eq("status", value: "Available")
                .limit(1)
                .execute()
                
            struct UnitID: Codable { let id: UUID }
            
            if let data = response?.data,
               let units = try? JSONDecoder().decode([UnitID].self, from: data),
               let unit = units.first {
                
                // Mark this specific physical item as Reserved for the IC to pick
                _ = try? await client
                    .from("inventory_units")
                    .update(["status": "Reserved"])
                    .eq("id", value: unit.id.uuidString)
                    .execute()
            }
            
            var piPayload: [String: AnyJSON] = [
                "product_id": .string(catalogId.uuidString),
                "transaction_id": .string(transactionId.uuidString),
                "boutique_id": .string(boutiqueId.uuidString),
                "staff_id": .string(staffId.uuidString),
                "status": .string("Pending") // Changed back to Pending so IC receives it
            ]
            
            if let uid = clientId {
                piPayload["uid"] = .string(uid.uuidString)
                piPayload["client_id"] = .string(uid.uuidString)
            }
            itemsPayload.append(piPayload)
        }
        
        if !itemsPayload.isEmpty {
            try await client
                .from("purchased_items")
                .insert(itemsPayload)
                .execute()
        }
        
        // 3. Update Client's products_purchased
        if let uid = clientId {
            struct ClientProducts: Codable {
                let products_purchased: [UUID]?
            }
            
            // Fetch current client (only products_purchased to avoid strict decoding failures on dob etc.)
            let response = try await client
                .from("client")
                .select("products_purchased")
                .eq("id", value: uid.uuidString)
                .execute()
            
            let clients = try JSONDecoder().decode([ClientProducts].self, from: response.data)
            
            if let currentClient = clients.first {
                var currentPurchased = currentClient.products_purchased ?? []
                currentPurchased.append(contentsOf: productIds)
                
                let updatePayload: [String: AnyJSON] = [
                    "products_purchased": .array(currentPurchased.map { .string($0.uuidString) })
                ]
                try await client
                    .from("client")
                    .update(updatePayload)
                    .eq("id", value: uid.uuidString)
                    .execute()
            }
        }
        
        // 4. Update cart status to 'completed'
        try await client
            .from("cart")
            .update(["status": "completed"])
            .eq("id", value: cartId.uuidString)
            .execute()
    }
}
