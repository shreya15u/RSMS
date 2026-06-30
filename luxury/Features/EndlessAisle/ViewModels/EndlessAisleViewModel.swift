//
//  EndlessAisleViewModel.swift
//  luxury
//
//  Created by Nalinish Ranjan on 26/05/26.
//

import Foundation
import Observation
import Supabase

@Observable
@MainActor
public final class EndlessAisleViewModel {
    public static let shared = EndlessAisleViewModel()
    
    public var isLoading = false
    public var isSaving = false
    public var errorMessage: String?
    
    public var outgoingManagerRequests: [EndlessAisle.SourcingRequest] = []
    public var incomingManagerRequests: [EndlessAisle.SourcingRequest] = []
    public var sourceDispatchRequests: [EndlessAisle.SourcingRequest] = []
    public var destinationReceiveRequests: [EndlessAisle.SourcingRequest] = []
    
    private let client = SupabaseManager.shared.client
    private var requestChannel: RealtimeChannelV2?
    private var requestListeningTask: Task<Void, Never>?
    
    public func loadRequests() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                guard let boutiqueId = try await currentBoutiqueId() else {
                    throw endlessAisleError("Boutique association not found.")
                }
                
                let rows: [PurchasedItemEntity] = try await client
                    .from("purchased_items")
                    .select()
                    .execute()
                    .value
                
                let catalogs: [CatalogEntity] = try await client
                    .from("catalogs")
                    .select()
                    .execute()
                    .value
                
                let boutiques: [CorporateBoutique] = try await client
                    .from("boutiques")
                    .select()
                    .execute()
                    .value
                
                var outgoing: [EndlessAisle.SourcingRequest] = []
                var incoming: [EndlessAisle.SourcingRequest] = []
                var dispatch: [EndlessAisle.SourcingRequest] = []
                var receive: [EndlessAisle.SourcingRequest] = []
                
                for row in rows {
                    guard let request = request(from: row, catalogs: catalogs, boutiques: boutiques) else { continue }
                    
                    if row.boutiqueId == boutiqueId && !row.transactionId.hasPrefix("\(EndlessAisleLink.prefix)|") {
                        if request.status == .pendingBoutiqueManagerApproval || request.status == .pendingSourceBoutiqueApproval || request.status == .arrived {
                            outgoing.append(request)
                        }
                    }
                    
                    if row.boutiqueId == boutiqueId && row.transactionId.hasPrefix("\(EndlessAisleLink.prefix)|") {
                        if request.status == .pendingSourceBoutiqueApproval {
                            incoming.append(request)
                        }
                        if request.status == .pendingSourceDispatch || request.status == .dispatched {
                            dispatch.append(request)
                        }
                    }
                    
                    if request.destinationBoutiqueId == boutiqueId && request.status == .arrived {
                        receive.append(request)
                    }
                }
                
                await MainActor.run {
                    self.outgoingManagerRequests = outgoing.sorted { $0.lastUpdated > $1.lastUpdated }
                    self.incomingManagerRequests = incoming.sorted { $0.lastUpdated > $1.lastUpdated }
                    self.sourceDispatchRequests = dispatch.sorted { $0.lastUpdated > $1.lastUpdated }
                    self.destinationReceiveRequests = receive.sorted { $0.lastUpdated > $1.lastUpdated }
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

    public func startObservingRequests() async {
        guard requestChannel == nil else { return }
        guard let boutiqueId = try? await currentBoutiqueId() else { return }
        
        let channel = client.realtimeV2.channel("endless_aisle_requests_\(boutiqueId.uuidString)")
        let inserts = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "purchased_items",
            filter: .eq("boutique_id", value: boutiqueId.uuidString)
        )
        let updates = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "purchased_items",
            filter: .eq("boutique_id", value: boutiqueId.uuidString)
        )
        
        requestChannel = channel
        requestListeningTask = Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    for await _ in inserts {
                        await MainActor.run {
                            self.loadRequests()
                        }
                    }
                }
                group.addTask {
                    for await _ in updates {
                        await MainActor.run {
                            self.loadRequests()
                        }
                    }
                }
            }
        }
        
        try? await channel.subscribeWithError()
    }
    
    public func stopObservingRequests() async {
        requestListeningTask?.cancel()
        requestListeningTask = nil
        
        if let channel = requestChannel {
            await client.removeChannel(channel)
            requestChannel = nil
        }
    }
    
    func requestManagerApproval(order: PurchasedItemEntity, item: EndlessAisle.Item) {
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                try await updatePurchasedItem(id: order.id, status: EndlessAisleStatus.pendingManagerApproval)
                SystemLogService.shared.logAction(
                    category: .inventory,
                    severity: .warning,
                    message: "Endless Aisle escalation requested for \(item.name)."
                )
                await MainActor.run {
                    self.isSaving = false
                    self.loadRequests()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isSaving = false
                }
            }
        }
    }
    
    public func availableSourceBoutiques(for request: EndlessAisle.SourcingRequest) async -> [EndlessAisle.BoutiqueStock] {
        do {
            let units = try await InventoryService.shared.fetchInventory(forCatalog: request.item.id)
            let available = units.filter { unit in
                unit.status == .available && unit.boutiqueId != request.destinationBoutiqueId
            }
            let grouped = Dictionary(grouping: available, by: \.boutiqueId)
            var stocks: [EndlessAisle.BoutiqueStock] = []
            
            for (boutiqueId, boutiqueUnits) in grouped {
                if let boutique: CorporateBoutique = try? await client
                    .from("boutiques")
                    .select()
                    .eq("id", value: boutiqueId.uuidString)
                    .single()
                    .execute()
                    .value {
                    stocks.append(
                        EndlessAisle.BoutiqueStock(
                            id: boutique.id,
                            name: boutique.name,
                            city: boutique.city,
                            quantity: boutiqueUnits.count
                        )
                    )
                }
            }
            
            return stocks.sorted { $0.name < $1.name }
        } catch {
            return []
        }
    }
    
    public func approveRequesterManager(request: EndlessAisle.SourcingRequest, sourceBoutique: EndlessAisle.BoutiqueStock) async throws {
        guard let originalOrderId = request.originalOrderId,
              let destinationBoutiqueId = request.destinationBoutiqueId else {
            throw endlessAisleError("Request details are incomplete.")
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            let original: PurchasedItemEntity = try await client
                .from("purchased_items")
                .select()
                .eq("id", value: originalOrderId.uuidString)
                .single()
                .execute()
                .value
            
            let requestPayload: [String: AnyJSON] = [
                "uid": .string(original.uid.uuidString),
                "product_id": .string(original.productId.uuidString),
                "reserved_date": .string(ISO8601DateFormatter().string(from: Date())),
                "transaction_id": .string(EndlessAisleLink.encode(originalOrderId: original.id, originalTransactionId: original.transactionId, destinationBoutiqueId: destinationBoutiqueId)),
                "status": .string(EndlessAisleStatus.sourceReview),
                "created_at": .string(ISO8601DateFormatter().string(from: Date())),
                "boutique_id": .string(sourceBoutique.id.uuidString)
            ]
            
            try await client
                .from("purchased_items")
                .insert(requestPayload)
                .execute()
            
            try await updatePurchasedItem(id: original.id, status: EndlessAisleStatus.requested)
            SystemLogService.shared.logAction(
                category: .inventory,
                severity: .info,
                message: "Endless Aisle request sent to \(sourceBoutique.name) for \(request.item.name)."
            )
            
            await MainActor.run {
                self.isSaving = false
                self.loadRequests()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isSaving = false
            }
            throw error
        }
    }
    
    public func approveSourceManager(requestId: UUID) {
        guard let request = incomingManagerRequests.first(where: { $0.id == requestId }),
              let sourceBoutiqueId = request.sourceBoutiqueId,
              let destinationBoutiqueId = request.destinationBoutiqueId,
              let originalOrderId = request.originalOrderId else {
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                let units = try await InventoryService.shared.fetchInventory(forCatalog: request.item.id, boutiqueId: sourceBoutiqueId)
                guard let unit = units.first(where: { $0.status == .available }) else {
                    throw endlessAisleError("Source boutique stock is no longer available.")
                }
                
                let sourceRow: PurchasedItemEntity = try await client
                    .from("purchased_items")
                    .select()
                    .eq("id", value: requestId.uuidString)
                    .single()
                    .execute()
                    .value
                
                guard let link = EndlessAisleLink.decode(sourceRow.transactionId) else {
                    throw endlessAisleError("Endless Aisle request link is invalid.")
                }
                
                try await InventoryService.shared.updateInventoryStatus(serials: [unit.serialNumber], newStatus: .reserved)
                
                let updatedLink = EndlessAisleLink.encode(
                    originalOrderId: originalOrderId,
                    originalTransactionId: link.originalTransactionId,
                    destinationBoutiqueId: destinationBoutiqueId,
                    serialNumber: unit.serialNumber
                )
                
                try await client
                    .from("purchased_items")
                    .update([
                        "status": EndlessAisleStatus.approved,
                        "transaction_id": updatedLink
                    ])
                    .eq("id", value: requestId.uuidString)
                    .execute()
                
                await MainActor.run {
                    self.isSaving = false
                    self.loadRequests()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isSaving = false
                }
            }
        }
    }
    
    public func dispatchSourceRequest(request: EndlessAisle.SourcingRequest) {
        guard let serialNumber = request.serialNumber else {
            errorMessage = "No reserved serial number is attached to this request."
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                try await InventoryService.shared.updateInventoryStatus(serials: [serialNumber], newStatus: .inTransit)
                try await updatePurchasedItem(id: request.id, status: EndlessAisleStatus.dispatched)
                SystemLogService.shared.logAction(
                    category: .inventory,
                    severity: .info,
                    message: "\(request.item.name) dispatched from \(request.sourceStore) to \(request.destinationStore).",
                    boutiqueName: request.sourceStore
                )
                
                await MainActor.run {
                    self.isSaving = false
                    self.loadRequests()
                }
                
                try? await Task.sleep(for: .seconds(5))
                try await updatePurchasedItem(id: request.id, status: EndlessAisleStatus.arrived)
                if let originalOrderId = request.originalOrderId {
                    try await updatePurchasedItem(id: originalOrderId, status: EndlessAisleStatus.arrived)
                }
                
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("EndlessAisleShipmentArrived"), object: nil)
                    self.loadRequests()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isSaving = false
                }
            }
        }
    }
    
    public func receiveSourcedStock(request: EndlessAisle.SourcingRequest, scannedCode: String) {
        guard let destinationBoutiqueId = request.destinationBoutiqueId,
              let serialNumber = request.serialNumber else {
            errorMessage = "Sourced unit details are incomplete."
            return
        }
        
        let normalizedScan = scannedCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let acceptedCodes = [
            serialNumber.lowercased(),
            request.item.sku.lowercased(),
            request.item.id.uuidString.lowercased()
        ]
        guard acceptedCodes.contains(normalizedScan) else {
            errorMessage = "Scanned item does not match \(request.item.sku)."
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                try await InventoryService.shared.updateInventoryStatus(serials: [serialNumber], newStatus: .available, newBoutiqueId: destinationBoutiqueId)
                try await updatePurchasedItem(id: request.id, status: EndlessAisleStatus.received)
                if let originalOrderId = request.originalOrderId {
                    try await updatePurchasedItem(id: originalOrderId, status: "Pending")
                }
                
                SystemLogService.shared.logAction(
                    category: .inventory,
                    severity: .info,
                    message: "\(request.item.name) received at \(request.destinationStore) and added to inventory.",
                    boutiqueName: request.destinationStore
                )
                
                await MainActor.run {
                    self.isSaving = false
                    NotificationCenter.default.post(name: NSNotification.Name("SFSOrderReceived"), object: nil)
                    self.loadRequests()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isSaving = false
                }
            }
        }
    }
    
    public func createRequest(item: EndlessAisle.Item) {
        errorMessage = "Open the SFS order and escalate the missing item from verification."
    }
    
    public func approveBMA(requestId: UUID) {
        guard let request = outgoingManagerRequests.first(where: { $0.id == requestId }) else { return }
        Task {
            let sources = await availableSourceBoutiques(for: request)
            if let first = sources.first {
                try? await approveRequesterManager(request: request, sourceBoutique: first)
            }
        }
    }
    
    public func approveBMB(requestId: UUID) {
        approveSourceManager(requestId: requestId)
    }
    
    public func dispatchICB(requestId: UUID) {
        guard let request = sourceDispatchRequests.first(where: { $0.id == requestId }) else { return }
        dispatchSourceRequest(request: request)
    }
    
    private func currentBoutiqueId() async throws -> UUID? {
        guard let profile = try await ProfileService().fetchCurrentProfile() else {
            return nil
        }
        
        if let staff = profile.1 as? StaffModel {
            return staff.boutiqueId
        }
        
        if let boutique = profile.1 as? CorporateBoutique {
            return boutique.id
        }
        
        return nil
    }
    
    private func updatePurchasedItem(id: UUID, status: String) async throws {
        try await client
            .from("purchased_items")
            .update(["status": status])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    private func request(from row: PurchasedItemEntity, catalogs: [CatalogEntity], boutiques: [CorporateBoutique]) -> EndlessAisle.SourcingRequest? {
        guard let catalog = catalogs.first(where: { $0.id == row.productId }),
              let state = requestState(for: row.status) else {
            return nil
        }
        
        let item = EndlessAisle.Item(
            id: catalog.id,
            name: catalog.name,
            sku: catalog.catalogId,
            price: catalog.amount,
            localQuantity: 0
        )
        
        if let link = EndlessAisleLink.decode(row.transactionId) {
            let source = boutiques.first(where: { $0.id == row.boutiqueId })
            let destination = boutiques.first(where: { $0.id == link.destinationBoutiqueId })
            return EndlessAisle.SourcingRequest(
                id: row.id,
                originalOrderId: link.originalOrderId,
                item: item,
                sourceBoutiqueId: row.boutiqueId,
                destinationBoutiqueId: link.destinationBoutiqueId,
                sourceStore: source?.name ?? "Source Boutique",
                destinationStore: destination?.name ?? "Destination Boutique",
                serialNumber: link.serialNumber,
                status: state,
                history: history(for: state, source: source?.name, destination: destination?.name, serialNumber: link.serialNumber),
                lastUpdated: row.deliveryDate ?? row.reservedDate
            )
        }
        
        let destination = boutiques.first(where: { $0.id == row.boutiqueId })
        return EndlessAisle.SourcingRequest(
            id: row.id,
            originalOrderId: row.id,
            item: item,
            sourceBoutiqueId: nil,
            destinationBoutiqueId: row.boutiqueId,
            sourceStore: "Unassigned",
            destinationStore: destination?.name ?? "Destination Boutique",
            serialNumber: nil,
            status: state,
            history: history(for: state, source: nil, destination: destination?.name, serialNumber: nil),
            lastUpdated: row.deliveryDate ?? row.reservedDate
        )
    }
    
    private func requestState(for status: String) -> EndlessAisle.RequestState? {
        switch status {
        case EndlessAisleStatus.pendingManagerApproval:
            return .pendingBoutiqueManagerApproval
        case EndlessAisleStatus.requested, EndlessAisleStatus.sourceReview:
            return .pendingSourceBoutiqueApproval
        case EndlessAisleStatus.approved:
            return .pendingSourceDispatch
        case EndlessAisleStatus.dispatched:
            return .dispatched
        case EndlessAisleStatus.arrived:
            return .arrived
        case EndlessAisleStatus.received:
            return .received
        default:
            return nil
        }
    }
    
    private func history(for state: EndlessAisle.RequestState, source: String?, destination: String?, serialNumber: String?) -> [String] {
        let sourceName = source ?? "source boutique"
        let destinationName = destination ?? "requesting boutique"
        let serialText = serialNumber.map { " Serial \($0)." } ?? ""
        
        switch state {
        case .pendingBoutiqueManagerApproval:
            return ["Inventory Controller escalated the missing SFS item to the boutique manager."]
        case .pendingSourceBoutiqueApproval:
            return ["Request sent to \(sourceName) for boutique manager approval."]
        case .pendingSourceDispatch:
            return ["\(sourceName) approved the request and reserved a unit.\(serialText)"]
        case .dispatched:
            return ["\(sourceName) dispatched the unit to \(destinationName).\(serialText)"]
        case .arrived:
            return ["Shipment arrived at \(destinationName). Scan the serial number to receive into inventory.\(serialText)"]
        case .received:
            return ["Item received into \(destinationName) inventory.\(serialText)"]
        case .checking, .localInStock, .noStockAnywhere:
            return []
        }
    }
    
    private func endlessAisleError(_ message: String) -> NSError {
        NSError(domain: "EndlessAisle", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
