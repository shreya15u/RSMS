//
//  CATransactionsListView.swift
//  luxury
//
//  Created by AutoAgent on 03/06/26.
//

import SwiftUI

struct CATransactionsListView: View {
    @Environment(Router.self) private var router
    let transactions: [SATransactionEntity]
    
    @State private var searchText = ""
    
    var filteredTransactions: [SATransactionEntity] {
        if searchText.isEmpty {
            return transactions
        } else {
            return transactions.filter {
                $0.id.uuidString.localizedCaseInsensitiveContains(searchText) ||
                ($0.client?.name.localizedCaseInsensitiveContains(searchText) == true)
            }
        }
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header & Custom Search
                VStack(spacing: 16) {
                    HStack {
                        Button(action: {
                            router.pop()
                        }) {
                            Image(systemName: "arrow.left")
                                .font(AppFonts.sansSerif(size: 20))
                                .foregroundStyle(.white)
                        }
                        .padding(.trailing, 8)
                        
                        Text("Transactions")
                            .font(AppFonts.serif(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.secondary)
                            .font(.system(size: 16, weight: .medium))
                        
                        TextField("Search Transactions", text: $searchText)
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
                }
                .padding(.bottom, 24)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if filteredTransactions.isEmpty {
                            Text("No transactions found.")
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.tertiary)
                                .padding(.horizontal, 24)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredTransactions) { tx in
                                    Button(action: {
                                        router.push(CARoute.transactionDetail(tx))
                                    }) {
                                        HStack(spacing: 16) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Txn #\(tx.id.uuidString.prefix(8).uppercased())")
                                                    .font(AppFonts.serif(size: 17, weight: .medium))
                                                    .foregroundStyle(.white)
                                                
                                                if let date = tx.dateOfTransaction {
                                                    Text(date.formatted(date: .abbreviated, time: .shortened))
                                                        .font(AppFonts.sansSerif(size: 12))
                                                        .foregroundStyle(AppColors.secondary)
                                                }
                                            }
                                            Spacer()
                                            Text(CurrencyManager.shared.format(amount: tx.transactionAmount))
                                                .font(AppFonts.sansSerif(size: 15, weight: .semibold))
                                                .foregroundStyle(AppColors.gold)
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(AppColors.tertiary)
                                        }
                                        .padding(16)
                                        .background(AppColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 1))
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
