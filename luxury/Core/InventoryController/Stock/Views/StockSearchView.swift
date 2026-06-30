//
//  StockSearchView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct StockSearchView: View {
    @State private var viewModel = StockSearchViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Stock Search", showBackButton: true, backAction: { dismiss() }, isInline: true)
                
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppColors.tertiary)
                    
                    TextField("Search by SKU, Brand, or Name", text: $viewModel.searchText)
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(AppColors.text)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(viewModel.filteredItems) { item in
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.brand.uppercased())
                                        .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                        .foregroundStyle(AppColors.gold)
                                        .kerning(1)
                                    
                                    Text(item.name)
                                        .font(AppFonts.serif(size: 17, weight: .medium))
                                        .foregroundStyle(AppColors.text)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text("\(item.qty)")
                                        .font(AppFonts.serif(size: 20, weight: .bold))
                                        .foregroundStyle(item.qty == 0 ? AppColors.error : .white)
                                    
                                    HStack(spacing: 4) {
                                        if item.rfid {
                                            Image(systemName: "antenna.radiowaves.left.and.right")
                                                .font(AppFonts.sansSerif(size: 10))
                                                .foregroundStyle(AppColors.success)
                                        }
                                        
                                        if item.alert {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .font(AppFonts.sansSerif(size: 10))
                                                .foregroundStyle(AppColors.error)
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .background(AppColors.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationTitle("Stock Search")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.fetchItems()
        }
    }
}
