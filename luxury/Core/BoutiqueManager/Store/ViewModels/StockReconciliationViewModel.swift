//
//  StockReconciliationViewModel.swift
//  luxury
//
//  Created by Codex on 27/05/26.
//

import Foundation
import Observation

@Observable
final class StockReconciliationViewModel {
    var isLoading = false
    var isSaving = false
    var errorMessage: String?
    var successMessage: String?
    var manualSKU = ""
    var currentCatalog: CatalogEntity?
    var currentInventory: InventoryItem?
    var expectedQuantity = 0
    var scannedQuantity = 0
    var editorName = ""
    var boutiqueName = ""
    var canSubmitCorrection = false

    private let service = StockReconciliationService()
    private var context: StockReconciliationContext?

    var hasLoadedItem: Bool {
        currentCatalog != nil
    }

    var hasMismatch: Bool {
        hasLoadedItem && expectedQuantity != scannedQuantity
    }

    func loadContext() {
        guard context == nil else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let context = try await service.fetchManagerContext()
                await MainActor.run {
                    self.context = context
                    self.editorName = context.editorName
                    self.boutiqueName = context.boutiqueName
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func handleScannedCode(_ code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let currentCatalog,
           currentCatalog.barCode.caseInsensitiveCompare(trimmed) == .orderedSame || currentCatalog.catalogId.caseInsensitiveCompare(trimmed) == .orderedSame {
            scannedQuantity += 1
            successMessage = nil
            errorMessage = nil
            refreshSubmitState()
            return
        }

        lookupItem(using: trimmed, initialScannedQuantity: 1)
    }

    func submitManualLookup() {
        let trimmed = manualSKU.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = String(localized: "Enter the SKU manually to continue.")
            return
        }

        lookupItem(using: trimmed, initialScannedQuantity: scannedQuantity > 0 && matchesCurrentCatalog(trimmed) ? scannedQuantity + 1 : 1)
    }

    func incrementScannedQuantity() {
        scannedQuantity += 1
        refreshSubmitState()
    }

    func decrementScannedQuantity() {
        if scannedQuantity > 0 {
            scannedQuantity -= 1
        }
        refreshSubmitState()
    }

    func applyCorrection() {
        guard let context, let currentCatalog else { return }

        isSaving = true
        errorMessage = nil
        successMessage = nil

        let previousExpected = expectedQuantity
        let appliedQuantity = scannedQuantity

        Task {
            do {
                try await service.applyCorrection(
                    inventory: currentInventory,
                    skuId: currentCatalog.id,
                    storeId: context.boutiqueId,
                    scannedQuantity: appliedQuantity
                )

                let timestamp = Self.auditTimestampFormatter.string(from: Date())
                SystemLogService.shared.logAction(
                    category: .inventory,
                    severity: .info,
                    message: "Inventory corrected by \(context.editorName) at \(timestamp) for \(currentCatalog.catalogId): \(previousExpected) to \(appliedQuantity)",
                    boutiqueName: context.boutiqueName
                )

                await MainActor.run {
                    if let currentInventory {
                        self.currentInventory = InventoryItem(
                            id: currentInventory.id,
                            storeId: currentInventory.storeId,
                            skuId: currentInventory.skuId,
                            quantity: appliedQuantity,
                            productAvailable: appliedQuantity > 0
                        )
                    } else {
                        self.currentInventory = InventoryItem(
                            id: UUID(),
                            storeId: context.boutiqueId,
                            skuId: currentCatalog.id,
                            quantity: appliedQuantity,
                            productAvailable: appliedQuantity > 0
                        )
                    }
                    self.expectedQuantity = appliedQuantity
                    self.isSaving = false
                    self.successMessage = String(localized: "Inventory updated by \(context.editorName) at \(timestamp).")
                    self.refreshSubmitState()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isSaving = false
                }
            }
        }
    }

    private func lookupItem(using code: String, initialScannedQuantity: Int) {
        guard let context else {
            loadContext()
            errorMessage = String(localized: "Loading boutique context. Try the scan again.")
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                let catalog = try await service.lookupCatalog(by: code)
                let inventory = try await service.fetchInventory(for: catalog.id, storeId: context.boutiqueId)

                await MainActor.run {
                    self.currentCatalog = catalog
                    self.currentInventory = inventory
                    self.expectedQuantity = inventory?.quantity ?? 0
                    self.scannedQuantity = initialScannedQuantity
                    self.manualSKU = catalog.catalogId
                    self.isLoading = false
                    self.refreshSubmitState()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    self.refreshSubmitState()
                }
            }
        }
    }

    private func matchesCurrentCatalog(_ code: String) -> Bool {
        guard let currentCatalog else { return false }
        return currentCatalog.barCode.caseInsensitiveCompare(code) == .orderedSame ||
            currentCatalog.catalogId.caseInsensitiveCompare(code) == .orderedSame
    }

    private func refreshSubmitState() {
        canSubmitCorrection = hasMismatch && scannedQuantity >= 0
    }

    private static let auditTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, hh:mm a"
        return formatter
    }()
}
