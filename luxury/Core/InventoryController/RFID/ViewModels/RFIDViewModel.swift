//
//  RFIDViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation
import Supabase

@Observable
final class RFIDViewModel {
    var recentSessions: [ScanSession] = []
    var catalogs: [CatalogEntity] = []
    var isLoading = false
    var errorMessage: String?

    private let damagedItemService = DamagedItemService()

    func fetchCatalogs() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetched: [CatalogEntity] = try await SupabaseManager.shared.client
                    .from("catalogs")
                    .select()
                    .execute()
                    .value

                await MainActor.run {
                    self.catalogs = fetched
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to load products: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }

    func saveDeliveryItems(
        to catalog: CatalogEntity,
        acceptedSerials: [String],
        damagedItems: [DamagedDeliveryItemDraft],
        completion: @escaping () -> Void
    ) {
        Task {
            do {
                var updatedCatalog = catalog

                if !acceptedSerials.isEmpty {
                    var boutiqueId: UUID? = nil
                    if let profileTuple = try? await ProfileService().fetchCurrentProfile(),
                       let staff = profileTuple.1 as? StaffModel {
                        boutiqueId = staff.boutiqueId
                    }
                    
                    if let storeId = boutiqueId {
                        let newUnits = acceptedSerials.map { serial in
                            InventoryUnitEntity(
                                id: UUID(),
                                catalogId: catalog.id,
                                boutiqueId: storeId,
                                serialNumber: serial,
                                status: .available,
                                createdAt: Date(),
                                updatedAt: Date()
                            )
                        }
                        try await InventoryService.shared.createInventoryUnits(newUnits)
                    }
                }

                for damagedItem in damagedItems {
                    try await damagedItemService.reportDamagedArrival(for: catalog, draft: damagedItem)
                }

                await MainActor.run {
                    if let index = self.catalogs.firstIndex(where: { $0.id == catalog.id }) {
                        self.catalogs[index] = updatedCatalog
                    }

                    let totalScanned = acceptedSerials.count + damagedItems.count
                    let newSession = ScanSession(
                        date: "Just Now",
                        zone: "Addition: \(catalog.name)",
                        scannedCount: totalScanned,
                        expectedCount: totalScanned,
                        variance: 0
                    )
                    self.recentSessions.insert(newSession, at: 0)
                    completion()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to complete delivery intake: \(error.localizedDescription)")
                }
            }
        }
    }
}
