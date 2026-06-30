//
//  TransferApprovalView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//  Modified by Antigravity on 01/06/26.
//

import SwiftUI
import Foundation

struct TransferApprovalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Router.self) private var router
    
    @State private var selectedSegment = 0 // 0: Awaiting Action, 1: History
    @State private var searchText = ""
    @State private var selectedTransfer: TransferRequest? = nil
    @State private var showingNewTransfer = false
    @State private var transfers: [TransferRequest] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppColors.secondary)
                        .font(.system(size: 16))
                    
                    TextField("Search by reference, store...", text: $searchText)
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(.white)
                        .tint(AppColors.gold)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppColors.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                
                // Premium Segmented Control
                HStack(spacing: 0) {
                    Button(action: { selectedSegment = 0 }) {
                        VStack(spacing: 10) {
                            Text("AWAITING ACTION")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(selectedSegment == 0 ? AppColors.gold : AppColors.secondary)
                                .kerning(1.5)
                            Rectangle()
                                .fill(selectedSegment == 0 ? AppColors.gold : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button(action: { selectedSegment = 1 }) {
                        VStack(spacing: 10) {
                            Text("TRANSFER HISTORY")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(selectedSegment == 1 ? AppColors.gold : AppColors.secondary)
                                .kerning(1.5)
                            Rectangle()
                                .fill(selectedSegment == 1 ? AppColors.gold : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 8)
                .padding(.horizontal, 24)
                
                Divider()
                    .background(AppColors.border)
                    .padding(.top, -1)
                
                // Transfers List
                ScrollView(showsIndicators: false) {
                    let filtered = filteredTransfers()
                    
                    if isLoading {
                        ProgressView()
                            .tint(AppColors.gold)
                            .padding(.top, 32)
                    } else if let errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 44))
                                .foregroundStyle(AppColors.secondary)
                            Text("Unable to load transfers")
                                .font(AppFonts.serif(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                            Text(errorMessage)
                                .font(AppFonts.sansSerif(size: 13))
                                .foregroundStyle(AppColors.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 80)
                    } else if filtered.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: selectedSegment == 0 ? "checkmark.circle" : "shippingbox")
                                .font(.system(size: 48))
                                .foregroundStyle(AppColors.secondary)
                            Text(selectedSegment == 0 ? "No Pending Stock Transfers" : "No Transfer History Found")
                                .font(AppFonts.serif(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                            Text(selectedSegment == 0 ? "All inter-store inventory transfers have been fully resolved." : "Completed requests will be displayed here.")
                                .font(AppFonts.sansSerif(size: 13))
                                .foregroundStyle(AppColors.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 80)
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(filtered) { transfer in
                                Button(action: { selectedTransfer = transfer }) {
                                    VStack(alignment: .leading, spacing: 14) {
                                        HStack {
                                            Text(transfer.reference.isEmpty ? "UNNAMED" : transfer.reference)
                                                .font(AppFonts.sansSerif(size: 13, weight: .bold))
                                                .foregroundStyle(AppColors.gold)
                                                .kerning(1.5)
                                            Spacer()
                                            StatusBadge(text: LocalizedStringKey(transfer.status), status: transfer.badgeStatus)
                                        }
                                        
                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Source Store")
                                                    .font(AppFonts.sansSerif(size: 9, weight: .semibold))
                                                    .foregroundStyle(AppColors.secondary)
                                                    .textCase(.uppercase)
                                                Text(transfer.source)
                                                    .font(AppFonts.serif(size: 16, weight: .medium))
                                                    .foregroundStyle(.white)
                                                    .lineLimit(1)
                                            }
                                            
                                            Spacer()
                                            Image(systemName: "arrow.right")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.gold)
                                            Spacer()
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Destination Store")
                                                    .font(AppFonts.sansSerif(size: 9, weight: .semibold))
                                                    .foregroundStyle(AppColors.secondary)
                                                    .textCase(.uppercase)
                                                Text(transfer.destination)
                                                    .font(AppFonts.serif(size: 16, weight: .medium))
                                                    .foregroundStyle(.white)
                                                    .lineLimit(1)
                                            }
                                        }
                                        
                                        Divider().background(AppColors.border)
                                        
                                        HStack {
                                            Label("\(transfer.itemCount) items", systemImage: "shippingbox")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.secondary)
                                            Spacer()
                                            Text("View Details")
                                                .font(AppFonts.sansSerif(size: 12, weight: .semibold))
                                                .foregroundStyle(AppColors.gold)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(AppColors.gold)
                                        }
                                    }
                                    .padding(20)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.border, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Stock Transfers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(AppFonts.sansSerif(size: 20, weight: .semibold))
                            .foregroundStyle(AppColors.gold)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewTransfer = true
                    }) {
                        Image(systemName: "plus")
                            .font(AppFonts.sansSerif(size: 20, weight: .semibold))
                            .foregroundStyle(AppColors.gold)
                    }
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedTransfer != nil },
                set: { if !$0 { selectedTransfer = nil } }
            )) {
                if let transfer = selectedTransfer {
                    BMTransferDetailView(
                        transfer: transfer,
                        onApprove: {
                            approveTransfer(transfer)
                        },
                        onReject: {
                            rejectTransfer(transfer)
                        }
                    )
                }
            }
            .navigationDestination(isPresented: $showingNewTransfer) {
                NewTransferView()
            }
        }
        .task {
            await loadTransfers()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StockTransferUpdated"))) { _ in
            Task { await loadTransfers() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StockTransferReceived"))) { _ in
            Task { await loadTransfers() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StockTransferApproved"))) { _ in
            Task { await loadTransfers() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StockTransferRejected"))) { _ in
            Task { await loadTransfers() }
        }
    } // Closes NavigationStack
} // Closes body
    
    private func loadTransfers() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let fetched = try await StockTransferService.shared.fetchTransfers()
            await MainActor.run {
                self.transfers = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.transfers = []
                self.isLoading = false
            }
        }
    }
    
    private func filteredTransfers() -> [TransferRequest] {
        let isAwaitingSegment = selectedSegment == 0
        
        let filteredByStatus = transfers.filter { transfer in
            guard transfer.reference.hasPrefix("TR-") else { return false }
            let isPending = transfer.status.lowercased() == "submitted" || transfer.status.lowercased() == "pending approval"
            return isAwaitingSegment ? isPending : !isPending
        }
        
        if searchText.isEmpty {
            return filteredByStatus
        } else {
            let query = searchText.lowercased()
            return filteredByStatus.filter { transfer in
                transfer.reference.lowercased().contains(query) ||
                transfer.source.lowercased().contains(query) ||
                transfer.destination.lowercased().contains(query) ||
                transfer.items.contains(where: { $0.name.lowercased().contains(query) || $0.sku.lowercased().contains(query) })
            }
        }
    }
    
    private func approveTransfer(_ transfer: TransferRequest) {
        Task {
            do {
                _ = try await StockTransferService.shared.updateTransfer(
                    id: transfer.id,
                    status: "Approved",
                    badgeStatus: .success
                )
                
                SystemLogService.shared.logAction(
                    category: .inventory,
                    severity: .info,
                    message: "Stock Transfer \(transfer.reference) approved by Boutique Manager.",
                    boutiqueName: transfer.source
                )
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("StockTransferApproved"),
                    object: nil,
                    userInfo: ["reference": transfer.reference]
                )
                
                await loadTransfers()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func rejectTransfer(_ transfer: TransferRequest) {
        Task {
            do {
                _ = try await StockTransferService.shared.updateTransfer(
                    id: transfer.id,
                    status: "Rejected",
                    badgeStatus: .error
                )
                
                SystemLogService.shared.logAction(
                    category: .inventory,
                    severity: .warning,
                    message: "Stock Transfer \(transfer.reference) rejected by Boutique Manager.",
                    boutiqueName: transfer.source
                )
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("StockTransferRejected"),
                    object: nil,
                    userInfo: ["reference": transfer.reference]
                )
                
                await loadTransfers()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - BMTransferDetailView

struct BMTransferDetailView: View {
    let transfer: TransferRequest
    var onApprove: () -> Void
    var onReject: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var showApproveConfirm = false
    @State private var showRejectConfirm = false
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TRANSFER DETAIL")
                            .font(AppFonts.sansSerif(size: 10, weight: .bold))
                            .foregroundStyle(AppColors.gold)
                            .kerning(1.5)
                        Text(transfer.reference.isEmpty ? "UNNAMED" : transfer.reference)
                            .font(AppFonts.serif(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                Divider().background(AppColors.border)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Status and Route Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("STATUS")
                                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1)
                                Spacer()
                                StatusBadge(text: LocalizedStringKey(transfer.status), status: transfer.badgeStatus)
                            }
                            
                            Divider().background(AppColors.border)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    Circle().fill(AppColors.secondary).frame(width: 8, height: 8)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("FROM (SOURCE)")
                                            .font(AppFonts.sansSerif(size: 9, weight: .bold))
                                            .foregroundStyle(AppColors.secondary)
                                        Text(transfer.source)
                                            .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                            .foregroundStyle(AppColors.text)
                                    }
                                }
                                
                                Rectangle().fill(AppColors.border).frame(width: 1, height: 20).padding(.leading, 3.5)
                                
                                HStack(spacing: 12) {
                                    Circle().fill(AppColors.gold).frame(width: 8, height: 8)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("TO (DESTINATION)")
                                            .font(AppFonts.sansSerif(size: 9, weight: .bold))
                                            .foregroundStyle(AppColors.secondary)
                                        Text(transfer.destination)
                                            .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                            .foregroundStyle(AppColors.text)
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                        
                        // Items List Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ITEMS REQUESTED (\(transfer.items.count))")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .textCase(.uppercase)
                                .kerning(1)
                            
                            ForEach(transfer.items) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name)
                                            .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                                            .foregroundStyle(AppColors.text)
                                        Text(item.sku)
                                            .font(AppFonts.sansSerif(size: 11))
                                            .foregroundStyle(AppColors.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("Qty: \(item.qty)")
                                            .font(AppFonts.sansSerif(size: 13, weight: .bold))
                                            .foregroundStyle(AppColors.gold)
                                        Text("Avail: \(item.availableQty)")
                                            .font(AppFonts.sansSerif(size: 10))
                                            .foregroundStyle(item.availableQty >= item.qty ? AppColors.success : AppColors.error)
                                    }
                                }
                                .padding(.vertical, 8)
                                
                                if item.id != transfer.items.last?.id {
                                    Divider().background(AppColors.border)
                                }
                            }
                        }
                        .padding(20)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                        
                        // Action Buttons if pending
                        let isPending = transfer.status.lowercased() == "submitted" || transfer.status.lowercased() == "pending approval"
                        if isPending {
                            VStack(spacing: 12) {
                                Button(action: { showApproveConfirm = true }) {
                                    Text("Approve Transfer")
                                        .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                        .foregroundStyle(AppColors.background)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(AppColors.gold)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                Button(action: { showRejectConfirm = true }) {
                                    Text("Reject Request")
                                        .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                        .foregroundStyle(AppColors.error)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(AppColors.error.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(AppColors.error.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                            .padding(.top, 16)
                        }
                    }
                    .padding(24)
                }
            }
        }
        .alert("Confirm Approval", isPresented: $showApproveConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Approve", role: .none) {
                onApprove()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to approve this stock transfer? This will update the inventory levels at the source and destination boutiques.")
        }
        .alert("Confirm Rejection", isPresented: $showRejectConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reject", role: .destructive) {
                onReject()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to reject this stock transfer request?")
        }
        .navigationTitle("Transfers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
