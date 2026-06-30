import Foundation
import Supabase

final class ASTService {
    static let shared = ASTService()
    
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    func fetchPurchasedItems(for clientId: UUID) async throws -> [PurchasedItem] {
        return try await client
            .from("purchased_items")
            .select()
            .eq("uid", value: clientId.uuidString)
            .execute()
            .value
    }
    
    func createAST(id: UUID, productId: UUID, clientId: UUID?, boutiqueId: UUID, warrantyStatus: String, description: String, remark: String, photoUrls: [String], createdBy: String? = nil) async throws -> AST {
        var payload: [String: AnyJSON] = [
            "id": .string(id.uuidString),
            "product_id": .string(productId.uuidString),
            "client_id": clientId.map { .string($0.uuidString) } ?? .null,
            "boutique_id": .string(boutiqueId.uuidString),
            "status": .string("open"),
            "warranty_status": .string(warrantyStatus),
            "description": .string(description),
            "remark": .string(remark)
        ]
        
        var metadataObj: [String: AnyJSON] = [:]
        
        if !photoUrls.isEmpty {
            metadataObj["photos"] = .array(photoUrls.map { .string($0) })
        }
        
        if let createdBy = createdBy {
            metadataObj["created_by"] = .string(createdBy)
        }
        
        if !metadataObj.isEmpty {
            payload["metadata"] = .object(metadataObj)
        }
        
        let ast: [AST] = try await client
            .from("ast")
            .insert(payload)
            .select()
            .execute()
            .value
        
        guard let first = ast.first else {
            throw NSError(domain: "AST", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create AST"])
        }
        return first
    }

    func fetchASTs(forBoutique boutiqueId: UUID) async throws -> [AST] {
        return try await client
            .from("ast")
            .select()
            .eq("boutique_id", value: boutiqueId.uuidString)
            .execute()
            .value
    }

    struct UpdateStatusPayload: Encodable {
        let status: String
    }

    func updateASTStatus(astId: UUID, newStatus: String) async throws {
        let payload = UpdateStatusPayload(status: newStatus)
        try await client
            .from("ast")
            .update(payload)
            .eq("id", value: astId.uuidString)
            .select()
            .single()
            .execute()
    }
}
