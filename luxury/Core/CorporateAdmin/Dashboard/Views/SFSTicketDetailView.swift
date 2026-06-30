//
//  SFSTicketDetailView.swift
//  luxury
//
//  Created by AutoAgent on 03/06/26.
//

import SwiftUI

struct SFSTicketDetailView: View {
    let ticket: PurchasedItemEntity
    @Environment(Router.self) private var router
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Ticket Details", showBackButton: true, backAction: { router.pop() }, isInline: true)
                
                ScrollView {
                VStack(spacing: 24) {
                    // Header Status
                    VStack(spacing: 12) {
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(AppColors.gold)
                        
                        Text("SFS Ticket")
                            .font(AppFonts.serif(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        let displayStatus = ticket.status.lowercased() == "ready to pick" ? "Ready" : ticket.status.capitalized
                        let statusType: BadgeStatus = ticket.status.lowercased() == "ready to pick" ? .success :
                                                      ticket.status.lowercased() == "secured" ? .neutral : .warning
                        
                        StatusBadge(text: LocalizedStringKey(displayStatus), status: statusType)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 8)
                    
                    // Product Information Card
                    if ticket.productName != nil || ticket.productBrand != nil || ticket.productSku != nil {
                        CardSection(title: "Product Information", icon: "bag.fill") {
                            if let name = ticket.productName {
                                DetailRow(label: "Name", value: name)
                            }
                            if let brand = ticket.productBrand {
                                DetailRow(label: "Brand", value: brand)
                            }
                            if let sku = ticket.productSku {
                                DetailRow(label: "SKU", value: sku)
                            }
                            DetailRow(label: "Product ID", value: String(ticket.productId.uuidString.prefix(8).uppercased()))
                        }
                    }
                    
                    // Order Details Card
                    CardSection(title: "Order Details", icon: "doc.text.fill") {
                        DetailRow(label: "Order ID", value: String(ticket.id.uuidString.prefix(8).uppercased()))
                        DetailRow(label: "Transaction ID", value: String(ticket.transactionId.prefix(8).uppercased()))
                    }
                    
                    // Timeline Card
                    CardSection(title: "Timeline", icon: "calendar") {
                        DetailRow(label: "Reserved On", value: ticket.reservedDate.formatted(date: .abbreviated, time: .shortened))
                        
                        if let delivery = ticket.deliveryDate {
                            DetailRow(label: "Delivery Date", value: delivery.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct CardSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.gold)
                Text(title)
                    .font(AppFonts.sansSerif(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.gold)
            }
            .padding(.bottom, 4)
            
            VStack(spacing: 12) {
                content
            }
        }
        .padding(20)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 1))
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(AppFonts.sansSerif(size: 14))
                .foregroundStyle(AppColors.secondary)
            Spacer(minLength: 16)
            Text(value)
                .font(AppFonts.sansSerif(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
        }
        Divider().background(AppColors.gold15)
    }
}
