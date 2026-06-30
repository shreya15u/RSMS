//
//  StockTransferService.swift
//  luxury
//
//  Created by Codex on 04/06/26.
//

import Foundation
import Supabase

final class StockTransferService {
    static let shared = StockTransferService()
    
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    func fetchTransfers(for boutiqueId: UUID? = nil) async throws -> [TransferRequest] {
        let rows: [StockTransferEntity] = try await client
            .from("stock_transfers")
            .select()
            .execute()
            .value
        
        return rows
            .filter { transfer in
                guard let boutiqueId else { return true }
                return transfer.sourceBoutiqueId == boutiqueId || transfer.destinationBoutiqueId == boutiqueId
            }
            .sorted {
                ($0.sortDate ?? .distantPast) > ($1.sortDate ?? .distantPast)
            }
            .map(\.transferRequest)
    }
    
    func fetchPendingCount(for boutiqueId: UUID? = nil) async throws -> Int {
        let rows: [StockTransferEntity] = try await client
            .from("stock_transfers")
            .select()
            .execute()
            .value
        
        return rows.filter { transfer in
            if let boutiqueId, transfer.sourceBoutiqueId != boutiqueId && transfer.destinationBoutiqueId != boutiqueId {
                return false
            }
            let status = transfer.status.lowercased()
            return status == "submitted" || status == "pending approval"
        }.count
    }
    
    func createTransfer(
        reference: String,
        sourceBoutiqueId: UUID,
        destinationBoutiqueId: UUID,
        source: String,
        destination: String,
        items: [TransferItem]
    ) async throws -> TransferRequest {
        let now = ISO8601DateFormatter().string(from: Date())
        let entity = StockTransferEntity(
            id: UUID(),
            reference: reference,
            sourceBoutiqueId: sourceBoutiqueId,
            destinationBoutiqueId: destinationBoutiqueId,
            source: source,
            destination: destination,
            items: items,
            status: "Submitted",
            badgeStatus: .neutral,
            createdAt: now,
            updatedAt: now,
            createdBy: nil,
            approvedBy: nil,
            rejectedBy: nil,
            shippedAt: nil,
            receivedAt: nil
        )
        
        try await client
            .from("stock_transfers")
            .insert(entity)
            .execute()
        
        return entity.transferRequest
    }
    
    func updateTransfer(
        id: UUID,
        status: String,
        badgeStatus: BadgeStatus,
        approvedBy: UUID? = nil,
        rejectedBy: UUID? = nil,
        shippedAt: Date? = nil,
        receivedAt: Date? = nil
    ) async throws -> TransferRequest {
        let payload = StockTransferUpdatePayload(
            status: status,
            badgeStatus: badgeStatus,
            updatedAt: Date(),
            approvedBy: approvedBy,
            rejectedBy: rejectedBy,
            shippedAt: shippedAt,
            receivedAt: receivedAt
        )
        
        try await client
            .from("stock_transfers")
            .update(payload)
            .eq("id", value: id.uuidString)
            .execute()
        
        return try await fetchTransfer(id: id)
    }
    
    func fetchTransfer(id: UUID) async throws -> TransferRequest {
        let entity: StockTransferEntity = try await client
            .from("stock_transfers")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        return entity.transferRequest
    }
}

    private struct StockTransferEntity: Codable, Identifiable, Hashable {
        let id: UUID
        let reference: String
        let sourceBoutiqueId: UUID
        let destinationBoutiqueId: UUID
        let source: String
        let destination: String
        let items: [TransferItem]
        let status: String
        let badgeStatus: BadgeStatus
        let createdAt: String?
        let updatedAt: String?
        let createdBy: UUID?
        let approvedBy: UUID?
        let rejectedBy: UUID?
        let shippedAt: String?
        let receivedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, reference, source, destination, items, status
        case sourceBoutiqueId = "source_boutique_id"
        case destinationBoutiqueId = "destination_boutique_id"
        case badgeStatus = "badge_status"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case createdBy = "created_by"
        case approvedBy = "approved_by"
        case rejectedBy = "rejected_by"
        case shippedAt = "shipped_at"
        case receivedAt = "received_at"
    }
    
        var transferRequest: TransferRequest {
            TransferRequest(
                id: id,
                reference: reference,
                source: source,
            destination: destination,
            items: items,
            status: status,
                badgeStatus: badgeStatus
            )
        }
        
        var sortDate: Date? {
            date(from: updatedAt) ?? date(from: createdAt)
        }
        
        private func date(from value: String?) -> Date? {
            guard let value else { return nil }
            if let parsed = ISO8601DateFormatter().date(from: value) {
                return parsed
            }
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter.date(from: value)
        }
    }

private struct StockTransferUpdatePayload: Encodable {
    let status: String
    let badgeStatus: BadgeStatus
    let updatedAt: Date
    let approvedBy: UUID?
    let rejectedBy: UUID?
    let shippedAt: Date?
    let receivedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case status
        case badgeStatus = "badge_status"
        case updatedAt = "updated_at"
        case approvedBy = "approved_by"
        case rejectedBy = "rejected_by"
        case shippedAt = "shipped_at"
        case receivedAt = "received_at"
    }
}
