//
//  ActiveAuditViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation
import Supabase
import UIKit

@Observable
final class ActiveAuditViewModel {
    let audit: RSMSCycleCount
    
    var yetToScanItems: [YetToScanItem] = []
    var scannedUnitIds: [UUID] = []
    var scannedItems: [ScannedAuditItem] = []
    var newlyAddedItems: [ScannedAuditItem] = []
    var unexpectedScannedItems: [UnexpectedScannedItem] = []
    var totalExpected: Int = 0
    var totalScanned: Int = 0
    var isLoading = false
    var errorMessage: String?
    
    var progress: Double {
        guard totalExpected > 0 else { return 0 }
        return Double(totalScanned) / Double(totalExpected)
    }
    
    @ObservationIgnored var fetchProfileHandler: () async throws -> (UserRole, Any)?
    @ObservationIgnored var fetchBoutiquesHandler: () async throws -> [CorporateBoutique]
    
    init(audit: RSMSCycleCount) {
        self.audit = audit
        self.fetchProfileHandler = {
            try await ProfileService().fetchCurrentProfile()
        }
        self.fetchBoutiquesHandler = {
            try await SupabaseManager.shared.client.from("boutiques").select().execute().value
        }
    }
    
    func startSession() async {
        if let cached = AuditPersistence.shared.loadSession(id: audit.id) {
            let profileTuple = try? await fetchProfileHandler()
            let staff = profileTuple?.1 as? StaffModel
            let storeId = staff?.boutiqueId ?? UUID()
            
            var allExpectedItems: [YetToScanItem] = []
            do {
                var allResponses: [YetToScanNetworkResponse] = []
                var offset = 0
                let chunkSize = 1000
                var hasMore = true
                
                while hasMore {
                    let response: [YetToScanNetworkResponse] = try await SupabaseManager.shared.client
                        .from("inventory_units")
                        .select("id, serial_number, catalog_id, catalogs(id, name, brand, catalog_id)")
                        .eq("boutique_id", value: storeId.uuidString)
                        .eq("status", value: "Available")
                        .range(from: offset, to: offset + chunkSize - 1)
                        .execute()
                        .value
                    
                    allResponses.append(contentsOf: response)
                    
                    if response.count < chunkSize {
                        hasMore = false
                    } else {
                        offset += chunkSize
                    }
                }
                
                allExpectedItems = allResponses.map { res in
                    YetToScanItem(
                        id: res.id,
                        serialNumber: res.serial_number,
                        catalogId: res.catalog_id,
                        name: res.catalogs?.name ?? "Unknown",
                        brand: res.catalogs?.brand ?? "Unknown"
                    )
                }
            } catch {
                print("Failed to fetch expected items for session restore: \(error)")
            }
            
            var rebuiltScannedItems: [ScannedAuditItem] = []
            for unitId in cached.scannedUnitIds {
                if let matched = allExpectedItems.first(where: { $0.id == unitId }) {
                    rebuiltScannedItems.append(ScannedAuditItem(name: matched.serialNumber, ok: true))
                } else {
                    rebuiltScannedItems.append(ScannedAuditItem(name: unitId.uuidString, ok: true))
                }
            }
            
            let unexpectedItems = cached.unexpectedScannedItems ?? []
            var rebuiltNewlyAddedItems: [ScannedAuditItem] = []
            for item in unexpectedItems {
                var resolvedName = item.barcode
                if let catalogResponse: [CatalogEntity] = try? await SupabaseManager.shared.client
                    .from("catalogs")
                    .select()
                    .eq("bar_code", value: item.barcode)
                    .execute()
                    .value, let catalog = catalogResponse.first {
                    resolvedName = catalog.name
                }
                rebuiltNewlyAddedItems.append(ScannedAuditItem(name: resolvedName, ok: false))
            }
            
            await MainActor.run {
                self.yetToScanItems = cached.yetToScanItems
                self.scannedUnitIds = cached.scannedUnitIds
                self.totalExpected = cached.yetToScanItems.count + cached.scannedUnitIds.count
                self.unexpectedScannedItems = unexpectedItems
                self.totalScanned = cached.scannedUnitIds.count + unexpectedItems.count
                self.scannedItems = rebuiltScannedItems
                self.newlyAddedItems = rebuiltNewlyAddedItems
            }
            return
        }
        
        await loadExpectedItems()
    }
    
    func loadExpectedItems() async {
        isLoading = true
        errorMessage = nil
        
        await MainActor.run {
            self.yetToScanItems.removeAll()
            self.scannedUnitIds.removeAll()
            self.scannedItems.removeAll()
            self.newlyAddedItems.removeAll()
            self.unexpectedScannedItems.removeAll()
        }
        
        do {
            let profileTuple = try? await fetchProfileHandler()
            let staff = profileTuple?.1 as? StaffModel
            let storeId = staff?.boutiqueId ?? UUID()
            
            var allResponses: [YetToScanNetworkResponse] = []
            var offset = 0
            let chunkSize = 1000
            var hasMore = true
            
            while hasMore {
                let response: [YetToScanNetworkResponse] = try await SupabaseManager.shared.client
                    .from("inventory_units")
                    .select("id, serial_number, catalog_id, catalogs(name, brand)")
                    .eq("boutique_id", value: storeId.uuidString)
                    .eq("status", value: "Available")
                    .range(from: offset, to: offset + chunkSize - 1)
                    .execute()
                    .value
                
                allResponses.append(contentsOf: response)
                
                if response.count < chunkSize {
                    hasMore = false
                } else {
                    offset += chunkSize
                }
            }
            
            let items: [YetToScanItem] = allResponses.map { res in
                YetToScanItem(
                    id: res.id,
                    serialNumber: res.serial_number,
                    catalogId: res.catalog_id,
                    name: res.catalogs?.name ?? "Unknown",
                    brand: res.catalogs?.brand ?? "Unknown"
                )
            }
            
            await MainActor.run {
                AuditPersistence.shared.clearSession(id: self.audit.id)
                self.yetToScanItems = items
                self.totalExpected = items.count
                self.totalScanned = 0
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func scanItem(barcode: String) async -> Result<Void, Error> {
        let cleanedToken = barcode.components(separatedBy: .whitespacesAndNewlines).joined().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if scannedItems.contains(where: { $0.name.components(separatedBy: .whitespacesAndNewlines).joined().localizedCaseInsensitiveCompare(cleanedToken) == .orderedSame }) ||
           unexpectedScannedItems.contains(where: { $0.barcode.components(separatedBy: .whitespacesAndNewlines).joined().localizedCaseInsensitiveCompare(cleanedToken) == .orderedSame }) {
            return .success(())
        }
        
        guard let index = yetToScanItems.firstIndex(where: { $0.serialNumber.components(separatedBy: .whitespacesAndNewlines).joined().localizedCaseInsensitiveCompare(cleanedToken) == .orderedSame }) else {
            do {
                let catalogsResponse: [CatalogEntity] = try await SupabaseManager.shared.client
                    .from("catalogs")
                    .select()
                    .eq("bar_code", value: cleanedToken)
                    .execute()
                    .value
                
                if let catalog = catalogsResponse.first {
                    let unexpectedItem = UnexpectedScannedItem(id: UUID(), barcode: cleanedToken, status: "new_item")
                    unexpectedScannedItems.append(unexpectedItem)
                    newlyAddedItems.insert(ScannedAuditItem(name: catalog.name, ok: false), at: 0)
                } else {
                    let unexpectedItem = UnexpectedScannedItem(id: UUID(), barcode: cleanedToken, status: "new_item")
                    unexpectedScannedItems.append(unexpectedItem)
                    newlyAddedItems.insert(ScannedAuditItem(name: cleanedToken, ok: false), at: 0)
                }
            } catch {
                let unexpectedItem = UnexpectedScannedItem(id: UUID(), barcode: cleanedToken, status: "new_item")
                unexpectedScannedItems.append(unexpectedItem)
                newlyAddedItems.insert(ScannedAuditItem(name: cleanedToken, ok: false), at: 0)
            }
            
            totalScanned += 1
            
            #if os(iOS)
            await MainActor.run {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
            }
            #endif
            
            saveSessionState()
            return .success(())
        }
        
        let matchedItem = yetToScanItems.remove(at: index)
        scannedUnitIds.append(matchedItem.id)
        totalScanned += 1
        
        scannedItems.insert(ScannedAuditItem(name: matchedItem.serialNumber, ok: true), at: 0)
        
        saveSessionState()
        return .success(())
    }
    
    func saveSessionState() {
        let session = AuditSession(
            id: audit.id,
            title: audit.title,
            date: audit.date,
            scope: audit.scope,
            status: "In Progress",
            badgeStatus: .warning,
            storeName: "Store",
            controllerName: "Controller",
            isSubmitted: false,
            yetToScanItems: yetToScanItems,
            scannedUnitIds: scannedUnitIds,
            varianceReport: nil,
            unexpectedScannedItems: unexpectedScannedItems
        )
        AuditPersistence.shared.saveSession(session)
        
        let currentTotalScanned = self.totalScanned
        let currentTotalExpected = self.totalExpected
        let auditId = self.audit.id
        
        Task {
            struct ProgressUpdate: Codable {
                let status: String
                let total_expected: Int
                let total_scanned: Int
            }
            let payload = ProgressUpdate(status: "in_progress", total_expected: currentTotalExpected, total_scanned: currentTotalScanned)
            do {
                try await SupabaseManager.shared.client.from("audits")
                    .update(payload)
                    .eq("id", value: auditId)
                    .execute()
            } catch {
                print("Failed to sync audit progress to DB: \(error)")
            }
        }
    }
    
    func submitCount() async -> Result<VarianceReport, Error> {
        do {
            isLoading = true
            
            let profileTuple = try? await fetchProfileHandler()
            let staff = profileTuple?.1 as? StaffModel
            let storeId = staff?.boutiqueId ?? UUID()
            let controllerName = staff?.name ?? "Controller"
            
            let boutiques = try? await fetchBoutiquesHandler()
            let storeName = boutiques?.first(where: { $0.id == storeId })?.name ?? "Boutique"
            
            var reportItems: [VarianceReportItem] = []
            var discrepancies: [DiscrepancyItem] = []
            
            for missing in yetToScanItems {
                discrepancies.append(
                    DiscrepancyItem(
                        name: missing.name,
                        detail: "Serial: \(missing.serialNumber)",
                        type: "missing"
                    )
                )
            }
            
            for unexpected in unexpectedScannedItems {
                var itemName = "Unexpected Scan"
                var itemDetail = "Barcode: \(unexpected.barcode)"
                
                do {
                    let catalogsResponse: [CatalogEntity] = try await SupabaseManager.shared.client
                        .from("catalogs")
                        .select()
                        .eq("bar_code", value: unexpected.barcode)
                        .execute()
                        .value
                    
                    if let catalog = catalogsResponse.first {
                        itemName = catalog.name
                        itemDetail = "Barcode: \(unexpected.barcode) (New SKU)"
                    }
                } catch {
                    print("Failed to resolve catalog for unexpected barcode \(unexpected.barcode): \(error)")
                }
                
                discrepancies.append(
                    DiscrepancyItem(
                        name: itemName,
                        detail: itemDetail,
                        type: "new"
                    )
                )
            }
            
            // Build real VarianceReportItems
            var allUnitsResponse: [YetToScanNetworkResponse] = []
            do {
                var offset = 0
                let chunkSize = 1000
                var hasMore = true
                
                while hasMore {
                    let response: [YetToScanNetworkResponse] = try await SupabaseManager.shared.client
                        .from("inventory_units")
                        .select("id, serial_number, catalog_id, catalogs(id, name, brand, catalog_id)")
                        .eq("boutique_id", value: storeId.uuidString)
                        .eq("status", value: "Available")
                        .range(from: offset, to: offset + chunkSize - 1)
                        .execute()
                        .value
                    
                    allUnitsResponse.append(contentsOf: response)
                    
                    if response.count < chunkSize {
                        hasMore = false
                    } else {
                        offset += chunkSize
                    }
                }
            } catch {
                print("Failed to fetch all inventory units for variance report: \(error)")
            }
            
            struct CatalogSummary {
                let id: UUID
                let name: String
                let sku: String
                var expectedQty: Int = 0
                var countedQty: Int = 0
            }
            
            var summaries: [UUID: CatalogSummary] = [:]
            
            for res in allUnitsResponse {
                guard let catId = res.catalog_id, let catInfo = res.catalogs else { continue }
                let sku = catInfo.catalog_id ?? "Unknown SKU"
                
                if summaries[catId] == nil {
                    summaries[catId] = CatalogSummary(id: catId, name: catInfo.name, sku: sku)
                }
                
                summaries[catId]?.expectedQty += 1
                if scannedUnitIds.contains(res.id) {
                    summaries[catId]?.countedQty += 1
                }
            }
            
            for unexpected in unexpectedScannedItems {
                do {
                    let catalogsResponse: [CatalogEntity] = try await SupabaseManager.shared.client
                        .from("catalogs")
                        .select()
                        .eq("bar_code", value: unexpected.barcode)
                        .execute()
                        .value
                    
                    if let catalog = catalogsResponse.first {
                        let catId = catalog.id
                        if summaries[catId] == nil {
                            summaries[catId] = CatalogSummary(id: catId, name: catalog.name, sku: catalog.catalogId)
                        }
                        summaries[catId]?.countedQty += 1
                    } else {
                        let dummyId = UUID()
                        summaries[dummyId] = CatalogSummary(id: dummyId, name: "Unexpected: \(unexpected.barcode)", sku: unexpected.barcode, expectedQty: 0, countedQty: 1)
                    }
                } catch {
                    print("Failed to fetch catalog details for barcode: \(unexpected.barcode)")
                }
            }
            
            for (_, summary) in summaries {
                let varQty = summary.countedQty - summary.expectedQty
                reportItems.append(
                    VarianceReportItem(
                        id: UUID(),
                        productName: summary.name,
                        sku: summary.sku,
                        expectedQty: summary.expectedQty,
                        countedQty: summary.countedQty,
                        variance: varQty,
                        isArchivedProduct: false
                    )
                )
            }
            
            let report = VarianceReport(
                id: UUID(),
                boutiqueName: storeName,
                date: Date(),
                controllerName: controllerName,
                items: reportItems
            )
            
            struct SubmitAuditPayload: Codable {
                let status: String
                let total_expected: Int
                let total_scanned: Int
                let variance: Int
                let accuracy: Double
                let discrepancies: [DiscrepancyItem]
                let scanned_unit_ids: [UUID]
            }
            
            let variance = yetToScanItems.count + unexpectedScannedItems.count
            let payload = SubmitAuditPayload(
                status: "due",
                total_expected: totalExpected,
                total_scanned: totalScanned,
                variance: variance,
                accuracy: totalExpected > 0 ? (max(0.0, Double(totalExpected - variance) / Double(totalExpected)) * 100.0) : 100.0,
                discrepancies: discrepancies,
                scanned_unit_ids: scannedUnitIds
            )
            
            try await SupabaseManager.shared.client.from("audits")
                .update(payload)
                .eq("id", value: audit.id.uuidString)
                .execute()
            
            let session = AuditSession(
                id: audit.id,
                title: audit.title,
                date: audit.date,
                scope: audit.scope,
                status: "Submitted",
                badgeStatus: .success,
                storeName: storeName,
                controllerName: controllerName,
                isSubmitted: true,
                yetToScanItems: yetToScanItems,
                scannedUnitIds: scannedUnitIds,
                varianceReport: report,
                unexpectedScannedItems: unexpectedScannedItems
            )
            
            AuditPersistence.shared.saveSession(session)
            
            await MainActor.run {
                self.isLoading = false
            }
            return .success(report)
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return .failure(error)
        }
    }

    var missingItems: [String] {
        return yetToScanItems.map { $0.serialNumber }
    }
    
    func addScannedItems(barcodes: [String]) async {
        for barcode in barcodes {
            let _ = await scanItem(barcode: barcode)
        }
    }
}
