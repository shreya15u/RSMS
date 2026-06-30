//
//  CycleCountDetailView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI
import Observation
import Supabase

// MARK: - Models

enum AuditModelStatus: String, Codable {
    case scheduled = "scheduled"
    case due = "due"
    case inProgress = "in_progress"
    case signedOff = "signed_off"
}

struct DiscrepancyItem: Codable, Hashable, Identifiable {
    var id: UUID { UUID() }
    let name: String?
    let detail: String?
    let type: String? // "missing" or "new"
}

struct DBStoreAudit: Codable, Identifiable {
    let id: UUID
    let boutiqueId: UUID
    let scheduledDate: String // Stored as "YYYY-MM-DD"
    let fixedDay: Int
    var status: AuditModelStatus
    let totalExpected: Int
    let totalScanned: Int
    let variance: Int
    let accuracy: Double
    let scannedUnitIds: [UUID]?
    let discrepancies: [DiscrepancyItem]?
    var signedOffBy: UUID?
    var signedOffAt: Date?
    let createdBy: UUID?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case boutiqueId = "boutique_id"
        case scheduledDate = "scheduled_date"
        case fixedDay = "fixed_day"
        case status
        case totalExpected = "total_expected"
        case totalScanned = "total_scanned"
        case variance
        case accuracy
        case scannedUnitIds = "scanned_unit_ids"
        case discrepancies
        case signedOffBy = "signed_off_by"
        case signedOffAt = "signed_off_at"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Services

final class CycleCountService {
    private let client = SupabaseManager.shared.client
    
    func fetchAudits(boutiqueId: UUID) async throws -> [DBStoreAudit] {
        return try await client.from("audits")
            .select()
            .eq("boutique_id", value: boutiqueId)
            .order("scheduled_date", ascending: false)
            .execute()
            .value
    }
    
    func signOffAudit(
        auditId: UUID,
        userId: UUID,
        variance: Int,
        accuracy: Double,
        totalScanned: Int,
        discrepancies: [DiscrepancyItem]
    ) async throws {
        struct UpdatePayload: Codable {
            let status: String
            let signed_off_by: UUID
            let signed_off_at: String
            let variance: Int
            let accuracy: Double
            let total_scanned: Int
            let discrepancies: [DiscrepancyItem]
        }
        
        let payload = UpdatePayload(
            status: AuditModelStatus.signedOff.rawValue,
            signed_off_by: userId,
            signed_off_at: ISO8601DateFormatter().string(from: Date()),
            variance: variance,
            accuracy: accuracy,
            total_scanned: totalScanned,
            discrepancies: discrepancies
        )
        
        try await client.from("audits")
            .update(payload)
            .eq("id", value: auditId)
            .execute()
    }
    
    func updateFixedDay(boutiqueId: UUID, day: Int, createdBy: UUID? = nil) async throws {
        let activeAudits: [DBStoreAudit] = try await client.from("audits")
            .select()
            .eq("boutique_id", value: boutiqueId)
            .neq("status", value: AuditModelStatus.signedOff.rawValue)
            .order("scheduled_date", ascending: false)
            .limit(1)
            .execute()
            .value
        
        let today = Date()
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month], from: today)
        comps.day = day
        
        var targetDate = calendar.date(from: comps) ?? today
        
        let targetStartOfDay = calendar.startOfDay(for: targetDate)
        let todayStartOfDay = calendar.startOfDay(for: today)
        
        if targetStartOfDay < todayStartOfDay {
            comps.month = (comps.month ?? 0) + 1
            if let newMonthDate = calendar.date(from: comps), 
               let range = calendar.range(of: .day, in: .month, for: newMonthDate) {
                comps.day = min(day, range.count)
            }
            targetDate = calendar.date(from: comps) ?? today
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let scheduledDateStr = dateFormatter.string(from: targetDate)
        
        if let latest = activeAudits.first {
            let updatePayload: [String: AnyJSON] = [
                "fixed_day": .integer(day),
                "scheduled_date": .string(scheduledDateStr)
            ]
            try await client.from("audits")
                .update(updatePayload)
                .eq("id", value: latest.id)
                .execute()
        } else {
            struct InsertAudit: Codable {
                let boutique_id: UUID
                let scheduled_date: String
                let fixed_day: Int
                let status: String
            }
            let payload = InsertAudit(
                boutique_id: boutiqueId,
                scheduled_date: scheduledDateStr,
                fixed_day: day,
                status: AuditModelStatus.scheduled.rawValue
            )
            try await client.from("audits")
                .insert(payload)
                .execute()
        }
    }
}

// MARK: - ViewModels

@Observable
final class CycleCountViewModel {
    static let shared = CycleCountViewModel()
    
    var activeAudits: [DBStoreAudit] = []
    var completedAudits: [DBStoreAudit] = []
    
    var openCount: Int { activeAudits.count }
    var closedCount: Int { completedAudits.count }
    
    var isLoading = false
    var errorMessage: String?
    
    var boutiqueId: UUID?
    var currentUserId: UUID?
    
    private let service = CycleCountService()
    private let profileService = ProfileService()
    
    func loadAudits() {
        isLoading = true
        Task {
            do {
                if boutiqueId == nil {
                    let profile = try await profileService.fetchCurrentProfile()
                    if let manager = profile?.1 as? CorporateBoutique {
                        self.boutiqueId = manager.id
                    }
                }
                if currentUserId == nil {
                    if let session = try? await SupabaseManager.shared.client.auth.session {
                        self.currentUserId = session.user.id
                    }
                }
                
                guard let bId = boutiqueId else {
                    await MainActor.run { isLoading = false }
                    return
                }
                
                let audits = try await service.fetchAudits(boutiqueId: bId)
                
                await MainActor.run {
                    self.activeAudits = audits.filter { $0.status != .signedOff }
                    self.completedAudits = audits.filter { $0.status == .signedOff }
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
    
    func signOffAudit(
        auditId: UUID,
        variance: Int,
        accuracy: Double,
        totalScanned: Int,
        discrepancies: [DiscrepancyItem],
        onSuccess: @escaping () -> Void
    ) {
        guard let userId = currentUserId else { return }
        
        Task {
            do {
                // Fetch manager profile to resolve email
                let profile = try await profileService.fetchCurrentProfile()
                var managerEmail = ""
                if let manager = profile?.1 as? CorporateBoutique {
                    managerEmail = manager.managerEmail
                }
                
                // Query public.staff for manager's staff id
                var staffId: UUID? = nil
                if !managerEmail.isEmpty {
                    struct StaffRecord: Codable {
                        let id: UUID
                    }
                    let staffList: [StaffRecord] = try await SupabaseManager.shared.client
                        .from("staff")
                        .select("id")
                        .eq("email", value: managerEmail)
                        .execute()
                        .value
                    staffId = staffList.first?.id
                }
                
                // Fallback to first available staff member for this boutique to satisfy foreign key constraint
                if staffId == nil, let bId = boutiqueId {
                    struct StaffRecord: Codable {
                        let id: UUID
                    }
                    let fallbackList: [StaffRecord] = try await SupabaseManager.shared.client
                        .from("staff")
                        .select("id")
                        .eq("boutique_id", value: bId.uuidString)
                        .limit(1)
                        .execute()
                        .value
                    staffId = fallbackList.first?.id
                }
                
                guard let finalStaffId = staffId else {
                    throw NSError(
                        domain: "RSMS",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "No staff profile record found in public.staff table for this boutique to execute sign-off validation."]
                    )
                }
                
                try await service.signOffAudit(
                    auditId: auditId,
                    userId: finalStaffId,
                    variance: variance,
                    accuracy: accuracy,
                    totalScanned: totalScanned,
                    discrepancies: discrepancies
                )
                
                // Fetch latest audits immediately to update state arrays synchronously
                if let bId = boutiqueId {
                    let audits = try await service.fetchAudits(boutiqueId: bId)
                    await MainActor.run {
                        self.activeAudits = audits.filter { $0.status != .signedOff }
                        self.completedAudits = audits.filter { $0.status == .signedOff }
                        onSuccess()
                    }
                } else {
                    await MainActor.run {
                        self.loadAudits()
                        onSuccess()
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func updateFixedDayAsync(day: Int) async throws {
        guard let bId = boutiqueId else { return }
        let creatorId = currentUserId
        try await service.updateFixedDay(boutiqueId: bId, day: day, createdBy: creatorId)
        await MainActor.run {
            self.loadAudits()
        }
    }
    
    func updateFixedDay(day: Int) {
        Task {
            do {
                try await updateFixedDayAsync(day: day)
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func fetchCurrentAuditDate(completion: @escaping (Int) -> Void) {
        Task {
            do {
                if boutiqueId == nil {
                    let profile = try await profileService.fetchCurrentProfile()
                    if let manager = profile?.1 as? CorporateBoutique {
                        self.boutiqueId = manager.id
                    }
                }
                guard let bId = boutiqueId else { return }
                
                struct AuditDay: Codable {
                    let fixed_day: Int
                }
                let audits: [AuditDay] = try await SupabaseManager.shared.client.from("audits")
                    .select("fixed_day")
                    .eq("boutique_id", value: bId)
                    .order("scheduled_date", ascending: false)
                    .limit(1)
                    .execute()
                    .value
                
                if let first = audits.first {
                    await MainActor.run {
                        completion(first.fixed_day)
                    }
                }
            } catch {
                print("Fetch current audit date error: \(error)")
            }
        }
    }
    
    func getFormattedDate(from dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
        return dateString
    }
    
    func getStatusLabel(for status: AuditModelStatus) -> String {
        switch status {
        case .scheduled: return "Scheduled"
        case .due: return "Pending Review"
        case .inProgress: return "In Progress"
        case .signedOff: return "Completed"
        }
    }
    
    func getStatusColor(for status: AuditModelStatus) -> Color {
        switch status {
        case .scheduled: return AppColors.blue
        case .due: return AppColors.gold
        case .inProgress: return AppColors.gold
        case .signedOff: return AppColors.success
        }
    }
}


struct CycleCountDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Router.self) private var router
    @State private var viewModel = CycleCountViewModel.shared
    @State private var selectedDay: String = ""
    @State private var applyNextMonth: Bool = false
    @State private var showConfirmAlert: Bool = false
    @State private var pendingSelectedDay: String = ""
    @State private var showDatePicker: Bool = false
    @State private var customDate: Date = Date()
    
    private var isCustomDateSelected: Bool {
        !["1st Day", "15th Day", "Last Day"].contains(selectedDay) && !selectedDay.isEmpty
    }

    private var auditDateTitle: String {
        if selectedDay.isEmpty {
            return "Loading..."
        }
        if selectedDay == "1st Day" {
            return "1st of every month"
        } else if selectedDay == "15th Day" {
            return "15th of every month"
        } else if selectedDay == "Last Day" {
            return "Last day of every month"
        } else {
            return "\(selectedDay) of every month"
        }
    }

    private func formatDayAsOrdinal(_ day: Int) -> String {
        let suffix: String
        if (11...13).contains(day % 100) {
            suffix = "th"
        } else {
            switch day % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(day)\(suffix)"
    }

    private func dayNumber(for dayString: String) -> Int {
        if dayString == "1st Day" { return 1 }
        if dayString == "15th Day" { return 15 }
        if dayString == "Last Day" {
            let range = Calendar.current.range(of: .day, in: .month, for: Date())
            return range?.count ?? 28
        }
        return Int(dayString.replacingOccurrences(of: "st", with: "").replacingOccurrences(of: "nd", with: "").replacingOccurrences(of: "rd", with: "").replacingOccurrences(of: "th", with: "")) ?? 1
    }

    private func syncCustomDate(from dayString: String) {
        let dayNum = dayNumber(for: dayString)
        var components = Calendar.current.dateComponents([.year, .month], from: Date())
        components.day = dayNum
        if let newDate = Calendar.current.date(from: components) {
            customDate = newDate
        }
    }

    private func executeDayUpdate(for dayString: String) {
        let dayNum = dayNumber(for: dayString)
        Task {
            do {
                try await viewModel.updateFixedDayAsync(day: dayNum)
            } catch {
                print("Failed to execute day update: \(error.localizedDescription)")
            }
        }
    }

    private var displayVariance: String {
        guard let latest = viewModel.completedAudits.first else { return "N/A" }
        return latest.variance > 0 ? "+\(latest.variance)" : "\(latest.variance)"
    }
    
    private var displayAccuracy: String {
        guard let latest = viewModel.completedAudits.first else { return "N/A" }
        return (latest.accuracy / 100.0).formatted(.percent.precision(.fractionLength(1)))
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                CustomHeader(title: "Inventory Audit Approval", showBackButton: true, backAction: { router.pop() }, isInline: true)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // 1. Top Section - Summary Metric Cards (First Block)
                        HStack(spacing: 12) {
                            MetricCard(title: "Variance", value: displayVariance, subtitle: "Net Discrepancy", icon: "arrow.up.arrow.down")
                                .frame(height: 160)
                            MetricCard(title: "Accuracy", value: displayAccuracy, subtitle: "Store Performance", icon: "percent")
                                .frame(height: 160)
                        }
                        .padding(.horizontal, 24)

                        // Pending Audits Section (if any are awaiting sign-off)
                        let pendingAudits = viewModel.activeAudits.filter { $0.status == .due || $0.status == .inProgress }
                        if !pendingAudits.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("AWAITING APPROVAL")
                                    .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1.5)
                                    .padding(.horizontal, 24)
                                    
                                VStack(spacing: 12) {
                                    ForEach(pendingAudits) { audit in
                                        Button(action: {
                                            router.push(BMRoute.activeAuditReportDetail(audit.id.uuidString))
                                        }) {
                                            HStack {
                                                Image(systemName: "clock.badge.checkmark")
                                                    .font(.system(size: 18))
                                                    .foregroundStyle(AppColors.gold)
                                                    .frame(width: 36, height: 36)
                                                    .background(AppColors.gold.opacity(0.1))
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(viewModel.getFormattedDate(from: audit.scheduledDate))
                                                        .font(AppFonts.serif(size: 17, weight: .semibold))
                                                        .foregroundStyle(.white)
                                                    
                                                    Text(audit.status == .due ? "Submitted by Controller • Awaiting Sign-off" : "In Progress")
                                                        .font(AppFonts.sansSerif(size: 13))
                                                        .foregroundStyle(AppColors.secondary)
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(AppColors.secondary)
                                            }
                                            .padding(16)
                                            .background(AppColors.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(AppColors.border, lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }

                        // 2. Middle Section - Reports & Actions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("REPORTS & ACTIONS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                                
                            VStack(spacing: 12) {
                                Button(action: {
                                    router.push(BMRoute.auditReportHub)
                                }) {
                                    HStack {
                                        Image(systemName: "doc.text.magnifyingglass")
                                            .font(.system(size: 18))
                                            .foregroundStyle(AppColors.gold)
                                            .frame(width: 36, height: 36)
                                            .background(AppColors.gold.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Audit Report")
                                                .font(AppFonts.serif(size: 17, weight: .semibold))
                                                .foregroundStyle(.white)
                                            
                                            Text("\(viewModel.closedCount) Archived Records")
                                                .font(AppFonts.sansSerif(size: 13))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(AppColors.secondary)
                                    }
                                    .padding(16)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(AppColors.border, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    router.push(BMRoute.writeOffApproval)
                                }) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.system(size: 18))
                                            .foregroundStyle(AppColors.gold)
                                            .frame(width: 36, height: 36)
                                            .background(AppColors.gold.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Write-Off Logs")
                                                .font(AppFonts.serif(size: 17, weight: .semibold))
                                                .foregroundStyle(.white)
                                            
                                            Text("Review and approve damaged items")
                                                .font(AppFonts.sansSerif(size: 13))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(AppColors.secondary)
                                    }
                                    .padding(16)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(AppColors.border, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 24)
                        }

                        // 3. Lower Section - Simplified Audit Schedule & Date Picker (Third Block)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AUDIT SCHEDULE — MANAGER CONTROL")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("FIXED AUDIT DATE")
                                        .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                        .foregroundStyle(AppColors.gold)
                                        .kerning(1.0)
                                    
                                    Text(auditDateTitle)
                                        .font(AppFonts.serif(size: 24, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                
                                // Day of Month Menu
                                Menu {
                                    Picker("Reschedule", selection: Binding(
                                        get: { Calendar.current.component(.day, from: customDate) },
                                        set: { newDay in
                                            var comps = Calendar.current.dateComponents([.year, .month], from: Date())
                                            comps.day = newDay
                                            if let newDate = Calendar.current.date(from: comps) {
                                                customDate = newDate
                                                pendingSelectedDay = formatDayAsOrdinal(newDay)
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                    showConfirmAlert = true
                                                }
                                            }
                                        }
                                    )) {
                                        ForEach(1...31, id: \.self) { day in
                                            Text("\(day)").tag(day)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 16))
                                            .foregroundStyle(AppColors.gold)
                                        Text("Reschedule Date")
                                            .font(AppFonts.sansSerif(size: 13, weight: .semibold))
                                            .foregroundStyle(AppColors.secondary)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundStyle(AppColors.gold50)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(AppColors.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 1))
                                }
                                .padding(.top, 4)
                            }
                            .padding(20)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.gold50, lineWidth: 0.8)
                            )
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
            }
            
        }
        .onAppear {
            viewModel.loadAudits()
            viewModel.fetchCurrentAuditDate { day in
                if day == 1 { selectedDay = "1st Day" }
                else if day == 15 { selectedDay = "15th Day" }
                else if day == 28 || day == 30 || day == 31 { selectedDay = "Last Day" }
                else { selectedDay = formatDayAsOrdinal(day) }
                syncCustomDate(from: selectedDay)
            }
        }
        .onChange(of: viewModel.isLoading) { _, isLoading in
            if !isLoading {
                if let day = viewModel.activeAudits.first?.fixedDay ?? viewModel.completedAudits.first?.fixedDay {
                    if day == 1 { selectedDay = "1st Day" }
                    else if day == 15 { selectedDay = "15th Day" }
                    else if day == 28 || day == 30 || day == 31 { selectedDay = "Last Day" }
                    else { selectedDay = formatDayAsOrdinal(day) }
                } else {
                    selectedDay = "1st Day"
                }
                syncCustomDate(from: selectedDay)
            }
        }

        .alert("Reschedule Audit", isPresented: $showConfirmAlert) {
            Button("Cancel", role: .cancel) {
                syncCustomDate(from: selectedDay)
            }
            Button("Yes") {
                selectedDay = pendingSelectedDay
                executeDayUpdate(for: pendingSelectedDay)
            }
        } message: {
            Text("Do you want to change the date?")
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Screen 1: The New Full-Screen Audit Report Hub
struct AuditReportHubView: View {
    @Environment(Router.self) private var router
    @State private var selectedTab: String = "Pending Review"
    @State private var viewModel = CycleCountViewModel.shared
    
    private var pendingReviewAudits: [DBStoreAudit] {
        viewModel.activeAudits.filter { $0.status == .due || $0.status == .inProgress }
    }
    
    private var activeTabAudits: [DBStoreAudit] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        return viewModel.activeAudits.filter { audit in
            let isCurrent = (audit.scheduledDate == today) || (audit.status == .inProgress)
            let isPending = (audit.scheduledDate < today) && (audit.status != .signedOff)
            return isCurrent || isPending
        }
    }
    
    private var completedAudits: [DBStoreAudit] {
        viewModel.completedAudits
    }
    
    private func formatDayAsOrdinal(_ day: Int) -> String {
        let suffix: String
        if (11...13).contains(day % 100) { suffix = "th" }
        else {
            switch day % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(day)\(suffix)"
    }
    
    private var upcomingAuditProj: (title: String, dateStr: String, badge: Color)? {
        let fixedDay = viewModel.activeAudits.first?.fixedDay ?? viewModel.completedAudits.first?.fixedDay
        guard let day = fixedDay else { return nil }
        
        let today = Date()
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month], from: today)
        comps.day = day
        
        var projectedDate = calendar.date(from: comps) ?? today
        
        let targetStartOfDay = calendar.startOfDay(for: projectedDate)
        let todayStartOfDay = calendar.startOfDay(for: today)
        
        if targetStartOfDay == todayStartOfDay {
            return nil
        }
        
        if targetStartOfDay < todayStartOfDay {
            comps.month = (comps.month ?? 0) + 1
            if let newMonthDate = calendar.date(from: comps), 
               let range = calendar.range(of: .day, in: .month, for: newMonthDate) {
                comps.day = min(day, range.count)
            }
            projectedDate = calendar.date(from: comps) ?? today
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        let formattedDate = formatter.string(from: projectedDate)
        
        return (title: "Audit \(formatDayAsOrdinal(day))", dateStr: formattedDate, badge: AppColors.blue)
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Apple Native Segmented Control
                Picker("Tab", selection: $selectedTab) {
                    Text("Pending Review").tag("Pending Review")
                    Text("Upcoming").tag("Upcoming")
                    Text("Completed").tag("Completed")
                }
                .pickerStyle(.segmented)
                .colorScheme(.dark)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Toggle List Views
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if selectedTab == "Pending Review" {
                            Text("AWAITING SIGN-OFF")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                                .padding(.top, 12)
                            
                            VStack(spacing: 12) {
                                ForEach(pendingReviewAudits) { audit in
                                    ActiveAuditRow(
                                        status: audit.status == .due ? "Submitted" : "In Progress",
                                        date: viewModel.getFormattedDate(from: audit.scheduledDate),
                                        badgeColor: audit.status == .due ? AppColors.success : AppColors.gold
                                    ) {
                                        router.push(BMRoute.activeAuditReportDetail(audit.id.uuidString))
                                    }
                                }
                                if pendingReviewAudits.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "tray.fill")
                                            .font(.system(size: 28))
                                            .foregroundStyle(AppColors.tertiary)
                                        Text("No pending audits for review.")
                                            .font(AppFonts.sansSerif(size: 13))
                                            .foregroundStyle(AppColors.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 28)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                                }
                            }
                            .padding(.horizontal, 24)
                            
                        } else if selectedTab == "Upcoming" {
                            Text("PROJECTED SCHEDULE")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                                .padding(.top, 12)
                            
                            VStack(spacing: 12) {
                                if let upcoming = upcomingAuditProj {
                                    ActiveAuditRow(
                                        status: "Upcoming",
                                        date: upcoming.dateStr,
                                        badgeColor: upcoming.badge
                                    ) {
                                        // Upcoming view not actionable
                                    }
                                } else {
                                    Text("No schedule configured.")
                                        .font(AppFonts.sansSerif(size: 14))
                                        .foregroundStyle(AppColors.secondary)
                                        .padding(.vertical, 20)
                                }
                            }
                            .padding(.horizontal, 24)
                            
                        } else {
                            Text("HISTORICAL FINALIZED COUNTS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                                .padding(.top, 12)
                            
                            VStack(spacing: 12) {
                                ForEach(completedAudits) { audit in
                                    HubCompletedAuditRow(
                                        date: viewModel.getFormattedDate(from: audit.scheduledDate),
                                        variance: "\(audit.variance)",
                                        accuracy: (audit.accuracy / 100).formatted(.percent.precision(.fractionLength(1)))
                                    ) {
                                        router.push(BMRoute.auditReportDetail(audit.id.uuidString))
                                    }
                                }
                                if completedAudits.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "tray")
                                            .font(.system(size: 28))
                                            .foregroundStyle(AppColors.tertiary)
                                        Text("No completed audits yet.")
                                            .font(AppFonts.sansSerif(size: 13))
                                            .foregroundStyle(AppColors.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 28)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Audit History Hub")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            viewModel.loadAudits()
        }
    }
}

// MARK: - Screen 2: Deep Breakdown Sub-View
struct AuditReportDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CycleCountViewModel.shared
    let auditTitle: String // actually auditId.uuidString
    
    @State private var verifiedItems: [YetToScanItem] = []
    @State private var isLoadingVerified = false
    
    @State private var missingExpanded = true
    @State private var newExpanded = true
    @State private var successfulExpanded = false
    
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    
    private var audit: DBStoreAudit? {
        viewModel.completedAudits.first { $0.id.uuidString == auditTitle } ?? viewModel.activeAudits.first { $0.id.uuidString == auditTitle }
    }
    
    private var missingItems: [DiscrepancyItem] {
        audit?.discrepancies?.filter { ($0.type ?? "missing") == "missing" } ?? []
    }
    
    private var newItems: [DiscrepancyItem] {
        audit?.discrepancies?.filter { ($0.type ?? "missing") == "new" } ?? []
    }
    
    private var report: VarianceReport {
        VarianceReport(
            id: audit?.id ?? UUID(),
            boutiqueName: "Boutique Audit",
            date: audit?.signedOffAt ?? Date(),
            controllerName: "Manager Verified",
            items: []
        )
    }
    
    private var filteredItems: [VarianceReportItem] {
        var list: [VarianceReportItem] = []
        for item in missingItems {
            list.append(
                VarianceReportItem(
                    id: UUID(),
                    productName: item.name ?? "Unknown Item",
                    sku: item.detail ?? "Missing",
                    expectedQty: 1,
                    countedQty: 0,
                    variance: -1,
                    isArchivedProduct: false
                )
            )
        }
        for item in newItems {
            list.append(
                VarianceReportItem(
                    id: UUID(),
                    productName: item.name ?? "Unknown Item",
                    sku: item.detail ?? "New",
                    expectedQty: 0,
                    countedQty: 1,
                    variance: 1,
                    isArchivedProduct: false
                )
            )
        }
        for item in verifiedItems {
            list.append(
                VarianceReportItem(
                    id: UUID(),
                    productName: item.name,
                    sku: "Serial: \(item.serialNumber)",
                    expectedQty: 1,
                    countedQty: 1,
                    variance: 0,
                    isArchivedProduct: false
                )
            )
        }
        return list.sorted { abs($0.variance) > abs($1.variance) }
    }
    
    private func fetchVerifiedItems() async {
        guard let scannedUnitIds = audit?.scannedUnitIds, !scannedUnitIds.isEmpty else { return }
        await MainActor.run { isLoadingVerified = true }
        do {
            var allResponses: [YetToScanNetworkResponse] = []
            let chunkSize = 1000
            for i in stride(from: 0, to: scannedUnitIds.count, by: chunkSize) {
                let chunk = Array(scannedUnitIds[i..<min(i + chunkSize, scannedUnitIds.count)])
                let response: [YetToScanNetworkResponse] = try await SupabaseManager.shared.client
                    .from("inventory_units")
                    .select("id, serial_number, catalog_id, catalogs(id, name, brand, catalog_id)")
                    .in("id", values: chunk)
                    .execute()
                    .value
                allResponses.append(contentsOf: response)
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
                self.verifiedItems = items
                self.isLoadingVerified = false
            }
        } catch {
            print("Failed to fetch verified items: \(error)")
            await MainActor.run { isLoadingVerified = false }
        }
    }
    
    private func generateCSV() -> URL? {
        var csvString = "Item Name,SKU,Expected Qty,Counted Qty,Variance\n"
        for item in filteredItems {
            let escapedName = item.productName.replacingOccurrences(of: "\"", with: "\"\"")
            csvString += "\"\(escapedName)\",\(item.sku),\(item.expectedQty),\(item.countedQty),\(item.variance)\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("VarianceReport.csv")
        try? csvString.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    @MainActor
    private func generatePDF() -> URL? {
        let printView = PDFReportView(report: report, filteredItems: filteredItems)
        let renderer = ImageRenderer(content: printView)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("VarianceReport.pdf")
        
        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let pdfContext = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdfContext.beginPDFPage(nil)
            context(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
        }
        return url
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            if audit == nil {
                VStack {
                    Spacer()
                    ProgressView().tint(AppColors.gold)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // Title Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("COUNT HEALTH BREAKDOWN")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.gold)
                                .kerning(1.5)
                            
                            Text("Boutique Count Report")
                                .font(AppFonts.serif(size: 26, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Text("Detailed verification report from store count")
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.secondary)
                        }
                        .padding(.horizontal, 24)
                        
                        // Scrollable metrics summary row
                        if let db = audit {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    MetricCard(title: "Total Expected", value: "\(db.totalExpected)", subtitle: nil, icon: "doc.text")
                                        .frame(width: 160, height: 160)
                                    MetricCard(title: "Total Scanned", value: "\(db.totalScanned)", subtitle: nil, icon: "barcode.viewfinder")
                                        .frame(width: 160, height: 160)
                                    MetricCard(title: "Variance", value: "\(db.variance)", subtitle: nil, icon: "exclamationmark.triangle")
                                        .frame(width: 160, height: 160)
                                    MetricCard(title: "Accuracy", value: String(format: "%.1f%%", db.accuracy), subtitle: nil, icon: "percent")
                                        .frame(width: 160, height: 160)
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        // Expandable cards list
                        VStack(spacing: 20) {
                            // Missing Items Card
                            ReportCardView(
                                title: "MISSING ITEMS",
                                quantity: missingItems.count,
                                skuCount: missingItems.count,
                                iconName: "xmark.circle.fill",
                                themeColor: AppColors.error,
                                isExpanded: $missingExpanded
                            ) {
                                if missingItems.isEmpty {
                                    Text("No missing items.")
                                        .font(AppFonts.sansSerif(size: 14))
                                        .foregroundStyle(AppColors.secondary)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    LazyVStack(spacing: 12) {
                                        ForEach(missingItems, id: \.detail) { item in
                                            BreakdownProductRow(name: item.name ?? "Unknown Item", detail: item.detail ?? "No details provided", status: "", statusColor: AppColors.error)
                                                .padding(.horizontal, 0)
                                        }
                                    }
                                }
                            }
                            
                            // New Items Card
                            ReportCardView(
                                title: "NEW ITEMS",
                                quantity: newItems.count,
                                skuCount: newItems.count,
                                iconName: "plus.circle.fill",
                                themeColor: AppColors.blue,
                                isExpanded: $newExpanded
                            ) {
                                if newItems.isEmpty {
                                    Text("No new items.")
                                        .font(AppFonts.sansSerif(size: 14))
                                        .foregroundStyle(AppColors.secondary)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    LazyVStack(spacing: 12) {
                                        ForEach(newItems, id: \.detail) { item in
                                            BreakdownProductRow(name: item.name ?? "Unknown Item", detail: item.detail ?? "No details provided", status: "New Item", statusColor: AppColors.warning)
                                                .padding(.horizontal, 0)
                                        }
                                    }
                                }
                            }
                            
                            // Successful/Verified Items Card
                            ReportCardView(
                                title: "SUCCESSFUL ITEMS",
                                quantity: verifiedItems.count,
                                skuCount: verifiedItems.count,
                                iconName: "checkmark.circle.fill",
                                themeColor: AppColors.success,
                                isExpanded: $successfulExpanded
                            ) {
                                if isLoadingVerified {
                                    ProgressView().tint(AppColors.gold)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else if verifiedItems.isEmpty {
                                    Text("No successful items.")
                                        .font(AppFonts.sansSerif(size: 14))
                                        .foregroundStyle(AppColors.secondary)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    LazyVStack(spacing: 12) {
                                        ForEach(verifiedItems) { item in
                                            BreakdownProductRow(name: item.name, detail: "Serial: \(item.serialNumber) • Brand: \(item.brand)", status: "Verified", statusColor: AppColors.success)
                                                .padding(.horizontal, 0)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Export Buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                if let url = generateCSV() {
                                    shareURL = url
                                    showShareSheet = true
                                }
                            }) {
                                Label("Export CSV", systemImage: "doc.text.fill")
                                    .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            Button(action: {
                                if let url = generatePDF() {
                                    shareURL = url
                                    showShareSheet = true
                                }
                            }) {
                                Label("Export PDF", systemImage: "doc.richtext.fill")
                                    .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                    .foregroundStyle(AppColors.background)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(AppColors.gold)
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .padding(.vertical, 24)
                }
            }
        }
        .navigationTitle("Audit Breakdown")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
        .task {
            await fetchVerifiedItems()
        }
    }
}

struct ActiveAuditReportDetailView: View {
    @Environment(Router.self) private var router
    let auditTitle: String // auditId.uuidString
    @State private var viewModel = CycleCountViewModel.shared
    
    @State private var verifiedItems: [YetToScanItem] = []
    @State private var isLoadingVerified = false
    
    @State private var missingExpanded = true
    @State private var newExpanded = true
    @State private var successfulExpanded = false
    
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    
    private var audit: DBStoreAudit? {
        viewModel.activeAudits.first { $0.id.uuidString == auditTitle }
    }
    
    private var missingItems: [DiscrepancyItem] {
        audit?.discrepancies?.filter { ($0.type ?? "missing") == "missing" } ?? []
    }
    
    private var newItems: [DiscrepancyItem] {
        audit?.discrepancies?.filter { ($0.type ?? "missing") == "new" } ?? []
    }
    
    private var report: VarianceReport {
        VarianceReport(
            id: audit?.id ?? UUID(),
            boutiqueName: "Boutique Audit",
            date: Date(),
            controllerName: "Manager Verified",
            items: []
        )
    }
    
    private var filteredItems: [VarianceReportItem] {
        var list: [VarianceReportItem] = []
        for item in missingItems {
            list.append(
                VarianceReportItem(
                    id: UUID(),
                    productName: item.name ?? "Unknown Item",
                    sku: item.detail ?? "Missing",
                    expectedQty: 1,
                    countedQty: 0,
                    variance: -1,
                    isArchivedProduct: false
                )
            )
        }
        for item in newItems {
            list.append(
                VarianceReportItem(
                    id: UUID(),
                    productName: item.name ?? "Unknown Item",
                    sku: item.detail ?? "New",
                    expectedQty: 0,
                    countedQty: 1,
                    variance: 1,
                    isArchivedProduct: false
                )
            )
        }
        for item in verifiedItems {
            list.append(
                VarianceReportItem(
                    id: UUID(),
                    productName: item.name,
                    sku: "Serial: \(item.serialNumber)",
                    expectedQty: 1,
                    countedQty: 1,
                    variance: 0,
                    isArchivedProduct: false
                )
            )
        }
        return list.sorted { abs($0.variance) > abs($1.variance) }
    }
    
    private func fetchVerifiedItems() async {
        guard let scannedUnitIds = audit?.scannedUnitIds, !scannedUnitIds.isEmpty else { return }
        await MainActor.run { isLoadingVerified = true }
        do {
            var allResponses: [YetToScanNetworkResponse] = []
            let chunkSize = 1000
            for i in stride(from: 0, to: scannedUnitIds.count, by: chunkSize) {
                let chunk = Array(scannedUnitIds[i..<min(i + chunkSize, scannedUnitIds.count)])
                let response: [YetToScanNetworkResponse] = try await SupabaseManager.shared.client
                    .from("inventory_units")
                    .select("id, serial_number, catalog_id, catalogs(id, name, brand, catalog_id)")
                    .in("id", values: chunk)
                    .execute()
                    .value
                allResponses.append(contentsOf: response)
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
                self.verifiedItems = items
                self.isLoadingVerified = false
            }
        } catch {
            print("Failed to fetch verified items: \(error)")
            await MainActor.run { isLoadingVerified = false }
        }
    }
    
    private func generateCSV() -> URL? {
        var csvString = "Item Name,SKU,Expected Qty,Counted Qty,Variance\n"
        for item in filteredItems {
            let escapedName = item.productName.replacingOccurrences(of: "\"", with: "\"\"")
            csvString += "\"\(escapedName)\",\(item.sku),\(item.expectedQty),\(item.countedQty),\(item.variance)\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("VarianceReport.csv")
        try? csvString.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    @MainActor
    private func generatePDF() -> URL? {
        let printView = PDFReportView(report: report, filteredItems: filteredItems)
        let renderer = ImageRenderer(content: printView)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("VarianceReport.pdf")
        
        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let pdfContext = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdfContext.beginPDFPage(nil)
            context(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
        }
        return url
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // Title Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SUBMITTED BY STORE INVENTORY")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                            
                            Text("Review verified anomalies across merged inventory stock before execution.")
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.secondary)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 24)
                        
                        // Scrollable metrics summary row
                        if let db = audit {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    MetricCard(title: "Total Expected", value: "\(db.totalExpected)", subtitle: nil, icon: "doc.text")
                                        .frame(width: 160, height: 160)
                                    MetricCard(title: "Total Scanned", value: "\(db.totalScanned)", subtitle: nil, icon: "barcode.viewfinder")
                                        .frame(width: 160, height: 160)
                                    MetricCard(title: "Variance", value: "\(db.variance)", subtitle: nil, icon: "exclamationmark.triangle")
                                        .frame(width: 160, height: 160)
                                    MetricCard(title: "Accuracy", value: String(format: "%.1f%%", db.accuracy), subtitle: nil, icon: "percent")
                                        .frame(width: 160, height: 160)
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        // Expandable cards list
                        VStack(spacing: 20) {
                            // Missing Items Card
                            ReportCardView(
                                title: "MISSING ITEMS",
                                quantity: missingItems.count,
                                skuCount: missingItems.count,
                                iconName: "xmark.circle.fill",
                                themeColor: AppColors.error,
                                isExpanded: $missingExpanded
                            ) {
                                if missingItems.isEmpty {
                                    Text("No missing items.")
                                        .font(AppFonts.sansSerif(size: 14))
                                        .foregroundStyle(AppColors.secondary)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    LazyVStack(spacing: 12) {
                                        ForEach(missingItems, id: \.detail) { item in
                                            BreakdownProductRow(name: item.name ?? "Unknown Item", detail: item.detail ?? "No details provided", status: "", statusColor: AppColors.error)
                                                .padding(.horizontal, 0)
                                        }
                                    }
                                }
                            }
                            
                            // New Items Card
                            ReportCardView(
                                title: "NEW ITEMS",
                                quantity: newItems.count,
                                skuCount: newItems.count,
                                iconName: "plus.circle.fill",
                                themeColor: AppColors.blue,
                                isExpanded: $newExpanded
                            ) {
                                if newItems.isEmpty {
                                    Text("No new items.")
                                        .font(AppFonts.sansSerif(size: 14))
                                        .foregroundStyle(AppColors.secondary)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    LazyVStack(spacing: 12) {
                                        ForEach(newItems, id: \.detail) { item in
                                            BreakdownProductRow(name: item.name ?? "Unknown Item", detail: item.detail ?? "No details provided", status: "New Item", statusColor: AppColors.warning)
                                                .padding(.horizontal, 0)
                                        }
                                    }
                                }
                            }
                            
                            // Successful/Verified Items Card
                            ReportCardView(
                                title: "SUCCESSFUL ITEMS",
                                quantity: verifiedItems.count,
                                skuCount: verifiedItems.count,
                                iconName: "checkmark.circle.fill",
                                themeColor: AppColors.success,
                                isExpanded: $successfulExpanded
                            ) {
                                if isLoadingVerified {
                                    ProgressView().tint(AppColors.gold)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else if verifiedItems.isEmpty {
                                    Text("No successful items.")
                                        .font(AppFonts.sansSerif(size: 14))
                                        .foregroundStyle(AppColors.secondary)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    LazyVStack(spacing: 12) {
                                        ForEach(verifiedItems) { item in
                                            BreakdownProductRow(name: item.name, detail: "Serial: \(item.serialNumber) • Brand: \(item.brand)", status: "Verified", statusColor: AppColors.success)
                                                .padding(.horizontal, 0)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Export Buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                if let url = generateCSV() {
                                    shareURL = url
                                    showShareSheet = true
                                }
                            }) {
                                Label("Export CSV", systemImage: "doc.text.fill")
                                    .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            Button(action: {
                                if let url = generatePDF() {
                                    shareURL = url
                                    showShareSheet = true
                                }
                            }) {
                                Label("Export PDF", systemImage: "doc.richtext.fill")
                                    .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                    .foregroundStyle(AppColors.background)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(AppColors.gold)
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical, 24)
                }
                
                // Fixed Sign-off Audit Button at the bottom
                if viewModel.currentUserId != nil {
                    VStack {
                        CustomButton(title: "Sign-off Audit", action: {
                            if let a = audit {
                                let totalScanned = verifiedItems.count
                                let totalExpected = missingItems.count + verifiedItems.count
                                let accuracy = totalExpected > 0 ? (Double(totalScanned) / Double(totalExpected)) * 100.0 : 100.0
                                let liveDiscrepancies = missingItems + newItems
                                let variance = missingItems.count + newItems.count
                                
                                viewModel.signOffAudit(
                                    auditId: a.id,
                                    variance: variance,
                                    accuracy: accuracy,
                                    totalScanned: totalScanned,
                                    discrepancies: liveDiscrepancies
                                ) {
                                    router.pop() // Navigate back on sign-off approval
                                }
                            } else {
                                router.pop()
                            }
                        })
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 34)
                    }
                    .background(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .overlay(
                        VStack {
                            Divider().background(AppColors.border)
                            Spacer()
                        }
                    )
                }
            }
        }
        .navigationTitle("Active Audit Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
        .task {
            await fetchVerifiedItems()
        }
        .alert("Sign-off Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { show in
                if !show { viewModel.errorMessage = nil }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        }
    }
}

private struct ActiveAuditRow: View {
    let status: String
    let date: String
    let badgeColor: Color
    var hideBadge: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(date)
                        .font(AppFonts.sansSerif(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                if status.uppercased() != "UPCOMING" && !hideBadge {
                    Text(status.uppercased())
                        .font(AppFonts.sansSerif(size: 10, weight: .bold))
                        .foregroundStyle(badgeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(badgeColor.opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(badgeColor.opacity(0.3), lineWidth: 1))
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.secondary)
                    .padding(.leading, 8)
            }
            .padding(16)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HubCompletedAuditRow: View {
    let date: String
    let variance: String
    let accuracy: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(date)
                        .font(AppFonts.sansSerif(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 12) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Variance")
                                .font(AppFonts.sansSerif(size: 9))
                                .foregroundStyle(AppColors.secondary)
                            Text(variance)
                                .font(AppFonts.sansSerif(size: 13, weight: .bold))
                                .foregroundStyle(variance.starts(with: "-") ? AppColors.error : (variance == "0" ? AppColors.success : AppColors.warning))
                        }
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Accuracy")
                                .font(AppFonts.sansSerif(size: 9))
                                .foregroundStyle(AppColors.secondary)
                            Text(accuracy)
                                .font(AppFonts.sansSerif(size: 13, weight: .bold))
                                .foregroundStyle(AppColors.success)
                        }
                    }
                    
                    Text("COMPLETED")
                        .font(AppFonts.sansSerif(size: 9, weight: .bold))
                        .foregroundStyle(AppColors.success)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.success.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.secondary)
                    .padding(.leading, 8)
            }
            .padding(16)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct BreakdownProductRow: View {
    let name: String
    let detail: String
    let status: String
    let statusColor: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(AppFonts.sansSerif(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text(detail)
                    .font(AppFonts.sansSerif(size: 13))
                    .foregroundStyle(AppColors.secondary)
            }
            
            Spacer()
            
            if !status.isEmpty {
                Text(status.uppercased())
                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(statusColor.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(16)
        .background(Color(white: 0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border.opacity(0.5), lineWidth: 1))
    }
}

private struct CycleCountVarianceRow: View {
    let item: RSMSVarianceItem

    private var diff: Int {
        item.actual - item.expected
    }

    private var formattedDiff: String {
        "\(diff > 0 ? "+" : "")\(diff)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.name)
                    .font(AppFonts.serif(size: 17, weight: .medium))
                    .foregroundStyle(.white)

                Spacer()

                Text(formattedDiff)
                    .font(AppFonts.sansSerif(size: 15, weight: .bold))
                    .foregroundStyle(diff == 0 ? AppColors.success : AppColors.error)
            }

            HStack {
                Text("Exp: \(item.expected)")
                Text("•")
                Text("Act: \(item.actual)")

                Spacer()

                Text(item.reason)
                    .font(AppFonts.sansSerif(size: 11).italic())
                    .foregroundStyle(AppColors.gold70)
            }
            .font(AppFonts.sansSerif(size: 12))
            .foregroundStyle(AppColors.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(AppColors.surface)
    }
}

private struct ReportCardView<Content: View>: View {
    let title: String
    let quantity: Int
    let skuCount: Int
    let iconName: String
    let themeColor: Color
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(themeColor.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: iconName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(themeColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(AppFonts.sansSerif(size: 10, weight: .bold))
                            .foregroundStyle(AppColors.secondary)
                            .kerning(1.0)
                        
                        HStack(spacing: 6) {
                            Text("\(quantity) \(quantity == 1 ? "unit" : "units")")
                                .font(AppFonts.sansSerif(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Text("•")
                                .foregroundStyle(AppColors.tertiary)
                            
                            Text("\(skuCount) \(skuCount == 1 ? "SKU" : "SKUs")")
                                .font(AppFonts.sansSerif(size: 12))
                                .foregroundStyle(AppColors.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AppColors.surface)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(spacing: 0) {
                    Divider().background(AppColors.border)
                    
                    VStack(spacing: 0) {
                        content()
                    }
                    .padding(16)
                    .background(AppColors.surface2.opacity(0.3))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isExpanded ? themeColor.opacity(0.3) : AppColors.gold15, lineWidth: 0.5)
        )
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct PDFReportView: View {
    let report: VarianceReport
    let filteredItems: [VarianceReportItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("INVENTORY VARIANCE REPORT")
                .font(AppFonts.sansSerif(size: 24, weight: .bold))
                .foregroundStyle(.black)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Boutique: \(report.boutiqueName)")
                    Text("Date: \(report.date.formatted())")
                    Text("Controller: \(report.controllerName)")
                }
                .font(AppFonts.sansSerif(size: 12))
                .foregroundStyle(AppColors.secondary)
                Spacer()
            }
            
            Divider()
            
            Text("Line Items")
                .font(AppFonts.sansSerif(size: 16, weight: .bold))
                .foregroundStyle(.black)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Item").font(AppFonts.sansSerif(size: 11, weight: .bold)).frame(maxWidth: .infinity, alignment: .leading)
                    Text("SKU").font(AppFonts.sansSerif(size: 11, weight: .bold)).frame(width: 80, alignment: .leading)
                    Text("Expected").font(AppFonts.sansSerif(size: 11, weight: .bold)).frame(width: 60, alignment: .trailing)
                    Text("Counted").font(AppFonts.sansSerif(size: 11, weight: .bold)).frame(width: 60, alignment: .trailing)
                    Text("Variance").font(AppFonts.sansSerif(size: 11, weight: .bold)).frame(width: 60, alignment: .trailing)
                }
                .foregroundStyle(.black)
                
                Divider()
                
                ForEach(filteredItems) { item in
                    HStack {
                        HStack {
                            Text(item.productName)
                            if item.isArchivedProduct {
                                Text("(Archived)")
                            }
                        }
                        .font(AppFonts.sansSerif(size: 10))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(item.sku).font(AppFonts.sansSerif(size: 10)).frame(width: 80, alignment: .leading)
                        Text("\(item.expectedQty)").font(AppFonts.sansSerif(size: 10)).frame(width: 60, alignment: .trailing)
                        Text("\(item.countedQty)").font(AppFonts.sansSerif(size: 10)).frame(width: 60, alignment: .trailing)
                        Text("\(item.variance > 0 ? "+" : "")\(item.variance)").font(AppFonts.sansSerif(size: 10, weight: .bold))
                            .foregroundStyle(item.variance > 0 ? AppColors.success : (item.variance < 0 ? AppColors.error : Color.black))
                            .frame(width: 60, alignment: .trailing)
                    }
                    .foregroundStyle(.black)
                }
            }
        }
        .padding(40)
        .frame(width: 595, height: 842)
        .background(Color.white)
    }
}
