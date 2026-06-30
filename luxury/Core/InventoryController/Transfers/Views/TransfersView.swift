//
//  TransfersView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct TransfersView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = TransfersViewModel()
    @State private var selectedFilter = 0
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Transfers")
                
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        summaryChip(title: "Incoming", value: incomingCount)
                        summaryChip(title: "Outgoing", value: outgoingCount)
                    }
                    
                    CustomButton(title: "New Transfer Request", icon: AnyView(Image(systemName: "plus.circle")), action: {
                        router.presentFullScreen(ICRoute.newTransfer)
                    })
                }
                .padding(24)
                
                Picker("Filter", selection: $selectedFilter) {
                    Text("Pending").tag(0)
                    Text("In Transit").tag(1)
                    Text("Completed").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(AppColors.gold)
                                .padding(.top, 24)
                        } else if sectionedTransfers().allSatisfy({ $0.items.isEmpty }) {
                            VStack(spacing: 16) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 48))
                                    .foregroundStyle(AppColors.secondary)
                                Text("No Transfer Activity")
                                    .font(AppFonts.serif(size: 18, weight: .medium))
                                    .foregroundStyle(.white)
                                Text("Incoming and outgoing stock movements will appear here as soon as they are created or updated.")
                                    .font(AppFonts.sansSerif(size: 13))
                                    .foregroundStyle(AppColors.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 36)
                            }
                            .padding(.top, 72)
                        } else {
                            ForEach(sectionedTransfers(), id: \.title) { section in
                                if !section.items.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text(section.title)
                                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                                .foregroundStyle(AppColors.secondary)
                                                .kerning(1.5)
                                            Spacer()
                                            Text("\(section.items.count)")
                                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                                .foregroundStyle(AppColors.gold)
                                        }
                                        .padding(.horizontal, 4)
                                        
                                        LazyVStack(spacing: 12) {
                                            ForEach(section.items) { item in
                                                Button(action: {
                                                    router.presentFullScreen(ICRoute.transferDetail(item.transfer))
                                                }) {
                                                    transferCard(for: item)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.top, 4)
                            .padding(.bottom, 24)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.fetchTransfers()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StockTransferUpdated"))) { _ in
            viewModel.fetchTransfers()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StockTransferReceived"))) { _ in
            viewModel.fetchTransfers()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StockTransferApproved"))) { _ in
            viewModel.fetchTransfers()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StockTransferRejected"))) { _ in
            viewModel.fetchTransfers()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EndlessAisleShipmentArrived"))) { _ in
            viewModel.fetchTransfers()
        }
        .onDisappear {
            viewModel.stopObservingLiveTransfers()
        }
    }
    
    private var incomingCount: Int {
        sectionedTransfers().first(where: { $0.title == "Incoming" })?.items.count ?? 0
    }
    
    private var outgoingCount: Int {
        sectionedTransfers().first(where: { $0.title == "Outgoing" })?.items.count ?? 0
    }
    
    private func sectionedTransfers() -> [TransferSection] {
        let transfers = viewModel.filteredTransfers(for: selectedFilter)
        let incoming = transfers.filter { $0.direction == .incoming }
        let outgoing = transfers.filter { $0.direction == .outgoing }
        return [
            TransferSection(title: "Incoming", items: incoming),
            TransferSection(title: "Outgoing", items: outgoing)
        ]
    }
    
    private func transferCard(for item: TransferBoardItem) -> some View {
        let transfer = item.transfer
        let directionColor: Color = item.direction == .incoming ? AppColors.success : AppColors.gold
        let directionIcon = item.direction == .incoming ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill"
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(transfer.reference)
                            .font(AppFonts.sansSerif(size: 12, weight: .bold))
                            .foregroundStyle(AppColors.gold)
                            .kerning(1.4)
                        if item.isLive {
                            StatusBadge(text: "Live", status: .warning)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: directionIcon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(directionColor)
                        Text(item.direction.rawValue)
                            .font(AppFonts.sansSerif(size: 11, weight: .bold))
                            .foregroundStyle(directionColor)
                            .kerning(1.2)
                    }
                }
                
                Spacer()
                
                StatusBadge(text: LocalizedStringKey(transfer.status), status: transfer.badgeStatus)
            }
            
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Source")
                        .font(AppFonts.sansSerif(size: 9, weight: .semibold))
                        .foregroundStyle(AppColors.secondary)
                        .textCase(.uppercase)
                    Text(transfer.source)
                        .font(AppFonts.serif(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "arrow.right")
                    .font(AppFonts.sansSerif(size: 12))
                    .foregroundStyle(AppColors.gold)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Destination")
                        .font(AppFonts.sansSerif(size: 9, weight: .semibold))
                        .foregroundStyle(AppColors.secondary)
                        .textCase(.uppercase)
                    Text(transfer.destination)
                        .font(AppFonts.serif(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            Divider().background(AppColors.border)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Items")
                        .font(AppFonts.sansSerif(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.secondary)
                        .kerning(1.2)
                    Spacer()
                    Text("\(transfer.itemCount) total")
                        .font(AppFonts.sansSerif(size: 11))
                        .foregroundStyle(AppColors.tertiary)
                }
                
                VStack(spacing: 8) {
                    ForEach(transfer.items.prefix(3)) { transferItem in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(transferItem.name)
                                    .font(AppFonts.sansSerif(size: 13, weight: .medium))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text(transferItem.sku)
                                    .font(AppFonts.sansSerif(size: 10))
                                    .foregroundStyle(AppColors.tertiary)
                            }
                            Spacer()
                            Text("×\(transferItem.qty)")
                                .font(AppFonts.serif(size: 16, weight: .semibold))
                                .foregroundStyle(directionColor)
                        }
                        .padding(.vertical, 2)
                    }
                    
                    if transfer.items.count > 3 {
                        Text("+\(transfer.items.count - 3) more")
                            .font(AppFonts.sansSerif(size: 10))
                            .foregroundStyle(AppColors.secondary)
                    }
                }
            }
        }
        .padding(18)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(item.direction == .incoming ? AppColors.gold15 : AppColors.border, lineWidth: 1)
        )
    }
    
    private func summaryChip(title: String, value: Int) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                .foregroundStyle(AppColors.secondary)
                .kerning(1.1)
            Spacer(minLength: 0)
            Text("\(value)")
                .font(AppFonts.serif(size: 16, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1))
    }
    
    private struct TransferSection {
        let title: String
        let items: [TransferBoardItem]
    }
}
