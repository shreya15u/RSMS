//
//  SATransactionListView.swift
//  luxury
//
//  Created by Nalinish Ranjan on 27/05/26.
//

import SwiftUI

struct SATransactionListView: View {
    @Environment(Router.self) private var router
    let transactions: [SATransactionEntity]
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { router.pop() }) {
                        ZStack {
                            Circle()
                                .fill(AppColors.surface2)
                                .frame(width: 44, height: 44)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                        }
                    }
                    Spacer()
                    Text("Transactions")
                        .font(AppFonts.sansSerif(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    // Invisible spacer for balance
                    Circle()
                        .frame(width: 44, height: 44)
                        .opacity(0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 16)
                
                if transactions.isEmpty {
                    Spacer()
                    Text("No transactions found.")
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(AppColors.secondary)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(transactions, id: \.id) { tx in
                                Button(action: {
                                    router.push(SARoute.transactionDetail(tx))
                                }) {
                                    TransactionCard(transaction: tx)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct TransactionCard: View {
    let transaction: SATransactionEntity
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.gold08)
                Text(String(transaction.client?.name.prefix(1) ?? "U").uppercased())
                    .font(AppFonts.serif(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.gold)
            }
            .frame(width: 46, height: 46)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.client?.name ?? "Unknown Client")
                    .font(AppFonts.sansSerif(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.text)
                
                if let date = transaction.dateOfTransaction {
                    Text(formatDate(date))
                        .font(AppFonts.sansSerif(size: 11))
                        .foregroundStyle(AppColors.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyManager.shared.format(amount: transaction.transactionAmount))
                    .font(AppFonts.serif(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.gold)
                
                Text(transaction.purpose.capitalized)
                    .font(AppFonts.sansSerif(size: 10))
                    .foregroundStyle(AppColors.secondary)
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
    }
}
