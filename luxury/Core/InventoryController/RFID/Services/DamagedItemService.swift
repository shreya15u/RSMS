//
//  DamagedItemService.swift
//  luxury
//
//  Created by Codex on 26/05/26.
//

import Foundation
import Supabase

final class DamagedItemService {
    private let client = SupabaseManager.shared.client
    private let authService = AuthService()
    private let profileService = ProfileService()
    private let storageService = StorageService()

    func reportDamagedArrival(for catalog: CatalogEntity, draft: DamagedDeliveryItemDraft) async throws {
        let session = await authService.getCurrentSession()
        guard let userId = session?.user.id else {
            throw NSError(domain: "DamagedItemService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to identify the signed in inventory controller."])
        }

        guard let (_, profile) = try await profileService.fetchCurrentProfile(preferredRole: .inventoryController),
              let staff = profile as? StaffModel,
              let boutiqueId = staff.boutiqueId else {
            throw NSError(domain: "DamagedItemService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to resolve the boutique for this delivery scan."])
        }

        let photoURL = try await storageService.uploadDamagePhoto(image: draft.photo, productId: catalog.id, serial: draft.serial)
        let record = ASTInsert(
            productId: catalog.id,
            clientId: nil,
            boutiqueId: boutiqueId,
            status: "damaged_on_arrival",
            warrantyStatus: nil,
            description: draft.description,
            remark: "Supplier notification queued from delivery scan.",
            metadata: DamagedASTMetadata(
                serialNumber: draft.serial,
                photoURL: photoURL,
                source: "delivery_scan",
                reportedBy: userId,
                reportedAt: Date(),
                supplierNotificationStatus: "queued"
            )
        )

        try await client.from("ast")
            .insert(record)
            .execute()

        SystemLogService.shared.logAction(
            category: .inventory,
            severity: .warning,
            message: "Damaged on arrival recorded for \(catalog.name) [\(draft.serial)]"
        )
    }
}

private struct ASTInsert: Encodable {
    let productId: UUID
    let clientId: UUID?
    let boutiqueId: UUID
    let status: String
    let warrantyStatus: String?
    let description: String
    let remark: String?
    let metadata: DamagedASTMetadata

    enum CodingKeys: String, CodingKey {
        case status, description, remark, metadata
        case productId = "product_id"
        case clientId = "client_id"
        case boutiqueId = "boutique_id"
        case warrantyStatus = "warranty_status"
    }
}

private struct DamagedASTMetadata: Encodable {
    let serialNumber: String
    let photoURL: String
    let source: String
    let reportedBy: UUID
    let reportedAt: Date
    let supplierNotificationStatus: String

    enum CodingKeys: String, CodingKey {
        case source
        case serialNumber = "serial_number"
        case photoURL = "photo_url"
        case reportedBy = "reported_by"
        case reportedAt = "reported_at"
        case supplierNotificationStatus = "supplier_notification_status"
    }
}
