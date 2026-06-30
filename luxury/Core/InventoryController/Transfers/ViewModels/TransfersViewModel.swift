//
//  TransfersViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation
import Supabase

enum TransferDirection: String, Codable, Hashable {
    case incoming = "Incoming"
    case outgoing = "Outgoing"
}

struct TransferBoardItem: Identifiable, Hashable {
    let transfer: TransferRequest
    let direction: TransferDirection
    let isLive: Bool
    
    var id: String {
        "\(transfer.id.uuidString)-\(direction.rawValue)-\(isLive ? "live" : "manual")"
    }
}

@Observable
final class TransfersViewModel {
    var pendingTransfers: [TransferBoardItem] = []
    var inTransitTransfers: [TransferBoardItem] = []
    var completedTransfers: [TransferBoardItem] = []
    var isLoading = false
    var errorMessage: String?
    
    private let client = SupabaseManager.shared.client
    private var channel: RealtimeChannelV2?
    private var manualChannel: RealtimeChannelV2?
    
    func fetchTransfers(retryCount: Int = 0) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await startObservingLiveTransfers()
                try await startObservingManualTransfers()
                let context = try await transferContext()
                let manualTransfers = try await StockTransferService.shared.fetchTransfers(for: context.boutiqueId)
                    .compactMap { boardItem(for: $0, context: context, isLive: false) }
                
                let liveTransfers = try await fetchLiveTransfers(context: context)
                    .map { boardItem(for: $0, context: context, isLive: true) }
                    .compactMap { $0 }
                
                let allTransfers = manualTransfers + liveTransfers
                
                await MainActor.run {
                    self.pendingTransfers = allTransfers.filter { isPending($0.transfer.status) }
                    self.inTransitTransfers = allTransfers.filter { isInTransit($0.transfer.status) }
                    self.completedTransfers = allTransfers.filter { isCompleted($0.transfer.status) }
                    self.isLoading = false
                }
            } catch {
                if retryCount < 3 && error.localizedDescription.contains("current profile") {
                    try? await Task.sleep(for: .milliseconds(400))
                    self.fetchTransfers(retryCount: retryCount + 1)
                } else {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    func stopObservingLiveTransfers() {
        Task {
            if let channel {
                await client.removeChannel(channel)
                self.channel = nil
            }
            if let manualChannel {
                await client.removeChannel(manualChannel)
                self.manualChannel = nil
            }
        }
    }
    
    private func startObservingLiveTransfers() async throws {
        guard channel == nil else { return }
        
        let liveChannel = client.realtimeV2.channel("transfers_live_feed")
        let insertChanges = liveChannel.postgresChange(InsertAction.self, schema: "public", table: "purchased_items")
        let updateChanges = liveChannel.postgresChange(UpdateAction.self, schema: "public", table: "purchased_items")
        
        channel = liveChannel
        
        Task {
            for await _ in insertChanges {
                await MainActor.run {
                    self.fetchTransfers()
                }
            }
        }
        
        Task {
            for await _ in updateChanges {
                await MainActor.run {
                    self.fetchTransfers()
                }
            }
        }
        
        try await liveChannel.subscribeWithError()
    }

    private func startObservingManualTransfers() async throws {
        guard manualChannel == nil else { return }
        
        let transferChannel = client.realtimeV2.channel("stock_transfers_live_feed")
        let changes = transferChannel.postgresChange(AnyAction.self, schema: "public", table: "stock_transfers")
        manualChannel = transferChannel
        
        Task {
            for await _ in changes {
                await MainActor.run {
                    self.fetchTransfers()
                }
            }
        }
        
        try await transferChannel.subscribeWithError()
    }
    
    private func fetchLiveTransfers(context: TransferContext) async throws -> [TransferRequest] {
        guard let boutiqueId = context.boutiqueId else {
            return []
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
        
        var transfers: [TransferRequest] = []
        var latestByOriginalOrderId: [UUID: (priority: Int, lastUpdated: Date, transfer: TransferRequest)] = [:]
        
        for row in rows {
            guard EndlessAisleLink.decode(row.transactionId) != nil else {
                continue
            }
            guard let request = endlessAisleRequest(from: row, catalogs: catalogs, boutiques: boutiques) else { continue }
            guard request.sourceBoutiqueId == boutiqueId || request.destinationBoutiqueId == boutiqueId else { continue }
            
            let transfer = TransferRequest(
                reference: "EA-\(request.id.uuidString.prefix(8).uppercased())",
                source: request.sourceStore,
                destination: request.destinationStore,
                items: [
                    TransferItem(
                        sku: request.item.sku,
                        name: request.item.name,
                        qty: 1,
                        availableQty: request.status == .received ? 1 : 0
                    )
                ],
                status: transferStatusText(for: request.status),
                badgeStatus: transferBadge(for: request.status)
            )
            if let originalOrderId = request.originalOrderId {
                let candidate = (
                    priority: transferPriority(for: request.status),
                    lastUpdated: request.lastUpdated,
                    transfer: transfer
                )
                if let existing = latestByOriginalOrderId[originalOrderId] {
                    if candidate.priority > existing.priority || (candidate.priority == existing.priority && candidate.lastUpdated >= existing.lastUpdated) {
                        latestByOriginalOrderId[originalOrderId] = candidate
                    }
                } else {
                    latestByOriginalOrderId[originalOrderId] = candidate
                }
            } else {
                transfers.append(transfer)
            }
        }
        
        transfers.append(contentsOf: latestByOriginalOrderId.values.map(\.transfer))
        return transfers.sorted { $0.reference < $1.reference }
    }
    
    func filteredTransfers(for segment: Int) -> [TransferBoardItem] {
        switch segment {
        case 0:
            return pendingTransfers
        case 1:
            return inTransitTransfers
        case 2:
            return completedTransfers
        default:
            return pendingTransfers
        }
    }
    
    private func transferContext() async throws -> TransferContext {
        guard let profile = try await ProfileService().fetchCurrentProfile() else {
            throw NSError(domain: "Transfers", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to resolve the current profile."])
        }
        
        if let staff = profile.1 as? StaffModel, let boutiqueId = staff.boutiqueId, let boutique = try await ProfileService().fetchBoutique(id: boutiqueId) {
            return TransferContext(boutiqueId: boutique.id, boutiqueName: boutique.name)
        }
        
        if let boutique = profile.1 as? CorporateBoutique {
            return TransferContext(boutiqueId: boutique.id, boutiqueName: boutique.name)
        }
        
        throw NSError(domain: "Transfers", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to resolve boutique context."])
    }
    
    private func boardItem(for transfer: TransferRequest, context: TransferContext, isLive: Bool) -> TransferBoardItem? {
        let sourceMatches = transfer.source.localizedCaseInsensitiveCompare(context.boutiqueName) == .orderedSame
        let destinationMatches = transfer.destination.localizedCaseInsensitiveCompare(context.boutiqueName) == .orderedSame
        
        guard sourceMatches || destinationMatches else {
            return nil
        }
        
        let direction: TransferDirection = sourceMatches ? .outgoing : .incoming
        return TransferBoardItem(transfer: transfer, direction: direction, isLive: isLive)
    }
    
    private func boardItem(for request: EndlessAisle.SourcingRequest, context: TransferContext, isLive: Bool) -> TransferBoardItem? {
        guard let boutiqueId = context.boutiqueId else {
            return nil
        }
        
        let sourceMatches = request.sourceBoutiqueId == boutiqueId
        let destinationMatches = request.destinationBoutiqueId == boutiqueId
        
        guard sourceMatches || destinationMatches else {
            return nil
        }
        
        let direction: TransferDirection = sourceMatches ? .outgoing : .incoming
        let transfer = TransferRequest(
            reference: "EA-\(request.id.uuidString.prefix(8).uppercased())",
            source: request.sourceStore,
            destination: request.destinationStore,
            items: [
                TransferItem(
                    sku: request.item.sku,
                    name: request.item.name,
                    qty: 1,
                    availableQty: request.status == .received ? 1 : 0
                )
            ],
            status: transferStatusText(for: request.status),
            badgeStatus: transferBadge(for: request.status)
        )
        return TransferBoardItem(transfer: transfer, direction: direction, isLive: isLive)
    }
    
    private func endlessAisleRequest(from row: PurchasedItemEntity, catalogs: [CatalogEntity], boutiques: [CorporateBoutique]) -> EndlessAisle.SourcingRequest? {
        guard let catalog = catalogs.first(where: { $0.id == row.productId }) else {
            return nil
        }
        
        let item = EndlessAisle.Item(
            id: catalog.id,
            name: catalog.name,
            sku: catalog.catalogId,
            price: catalog.amount,
            localQuantity: 0
        )
        
        guard let link = EndlessAisleLink.decode(row.transactionId) else {
            return nil
        }
        
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
            status: requestState(for: row.status) ?? .checking,
            history: [],
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
    
    private func transferStatusText(for status: EndlessAisle.RequestState) -> String {
        switch status {
        case .pendingBoutiqueManagerApproval, .pendingSourceBoutiqueApproval:
            return "Pending"
        case .pendingSourceDispatch, .dispatched:
            return "In Transit"
        case .arrived:
            return "Pending Receipt"
        case .received:
            return "Completed"
        case .checking, .localInStock, .noStockAnywhere:
            return "Pending"
        }
    }
    
    private func transferBadge(for status: EndlessAisle.RequestState) -> BadgeStatus {
        switch status {
        case .pendingBoutiqueManagerApproval, .pendingSourceBoutiqueApproval:
            return .pending
        case .pendingSourceDispatch, .dispatched:
            return .warning
        case .arrived:
            return .neutral
        case .received:
            return .success
        case .checking, .localInStock, .noStockAnywhere:
            return .neutral
        }
    }

    private func transferPriority(for status: EndlessAisle.RequestState) -> Int {
        switch status {
        case .received:
            return 4
        case .arrived:
            return 3
        case .dispatched:
            return 2
        case .pendingSourceDispatch:
            return 1
        case .pendingBoutiqueManagerApproval, .pendingSourceBoutiqueApproval, .checking, .localInStock, .noStockAnywhere:
            return 0
        }
    }
    
    private func isPending(_ status: String) -> Bool {
        let s = status.lowercased()
        return s == "submitted" || s == "pending approval" || s == "approved" || s == "pending receipt" || s == "pending"
    }
    
    private func isInTransit(_ status: String) -> Bool {
        status.lowercased() == "in transit"
    }
    
    private func isCompleted(_ status: String) -> Bool {
        let s = status.lowercased()
        return s == "completed" || s == "received" || s == "rejected"
    }
}

private struct TransferContext {
    let boutiqueId: UUID?
    let boutiqueName: String
}
