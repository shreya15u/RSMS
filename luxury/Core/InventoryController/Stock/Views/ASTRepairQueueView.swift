//
//  ASTRepairQueueView.swift
//  luxury
//
//  Created by AI on 2026-06-03.
//

import SwiftUI
import Supabase

struct ASTRepairQueueView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Router.self) private var router
    
    @State private var tickets: [ASTDetails] = []
    @State private var isLoading = true
    @State private var selectedFilter: String = "All"
    
    @State private var errorMessage: String? = nil
    
    let filters = ["All", "Approved", "In Progress", "Dispatched"]
    
    var filteredTickets: [ASTDetails] {
        if selectedFilter == "All" {
            return tickets
        }
        return tickets.filter { $0.status.lowercased() == selectedFilter.lowercased().replacingOccurrences(of: " ", with: "_") }
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Filter ScrollView
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filters, id: \.self) { filter in
                            Button(action: {
                                withAnimation {
                                    selectedFilter = filter
                                }
                            }) {
                                Text(filter)
                                    .font(AppFonts.sansSerif(size: 11, weight: selectedFilter == filter ? .medium : .light))
                                    .foregroundStyle(selectedFilter == filter ? AppColors.background : AppColors.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedFilter == filter ? AppColors.gold : Color.clear)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(selectedFilter == filter ? Color.clear : AppColors.gold15, lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(AppColors.gold)
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundStyle(AppColors.error)
                        Text("Error Loading Tickets")
                            .font(AppFonts.sansSerif(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                        Text(error)
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(AppColors.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    Spacer()
                } else if filteredTickets.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 40))
                            .foregroundStyle(AppColors.gold.opacity(0.5))
                        Text("No tickets in repair queue")
                            .font(AppFonts.sansSerif(size: 16))
                            .foregroundStyle(AppColors.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredTickets, id: \.id) { ticket in
                                Button(action: {
                                    router.push(ICRoute.astDetail(ticket))
                                }) {
                                    ICASTQueueRowView(ticket: ticket)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                    .refreshable {
                        fetchTickets()
                    }
                }
            }
        }
        .navigationTitle("Repair Queue")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            fetchTickets()
        }
    }
    
    private func fetchTickets() {
        Task {
            do {
                let fetched: [ASTDetails] = try await SupabaseManager.shared.client
                    .from("ast")
                    .select("*, catalogs(*), client(*)")
                    .or("status.eq.approved,status.eq.in_progress,status.eq.dispatched")
                    .execute()
                    .value
                
                await MainActor.run {
                    self.tickets = fetched
                    self.isLoading = false
                }
            } catch {
                print("Failed to fetch repair queue tickets: \(error)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

struct ICASTQueueRowView: View {
    let ticket: ASTDetails
    
    var statusText: String {
        switch ticket.status.lowercased() {
        case "approved": return "Approved"
        case "in_progress": return "In Progress"
        case "dispatched": return "Dispatched"
        default: return ticket.status.capitalized
        }
    }
    
    var badgeStatus: BadgeStatus {
        switch ticket.status.lowercased() {
        case "approved": return .neutral
        case "in_progress": return .warning
        case "dispatched": return .success
        default: return .pending
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(ticket.catalogs?.name ?? "Service Item")
                    .font(AppFonts.serif(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                Spacer()
                StatusBadge(text: LocalizedStringKey(statusText), status: badgeStatus)
            }
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 12))
                        Text(ticket.client?.name ?? "Unknown Client")
                    }
                    .font(AppFonts.sansSerif(size: 13))
                    .foregroundStyle(AppColors.secondary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "number")
                            .font(.system(size: 12))
                        Text(ticket.catalogs?.catalogId ?? "Unknown ID")
                    }
                    .font(AppFonts.sansSerif(size: 13))
                    .foregroundStyle(AppColors.secondary)
                    
                    if let issue = ticket.description, !issue.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 12))
                            Text(issue)
                        }
                        .font(AppFonts.sansSerif(size: 13))
                        .foregroundStyle(AppColors.gold)
                        .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.tertiary)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.gold.opacity(0.15), lineWidth: 1)
        )
    }
}
