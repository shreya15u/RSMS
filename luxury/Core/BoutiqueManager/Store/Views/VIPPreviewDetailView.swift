//
//  VIPPreviewDetailView.swift
//  luxury
//
//  Created by Nalinish Ranjan on 27/05/26.
//

import SwiftUI

struct VIPPreviewDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = StoreViewModel()
    @State private var event: StoreEvent
    @State private var showToast = false
    @State private var toastMessage = ""
    
    init(event: StoreEvent) {
        self._event = State(initialValue: event)
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Event Banner Card
                        eventBannerCard
                        
                        // RSVP Status Analytics
                        rsvpAnalyticsCard
                        
                        // Guest List Section
                        guestListSection
                        
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            
            // Toast Notification
            if showToast {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(AppColors.gold)
                        Text(toastMessage)
                            .font(AppFonts.sansSerif(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColors.surface2)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(AppColors.gold.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(radius: 6)
                    .padding(.bottom, 30)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("VIP Preview Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    // MARK: - Components
    
    private var eventBannerCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("VIP PREVIEW")
                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                    .foregroundStyle(AppColors.gold)
                    .kerning(1.5)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColors.gold15)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Spacer()
                
                Button(action: {
                    sendAllReminders()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                            .font(AppFonts.sansSerif(size: 9, weight: .bold))
                        Text("SEND REMINDERS")
                            .font(AppFonts.sansSerif(size: 9, weight: .bold))
                    }
                    .foregroundStyle(AppColors.gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.gold15)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppColors.gold.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            
            Text(event.title)
                .font(AppFonts.serif(size: 26, weight: .semibold))
                .foregroundStyle(.white)
            
            Divider()
                .background(AppColors.border)
            
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 16) {
                GridRow {
                    detailLabel(icon: "calendar", title: "DATE", value: event.date)
                    detailLabel(icon: "location.fill", title: "VENUE", value: event.venue ?? "VIP Salon")
                }
                
                GridRow {
                    detailLabel(icon: "sparkles", title: "FEATURED COLLECTION", value: event.featuredCollection ?? "High Jewelry")
                    detailLabel(icon: "person.badge.shield.checkmark.fill", title: "HOST ASSOCIATE", value: event.hostAssociate ?? "Sarah Connor")
                }
            }
        }
        .padding(24)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.gold15, lineWidth: 1)
        )
    }
    
    private func detailLabel(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(AppFonts.sansSerif(size: 16))
                .foregroundStyle(AppColors.gold)
                .frame(width: 24, height: 24)
                .background(AppColors.gold08)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.sansSerif(size: 9, weight: .bold))
                    .foregroundStyle(AppColors.secondary)
                    .kerning(1)
                
                Text(value)
                    .font(AppFonts.sansSerif(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var rsvpAnalyticsCard: some View {
        let guests = event.guests ?? []
        let total = guests.count
        let confirmed = guests.filter { $0.status == "Confirmed" }.count
        let declined = guests.filter { $0.status == "Declined" }.count
        let pending = guests.filter { $0.status == "No Response" }.count
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("RSVP ANALYTICS")
                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                .foregroundStyle(AppColors.secondary)
                .kerning(1.5)
            
            HStack(spacing: 20) {
                // Large number
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(confirmed)")
                        .font(AppFonts.serif(size: 36, weight: .bold))
                        .foregroundStyle(AppColors.success)
                    Text("CONFIRMED")
                        .font(AppFonts.sansSerif(size: 10, weight: .semibold))
                        .foregroundStyle(AppColors.secondary)
                }
                
                Spacer()
                
                // Details
                VStack(alignment: .trailing, spacing: 6) {
                    analyticRow(title: "Declined", count: declined, color: AppColors.error)
                    analyticRow(title: "No Response", count: pending, color: AppColors.warning)
                    analyticRow(title: "Total Invited", count: total, color: .white)
                }
            }
            .padding(20)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Visual progress bar
            if total > 0 {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        let confWidth = CGFloat(confirmed) / CGFloat(total) * geo.size.width
                        let decWidth = CGFloat(declined) / CGFloat(total) * geo.size.width
                        let pendWidth = CGFloat(pending) / CGFloat(total) * geo.size.width
                        
                        if confirmed > 0 {
                            Rectangle()
                                .fill(AppColors.success)
                                .frame(width: confWidth)
                        }
                        if declined > 0 {
                            Rectangle()
                                .fill(AppColors.error)
                                .frame(width: decWidth)
                        }
                        if pending > 0 {
                            Rectangle()
                                .fill(AppColors.warning)
                                .frame(width: pendWidth)
                        }
                    }
                }
                .frame(height: 6)
                .clipShape(Capsule())
                .background(AppColors.tertiary.opacity(0.3))
            }
        }
    }
    
    private func analyticRow(title: String, count: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(title)
                .font(AppFonts.sansSerif(size: 12))
                .foregroundStyle(AppColors.secondary)
            Text("\(count)")
                .font(AppFonts.sansSerif(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
    }
    
    private var guestListSection: some View {
        let guests = event.guests ?? []
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("GUEST LIST (\(guests.count))")
                    .font(AppFonts.sansSerif(size: 11, weight: .bold))
                    .foregroundStyle(AppColors.secondary)
                    .kerning(1.5)
                Spacer()
            }
            
            if guests.isEmpty {
                Text("No VIP guests invited yet.")
                    .font(AppFonts.sansSerif(size: 13))
                    .foregroundStyle(AppColors.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(spacing: 10) {
                    ForEach(guests) { guest in
                        HStack(spacing: 16) {
                            // Avatar Circle
                            Text(getInitials(name: guest.name))
                                .font(AppFonts.sansSerif(size: 12, weight: .semibold))
                                .foregroundStyle(AppColors.gold)
                                .frame(width: 38, height: 38)
                                .background(AppColors.gold08)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(AppColors.gold.opacity(0.3), lineWidth: 1))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(guest.name)
                                        .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                        .foregroundStyle(.white)
                                    
                                    // Tier badge
                                    Text(guest.tier)
                                        .font(AppFonts.sansSerif(size: 8, weight: .bold))
                                        .foregroundStyle(guest.tier == "Platinum" ? AppColors.success : AppColors.warning)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(guest.tier == "Platinum" ? AppColors.success.opacity(0.15) : AppColors.warning.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                
                                if guest.reminderSent {
                                    HStack(spacing: 4) {
                                        Image(systemName: "paperplane.fill")
                                            .font(AppFonts.sansSerif(size: 9))
                                            .foregroundStyle(AppColors.gold)
                                        Text("Reminder sent")
                                            .font(AppFonts.sansSerif(size: 10))
                                            .foregroundStyle(AppColors.gold)
                                    }
                                } else {
                                    Text("No reminders sent")
                                        .font(AppFonts.sansSerif(size: 10))
                                        .foregroundStyle(AppColors.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Status badge inside Menu dropdown picker
                            Menu {
                                Button(action: { updateGuestStatus(guestId: guest.id, status: "No Response") }) {
                                    HStack {
                                        Text("No Response")
                                        if guest.status == "No Response" {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                Button(action: { updateGuestStatus(guestId: guest.id, status: "Confirmed") }) {
                                    HStack {
                                        Text("Confirmed")
                                        if guest.status == "Confirmed" {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                Button(action: { updateGuestStatus(guestId: guest.id, status: "Declined") }) {
                                    HStack {
                                        Text("Declined")
                                        if guest.status == "Declined" {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            } label: {
                                statusBadge(status: guest.status)
                            }
                        }
                        .padding(14)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(guest.status == "Confirmed" ? AppColors.success.opacity(0.15) : Color.clear, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    private func statusBadge(status: String) -> some View {
        var bg = AppColors.tertiary.opacity(0.3)
        var fg = AppColors.secondary
        
        switch status {
        case "Confirmed":
            bg = AppColors.success.opacity(0.15)
            fg = AppColors.success
        case "Declined":
            bg = AppColors.error.opacity(0.15)
            fg = AppColors.error
        case "No Response":
            bg = AppColors.warning.opacity(0.15)
            fg = AppColors.warning
        default:
            break
        }
        
        return HStack(spacing: 4) {
            Text(status.uppercased())
            Image(systemName: "chevron.up.chevron.down")
                .font(AppFonts.sansSerif(size: 7, weight: .semibold))
        }
        .font(AppFonts.sansSerif(size: 9, weight: .bold))
        .foregroundStyle(fg)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func updateGuestStatus(guestId: UUID, status: String) {
        guard var guests = event.guests,
              let idx = guests.firstIndex(where: { $0.id == guestId }) else { return }
        
        guests[idx].status = status
        
        // Reset reminder status if status is no longer Confirmed
        if status != "Confirmed" {
            guests[idx].reminderSent = false
        }
        
        event.guests = guests
        event.rsvpCount = guests.filter { $0.status == "Confirmed" }.count
        
        viewModel.updateEvent(event)
    }
    
    private func sendAllReminders() {
        guard var guests = event.guests else { return }
        
        for idx in guests.indices {
            if guests[idx].status == "Confirmed" {
                guests[idx].reminderSent = true
            } else {
                guests[idx].reminderSent = false
            }
        }
        
        event.guests = guests
        event.remindersSent = true
        
        viewModel.updateEvent(event)
        
        toastMessage = "RSVP reminders sent via SMS & Email"
        withAnimation(.spring()) {
            showToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showToast = false
            }
        }
    }
    
    private func getInitials(name: String) -> String {
        let parts = name.components(separatedBy: " ")
        let firstInit = parts.first?.prefix(1) ?? ""
        let lastInit = parts.count > 1 ? (parts.last?.prefix(1) ?? "") : ""
        return "\(firstInit)\(lastInit)".uppercased()
    }
    
    private func formatDeadline(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy, h:mm a"
        return formatter.string(from: date)
    }
}
