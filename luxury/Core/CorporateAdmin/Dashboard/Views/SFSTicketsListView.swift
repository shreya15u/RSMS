//
//  SFSTicketsListView.swift
//  luxury
//
//  Created by AutoAgent on 03/06/26.
//

import SwiftUI

struct SFSTicketsListView: View {
    @Environment(Router.self) private var router
    let tickets: [PurchasedItemEntity]
    var onSelectTicket: ((PurchasedItemEntity) -> Void)?
    
    @State private var searchText = ""
    
    var filteredTickets: [PurchasedItemEntity] {
        if searchText.isEmpty {
            return tickets
        } else {
            return tickets.filter { ticket in
                let idMatch = ticket.id.uuidString.localizedCaseInsensitiveContains(searchText)
                let nameMatch = ticket.productName?.localizedCaseInsensitiveContains(searchText) ?? false
                let transactionMatch = ticket.transactionId.localizedCaseInsensitiveContains(searchText)
                return idMatch || nameMatch || transactionMatch
            }
        }
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header & Custom Search
                CustomHeader(title: "SFS Tickets", showBackButton: true, backAction: { router.pop() }, isInline: true)
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.secondary)
                            .font(.system(size: 16, weight: .medium))
                        
                        TextField("Search Tickets", text: $searchText)
                            .font(AppFonts.sansSerif(size: 16))
                            .foregroundStyle(.white)
                            .tint(AppColors.gold)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppColors.tertiary)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 1))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if filteredTickets.isEmpty {
                            Text("No SFS tickets found.")
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.tertiary)
                                .padding(.horizontal, 24)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredTickets) { item in
                                    Button(action: {
                                        if let onSelectTicket = onSelectTicket {
                                            onSelectTicket(item)
                                        } else {
                                            router.push(CARoute.sfsTicketDetail(item))
                                        }
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.productName ?? "Premium Timepiece")
                                                    .font(AppFonts.serif(size: 17, weight: .medium))
                                                    .foregroundStyle(.white)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.8)
                                                Text("Order ID: \(item.id.uuidString.prefix(8).uppercased())")
                                                    .font(AppFonts.sansSerif(size: 12))
                                                    .foregroundStyle(AppColors.secondary)
                                            }
                                            Spacer()
                                            
                                            let displayStatus = item.status.lowercased() == "ready to pick" ? "Ready" : item.status.capitalized
                                            let statusString = item.status.lowercased()
                                            let statusType: BadgeStatus = (statusString == "ready to pick" || statusString == "delivered") ? .success :
                                                                          (statusString == "secured") ? .neutral :
                                                                          (statusString == "pending") ? .pending : .warning
                                            
                                            StatusBadge(text: LocalizedStringKey(displayStatus), status: statusType)
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(AppColors.tertiary)
                                                .padding(.leading, 8)
                                        }
                                        .padding(18)
                                        .background(AppColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppColors.gold15, lineWidth: 0.5))
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }
}
