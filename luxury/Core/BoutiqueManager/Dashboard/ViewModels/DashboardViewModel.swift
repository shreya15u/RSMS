//
//  DashboardViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation
import Network
import Supabase

enum PacingStatus: String {
    case exceeded = "Target Achieved"
    case ahead    = "Ahead of Pace"
    case onTrack  = "On Track"
    case behind   = "Behind Pace"

    var badgeStatus: BadgeStatus {
        switch self {
        case .exceeded: return .success
        case .ahead:    return .success
        case .onTrack:  return .warning
        case .behind:   return .error
        }
    }
}

@Observable
final class DashboardViewModel {

    private var salesActualRaw: Double = 0
    private let storeOpenHour:  Double = 10
    private let storeCloseHour: Double = 20
    private var updateTask:  Task<Void, Never>?
    private var monitorTask: Task<Void, Never>?
    private var sfsPollingTask: Task<Void, Never>?
    var sfsFulfillments: [PurchasedItemEntity] = []
    var pendingAuditsCount: Int = 0
    
    var showAllAppointments: Bool = false {
        didSet {
            fetchAppointments()
        }
    }


    var salesTargetRaw: Double = 0

    var isTargetConfigured: Bool { salesTargetRaw > 0 }
    var isOffline:          Bool = false
    var lastSyncedAt:       Date = Date()
    var isLoadingSales:     Bool = false
    var boutiqueName:       String = "Dashboard"

    var todaySales:  String { isTargetConfigured ? formatCurrency(salesActualRaw) : formatCurrency(salesActualRaw) }
    var salesTarget: String { isTargetConfigured ? formatCurrency(salesTargetRaw) : "No target set" }

    var salesProgress: Double {
        guard isTargetConfigured, salesTargetRaw > 0 else { return 0 }
        return min(1.0, max(0.0, salesActualRaw / salesTargetRaw))
    }

    var pacingProgress: Double {
        let c   = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let now = Double(c.hour ?? Int(storeOpenHour)) + Double(c.minute ?? 0) / 60.0
        return min(1.0, max(0, now - storeOpenHour) / (storeCloseHour - storeOpenHour))
    }

    var pacingStatus: PacingStatus {
        guard isTargetConfigured else { return .onTrack }
        if salesProgress >= 1.0   { return .exceeded }
        let d = salesProgress - pacingProgress
        if d >  0.05 { return .ahead  }
        if d < -0.05 { return .behind }
        return .onTrack
    }

    var projectedSales: String {
        guard isTargetConfigured, pacingProgress > 0.01 else { return salesTarget }
        return formatCurrency(salesActualRaw / pacingProgress)
    }

    var lastSyncedText: String {
        let f        = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: lastSyncedAt, relativeTo: Date())
    }

    var pendingAppointments: [AppointmentEntity] = []

    var appointments: [AppointmentEntity] = []
    var availableStaff: [StaffModel] = []

    func startRealTimeUpdates() {
        fetchBoutiqueName()
        fetchTodaySales()
        fetchAppointments()
        fetchAvailableStaff()
        fetchPendingAuditsCount()
        startSalesPolling()
        startNetworkMonitoring()
        startFulfillmentPolling()
    }

    func stopRealTimeUpdates() {
        updateTask?.cancel()
        updateTask = nil
        monitorTask?.cancel()
        monitorTask = nil
        sfsPollingTask?.cancel()
        sfsPollingTask = nil
    }

    // MARK: – Live Sales Fetch

    func fetchTodaySales() {
        isLoadingSales = true
        Task {
            do {
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: Date())
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let startISO = isoFormatter.string(from: startOfDay)

                let orders: [OrderEntity] = try await SupabaseManager.shared.client
                    .from("order")
                    .select()
                    .gte("date_of_purchase", value: startISO)
                    .execute()
                    .value

                let totalRevenue = orders.reduce(0.0) { $0 + $1.totalPrice }

                await MainActor.run {
                    self.salesActualRaw = totalRevenue
                    self.lastSyncedAt = Date()
                    self.isLoadingSales = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingSales = false
                }
                print("Failed to fetch today's sales: \(error)")
            }
        }
    }

    private func startSalesPolling() {
        updateTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                self?.fetchTodaySales()
            }
        }
    }

    private func startNetworkMonitoring() {
        monitorTask = Task { @MainActor [weak self] in
            for await offline in Self.networkStatusStream() {
                guard !Task.isCancelled else { return }
                self?.isOffline = offline
                if !offline { self?.lastSyncedAt = Date() }
            }
        }
    }

    private static func networkStatusStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { path in
                continuation.yield(path.status != .satisfied)
            }
            monitor.start(queue: .global())
            continuation.onTermination = { _ in monitor.cancel() }
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        return CurrencyManager.shared.format(amount: value)
    }

    func fetchBoutiqueName() {
        Task {
            do {
                if let (_, profile) = try await ProfileService().fetchCurrentProfile() {
                    if let boutique = profile as? CorporateBoutique {
                        await MainActor.run {
                            self.boutiqueName = boutique.name.isEmpty ? "Dashboard" : boutique.name
                            self.salesTargetRaw = boutique.dailySalesTarget ?? 0
                        }
                    }
                }
            } catch {
                print("Failed to fetch boutique name: \(error)")
            }
        }
    }

    func fetchSFSFulfillments() async {
        do {
            var boutiqueId: UUID? = nil
            if let (_, profile) = try await ProfileService().fetchCurrentProfile(),
               let boutique = profile as? CorporateBoutique {
                boutiqueId = boutique.id
            }
            
            guard let bId = boutiqueId else { return }
            
            let items: [PurchasedItemEntity] = try await SupabaseManager.shared.client
                .from("purchased_items")
                .select()
                .eq("boutique_id", value: bId.uuidString)
                .execute()
                .value
            
            let products: [CatalogEntity] = try await SupabaseManager.shared.client
                .from("catalogs")
                .select()
                .execute()
                .value
            
            var resolved: [PurchasedItemEntity] = []
            for var item in items {
                if let product = products.first(where: { $0.id == item.productId }) {
                    item.productName = product.name
                    item.productBrand = product.brand
                    item.productSku = product.catalogId
                }
                resolved.append(item)
            }
            
            let sorted = resolved.sorted(by: { $0.reservedDate > $1.reservedDate })
            
            await MainActor.run {
                self.sfsFulfillments = sorted
            }
        } catch {
            print("Failed to fetch SFS fulfillments: \(error)")
        }
    }

    func fetchPendingAuditsCount() {
        Task {
            do {
                if let (_, profile) = try await ProfileService().fetchCurrentProfile(),
                   let boutique = profile as? CorporateBoutique {
                    let response = try await SupabaseManager.shared.client
                        .from("audits")
                        .select("id")
                        .eq("boutique_id", value: boutique.id.uuidString)
                        .eq("status", value: "due")
                        .execute()
                    
                    struct AuditID: Codable {
                        let id: UUID
                    }
                    let decoder = JSONDecoder()
                    let fetched = try decoder.decode([AuditID].self, from: response.data)
                    await MainActor.run {
                        self.pendingAuditsCount = fetched.count
                    }
                }
            } catch {
                print("Failed to fetch pending audits count: \(error)")
            }
        }
    }

    // TODO: upgrade to WebSocket/SSE
    private func startFulfillmentPolling() {
        sfsPollingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                await self?.fetchSFSFulfillments()
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }
    
    // MARK: - Appointments & Staff
    
    func fetchAppointments() {
        Task {
            do {
                if let (_, profile) = try await ProfileService().fetchCurrentProfile(),
                   let boutique = profile as? CorporateBoutique {
                    
                    let isoFormatter = ISO8601DateFormatter()
                    let todayISO = isoFormatter.string(from: Date())
                    
                    let pending: [AppointmentEntity] = try await SupabaseManager.shared.client
                        .from("appointment")
                        .select("*, client(*)")
                        .eq("boutique_id", value: boutique.id)
                        .eq("status", value: "pending")
                        .order("timestamp", ascending: true)
                        .execute()
                        .value
                    
                    var query = SupabaseManager.shared.client
                        .from("appointment")
                        .select("*, client(*)")
                        .eq("boutique_id", value: boutique.id)
                        .neq("status", value: "pending")
                    
                    if !showAllAppointments {
                        query = query.gte("timestamp", value: todayISO)
                    }
                        
                    let upcoming: [AppointmentEntity] = try await query
                        .order("timestamp", ascending: true)
                        .limit(5)
                        .execute()
                        .value
                    
                    await MainActor.run {
                        self.pendingAppointments = pending
                        self.appointments = upcoming
                    }
                }
            } catch {
                print("Failed to fetch appointments: \(error)")
            }
        }
    }
    
    func refreshAll() async {
        fetchAppointments()
        fetchAvailableStaff()
        fetchPendingAuditsCount()
        await fetchSFSFulfillments()
    }
    
    func fetchAvailableStaff() {
        Task {
            do {
                if let (_, profile) = try await ProfileService().fetchCurrentProfile(),
                   let boutique = profile as? CorporateBoutique {
                    
                    let fetched: [StaffModel] = try await SupabaseManager.shared.client
                        .from("staff")
                        .select()
                        .eq("boutique_id", value: boutique.id)
                        .execute()
                        .value
                    
                    await MainActor.run {
                        self.availableStaff = fetched
                    }
                }
            } catch {
                print("Failed to fetch available staff: \(error)")
            }
        }
    }
    
    func advisorName(for staffId: UUID?) -> String {
        guard let staffId = staffId else { return "Unassigned" }
        return availableStaff.first(where: { $0.id == staffId })?.name ?? "Unknown"
    }
    
    func assignStaff(to appointmentId: UUID, staffId: UUID) async {
        struct UpdateStaffRequest: Encodable {
            let assigned_to: UUID
            let status: String
        }
        do {
            try await SupabaseManager.shared.client
                .from("appointment")
                .update(UpdateStaffRequest(assigned_to: staffId, status: AppointmentStatus.upcoming.rawValue))
                .eq("id", value: appointmentId)
                .execute()
            
            // Refresh
            fetchAppointments()
        } catch {
            print("Failed to assign staff: \(error)")
        }
    }
}
