//
//  UIModels.swift
//  luxury
//
//  Created by Aditya Chauhan on 20/05/26.
//

import Foundation
import SwiftUI

enum BadgeStatus: String, Codable, Hashable {
    case success
    case warning
    case error
    case neutral
    case pending
    
    var color: Color {
        switch self {
        case .success: return AppColors.success
        case .warning: return AppColors.warning
        case .error: return AppColors.error
        case .neutral: return AppColors.tertiary
        case .pending: return AppColors.blue
        }
    }
}

struct RSMSVarianceItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let expected: Int
    let actual: Int
    let reason: String
    
    init(id: UUID = UUID(), name: String, expected: Int, actual: Int, reason: String) {
        self.id = id
        self.name = name
        self.expected = expected
        self.actual = actual
        self.reason = reason
    }
}

struct RSMSCycleCount: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let date: String
    let scope: String
    var status: String
    var badgeStatus: BadgeStatus
    
    init(id: UUID = UUID(), title: String, date: String, scope: String, status: String, badgeStatus: BadgeStatus) {
        self.id = id
        self.title = title
        self.date = date
        self.scope = scope
        self.status = status
        self.badgeStatus = badgeStatus
    }
}

enum UrgencyLevel: String, Codable, Comparable {
    case critical = "Critical"
    case warning = "Warning"
    case normal = "Normal"
    
    var priority: Int {
        switch self {
        case .critical: return 0
        case .warning: return 1
        case .normal: return 2
        }
    }
    
    static func < (lhs: UrgencyLevel, rhs: UrgencyLevel) -> Bool {
        lhs.priority < rhs.priority
    }
}

struct InventoryAlert: Identifiable, Hashable {
    let id: UUID
    let itemName: String
    let sku: String
    let currentQty: Int
    let status: BadgeStatus
    let location: String
    let alertType: String
    let timeRaised: String
    let urgency: UrgencyLevel
    
    init(
        id: UUID = UUID(),
        itemName: String,
        sku: String,
        currentQty: Int,
        status: BadgeStatus,
        location: String = "Main Vault",
        alertType: String = "Stock Issue",
        timeRaised: String = "Just Now",
        urgency: UrgencyLevel = .warning
    ) {
        self.id = id
        self.itemName = itemName
        self.sku = sku
        self.currentQty = currentQty
        self.status = status
        self.location = location
        self.alertType = alertType
        self.timeRaised = timeRaised
        self.urgency = urgency
    }
}

struct StockItem: Identifiable, Hashable {
    let id = UUID()
    let brand: String
    let name: String
    let qty: Int
    let rfid: Bool
    let alert: Bool
}

struct ScannedAuditItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let ok: Bool
}

enum ClientTier: String, CaseIterable, Hashable {
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
    
    var badgeStatus: BadgeStatus {
        switch self {
        case .silver: return .neutral
        case .gold: return .warning
        case .platinum: return .success
        }
    }
}

struct Client: Identifiable, Hashable {
    let id: UUID
    let name: String
    let tier: ClientTier
    var lastVisit: String
    var ltv: Double
    let initial: String
    var isHot: Bool
    let phone: String?
    let email: String?
    var dob: String?
    var maritalStatus: String?
    var dateOfAnniversary: String?
    var createdAt: Date?
    
    init(id: UUID = UUID(), name: String, tier: ClientTier, lastVisit: String, ltv: Double, initial: String, isHot: Bool = false, phone: String? = nil, email: String? = nil, dob: String? = nil, maritalStatus: String? = nil, dateOfAnniversary: String? = nil, createdAt: Date? = nil) {
        self.id = id
        self.name = name
        self.tier = tier
        self.lastVisit = lastVisit
        if let storedLTVStr = UserDefaults.standard.string(forKey: "luxury_ltv_\(id.uuidString)"), let storedLTV = Double(storedLTVStr) {
            self.ltv = storedLTV
        } else {
            self.ltv = ltv
        }
        self.initial = initial
        self.isHot = isHot
        self.phone = phone
        self.email = email
        self.dob = dob
        self.maritalStatus = maritalStatus
        self.dateOfAnniversary = dateOfAnniversary
        self.createdAt = createdAt
    }
}

extension Client {
    init(entity: ClientEntity) {
        self.id = entity.id
        self.name = entity.name
        
        let clientTier = ClientTier(rawValue: entity.tier ?? "Silver") ?? .silver
        self.tier = clientTier
        
        let hasPurchases = !(entity.productsPurchased?.isEmpty ?? true)
        self.lastVisit = hasPurchases ? "Today" : "New Client"
        
        // Tier-based default LTV for premium look, but only if they have purchases
        if let storedLTVStr = UserDefaults.standard.string(forKey: "luxury_ltv_\(entity.id.uuidString)"), let storedLTV = Double(storedLTVStr) {
            self.ltv = storedLTV
        } else if hasPurchases {
            switch clientTier {
            case .silver:
                self.ltv = 450000.0
            case .gold:
                self.ltv = 2800000.0
            case .platinum:
                self.ltv = 11500000.0
            }
        } else {
            self.ltv = 0.0
        }
        
        let parts = entity.name.components(separatedBy: " ")
        let firstInit = parts.first?.prefix(1) ?? ""
        let lastInit = parts.count > 1 ? (parts.last?.prefix(1) ?? "") : ""
        self.initial = "\(firstInit)\(lastInit)".uppercased()
        
        // isHot is now managed dynamically by ViewModels based on upcoming appointments
        self.isHot = false
        self.phone = entity.phone
        self.email = entity.email
        self.dob = entity.dob
        self.maritalStatus = entity.maritalStatus
        self.dateOfAnniversary = entity.dateOfAnniversary
        self.createdAt = entity.createdAt
    }
}

struct ClientNote: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var note: String
    let date: String
    let salesAssociateId: UUID
    let authorName: String
}

struct ClientPurchase: Identifiable, Hashable, Codable {
    var id: UUID
    let name: String
    let price: Double
    let date: String
    var productId: UUID?
    var imageUrl: String?
    var boutiqueId: String?
    var boutiqueName: String?
    var boutiqueLocation: String?
    var advisorId: String?
    var advisorName: String?
    
    init(id: UUID = UUID(), name: String, price: Double, date: String, productId: UUID? = nil, imageUrl: String? = nil, boutiqueId: String? = nil, boutiqueName: String? = nil, boutiqueLocation: String? = nil, advisorId: String? = nil, advisorName: String? = nil) {
        self.id = id
        self.name = name
        self.price = price
        self.date = date
        self.productId = productId
        self.imageUrl = imageUrl
        self.boutiqueId = boutiqueId
        self.boutiqueName = boutiqueName
        self.boutiqueLocation = boutiqueLocation
        self.advisorId = advisorId
        self.advisorName = advisorName
    }
}

struct ClientSizePreference: Identifiable, Hashable, Codable {
    var id: UUID
    var ringSize: String
    var wristSize: String
    var apparelSize: String
    var shoeSize: String
    
    init(id: UUID = UUID(), ringSize: String = "", wristSize: String = "", apparelSize: String = "", shoeSize: String = "") {
        self.id = id
        self.ringSize = ringSize
        self.wristSize = wristSize
        self.apparelSize = apparelSize
        self.shoeSize = shoeSize
    }
}

struct ClientWishlistItem: Identifiable, Hashable, Codable {
    var id: UUID
    let brand: String
    let name: String
    let price: Double
    var productImages: [String]?
    
    init(id: UUID = UUID(), brand: String, name: String, price: Double, productImages: [String]? = nil) {
        self.id = id
        self.brand = brand
        self.name = name
        self.price = price
        self.productImages = productImages
    }
}

struct ClientTicket: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    let title: String
    let status: String
    let date: String
    let isActive: Bool
}

struct ClientStat: Identifiable, Hashable {
    let id = UUID()
    let value: String
    let label: String
}

struct ApprovalRequest: Identifiable, Hashable {
    let id: UUID
    let associateName: String
    let clientName: String
    let amount: String
    let discount: String
    
    init(id: UUID = UUID(), associateName: String, clientName: String, amount: String, discount: String) {
        self.id = id
        self.associateName = associateName
        self.clientName = clientName
        self.amount = amount
        self.discount = discount
    }
}


struct SADashClient: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let tier: String
    let lastVisit: String
    let ltv: Double
    let initial: String
}

struct Product: Identifiable, Hashable {
    let id: UUID
    let brand: String
    let name: String
    let price: String
    let inStock: Bool
    
    init(id: UUID = UUID(), brand: String, name: String, price: String, inStock: Bool) {
        self.id = id
        self.brand = brand
        self.name = name
        self.price = price
        self.inStock = inStock
    }
}

struct CartItemModel: Identifiable, Hashable {
    let id: UUID
    let brand: String
    let name: String
    let price: Int
    var qty: Int
    
    init(id: UUID = UUID(), brand: String, name: String, price: Int, qty: Int) {
        self.id = id
        self.brand = brand
        self.name = name
        self.price = price
        self.qty = qty
    }
}

enum TenderMode: String, CaseIterable, Hashable {
    case card = "Card"
    case upi = "UPI"
    case split = "Split"
    case cash = "Cash"
}

struct ScanSession: Identifiable, Hashable {
    let id: UUID
    let date: String
    let zone: String
    let scannedCount: Int
    let expectedCount: Int
    let variance: Int
    
    init(id: UUID = UUID(), date: String, zone: String, scannedCount: Int, expectedCount: Int, variance: Int) {
        self.id = id
        self.date = date
        self.zone = zone
        self.scannedCount = scannedCount
        self.expectedCount = expectedCount
        self.variance = variance
    }
}

struct RFIDTag: Identifiable, Hashable, Codable {
    let id: UUID
    let epc: String
    let name: String
    let ok: Bool
    
    init(id: UUID = UUID(), epc: String, name: String, ok: Bool) {
        self.id = id
        self.epc = epc
        self.name = name
        self.ok = ok
    }
}

struct TransferItem: Identifiable, Hashable, Codable {
    let id: UUID
    let sku: String
    let name: String
    var qty: Int
    var availableQty: Int
    
    init(id: UUID = UUID(), sku: String, name: String, qty: Int, availableQty: Int = 10) {
        self.id = id
        self.sku = sku
        self.name = name
        self.qty = qty
        self.availableQty = availableQty
    }
}

struct TransferRequest: Identifiable, Hashable, Codable {
    let id: UUID
    let reference: String
    let source: String
    let destination: String
    let items: [TransferItem]
    let status: String
    let badgeStatus: BadgeStatus
    
    var itemCount: Int {
        items.reduce(0) { $0 + $1.qty }
    }
    
    init(
        id: UUID = UUID(),
        reference: String = "",
        source: String,
        destination: String,
        items: [TransferItem] = [],
        status: String,
        badgeStatus: BadgeStatus = .neutral
    ) {
        self.id = id
        self.reference = reference
        self.source = source
        self.destination = destination
        self.items = items
        self.status = status
        self.badgeStatus = badgeStatus
    }
}

struct VIPGuest: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var tier: String
    var status: String // "No Response", "Confirmed", "Declined"
    var reminderSent: Bool = false
}

struct StoreEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var date: String
    var rsvpCount: Int
    var type: String
    
    // VIP Preview fields
    var featuredCollection: String?
    var venue: String?
    var hostAssociate: String?
    var guests: [VIPGuest]?
    var deadline: Date?
    var reminderWindowHours: Int? // hours before deadline
    var remindersSent: Bool?
    var invitationsSent: Bool?
    
    init(
        id: UUID = UUID(),
        title: String,
        date: String,
        rsvpCount: Int,
        type: String,
        featuredCollection: String? = nil,
        venue: String? = nil,
        hostAssociate: String? = nil,
        guests: [VIPGuest]? = nil,
        deadline: Date? = nil,
        reminderWindowHours: Int? = nil,
        remindersSent: Bool? = nil,
        invitationsSent: Bool? = false
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.rsvpCount = rsvpCount
        self.type = type
        self.featuredCollection = featuredCollection
        self.venue = venue
        self.hostAssociate = hostAssociate
        self.guests = guests
        self.deadline = deadline
        self.reminderWindowHours = reminderWindowHours
        self.remindersSent = remindersSent
        self.invitationsSent = invitationsSent
    }
}


struct ReportItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let icon: String
    
    init(id: UUID = UUID(), title: String, subtitle: String, icon: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
}

enum KPIType: Hashable {
    case string(String)
    case currency(Double)
}

struct GlobalKPI: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let type: KPIType
    let icon: String
}

struct RevenueData: Identifiable, Hashable {
    let id = UUID()
    let month: String
    let amount: Double
}

struct SalesCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let revenue: String
    let percentage: Double
}

struct TierMetric: Identifiable, Hashable {
    let id = UUID()
    let tier: String
    let count: Int
    let revenue: String
}

struct TeamMember: Identifiable, Hashable {
    let id: UUID
    let name: String
    let role: String
    let shift: String
    let status: String
    let badgeStatus: BadgeStatus
    let salesToday: String
    
    init(id: UUID = UUID(), name: String, role: String, shift: String, status: String, badgeStatus: BadgeStatus, salesToday: String) {
        self.id = id
        self.name = name
        self.role = role
        self.shift = shift
        self.status = status
        self.badgeStatus = badgeStatus
        self.salesToday = salesToday
    }
}

struct BMStaffMember: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let rev: String
    let target: String
    let pct: Double
    let initials: String
    let live: Bool
    let clients: Int
    var avatarUrl: String? = nil
    var resumeUrl: String? = nil
}

struct StaffMetric: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let commission: String
    let conversion: String
    let interactions: Int
}

enum ApprovalState: String, CaseIterable, Hashable {
    case waiting = "Waiting"
    case approved = "Approved"
    case rejected = "Rejected"
    case timedOut = "Timed Out"
}

enum ReturnResolution: String, CaseIterable, Hashable {
    case refund = "Refund"
    case exchange = "Exchange"
    case storeCredit = "Store Credit"
}

enum AfterSalesStage: String, CaseIterable, Hashable {
    case intake = "Intake"
    case managerReview = "Manager Review"
    case inProgress = "In Progress"
    case dispatched = "Dispatched"
    case ready = "Ready"
}

struct DiscountRequest: Identifiable, Hashable {
    let id = UUID()
    let client: String
    let total: String
    let discount: String
    let advisor: String
    let time: String
}

struct AfterSalesTicket: Identifiable, Hashable {
    let id = UUID()
    let client: String
    let item: String
    let serial: String
    let issue: String
    let stage: AfterSalesStage
    let photoRequired: Bool
}

struct ReturnCase: Identifiable, Hashable {
    let id = UUID()
    let receipt: String
    let client: String
    let item: String
    let amount: Double
    let resolution: ReturnResolution
}

struct CertificateRecord: Identifiable, Hashable {
    let id = UUID()
    let item: String
    let serial: String
    let certificate: String
    let status: String
}

struct VarianceReportItem: Identifiable, Hashable, Codable {
    let id: UUID
    let productName: String
    let sku: String
    let expectedQty: Int
    let countedQty: Int
    let variance: Int
    let isArchivedProduct: Bool
}

struct VarianceReport: Identifiable, Hashable, Codable {
    let id: UUID
    let boutiqueName: String
    let date: Date
    let controllerName: String
    let items: [VarianceReportItem]
}

struct UnexpectedScannedItem: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    let barcode: String
    let status: String // e.g. "new_item"
}

struct AuditSession: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    let date: String
    let scope: String
    var status: String
    var badgeStatus: BadgeStatus
    var storeName: String
    var controllerName: String
    var isSubmitted: Bool
    var yetToScanItems: [YetToScanItem]
    var scannedUnitIds: [UUID]
    var varianceReport: VarianceReport?
    var unexpectedScannedItems: [UnexpectedScannedItem]?
}

struct YetToScanItem: Identifiable, Codable, Hashable {
    let id: UUID
    let serialNumber: String
    let catalogId: UUID?
    let name: String
    let brand: String
}

struct YetToScanNetworkResponse: Codable {
    let id: UUID
    let serial_number: String
    let catalog_id: UUID?
    let catalogs: CatalogNetworkResponse?
    
    struct CatalogNetworkResponse: Codable {
        let id: UUID?
        let name: String
        let brand: String
        let catalog_id: String?
    }
}

struct AuditCountItem: Identifiable, Hashable, Codable {
    var id: UUID { productId }
    let productId: UUID
    let name: String
    let sku: String
    let barcode: String
    var expectedQty: Int
    var countedQty: Int
    var isArchivedProduct: Bool
}

enum POStatus: String, Codable, CaseIterable, Hashable {
    case open = "Open"
    case fullyReceived = "Fully Received"
}

struct POItem: Identifiable, Codable, Hashable {
    let id: UUID
    let brand: String
    let name: String
    let sku: String
    let expectedQty: Int
    var receivedQty: Int
    var scannedSerials: [String]
    
    init(id: UUID = UUID(), brand: String, name: String, sku: String, expectedQty: Int, receivedQty: Int = 0, scannedSerials: [String] = []) {
        self.id = id
        self.brand = brand
        self.name = name
        self.sku = sku
        self.expectedQty = expectedQty
        self.receivedQty = receivedQty
        self.scannedSerials = scannedSerials
    }
}

struct PurchaseOrder: Identifiable, Codable, Hashable {
    let id: UUID
    let poNumber: String
    let supplier: String
    var status: POStatus
    var items: [POItem]
    let createdAt: Date
    var receivedAt: Date?
    
    init(id: UUID = UUID(), poNumber: String, supplier: String, status: POStatus = .open, items: [POItem], createdAt: Date = Date(), receivedAt: Date? = nil) {
        self.id = id
        self.poNumber = poNumber
        self.supplier = supplier
        self.status = status
        self.items = items
        self.createdAt = createdAt
        self.receivedAt = receivedAt
    }
}
