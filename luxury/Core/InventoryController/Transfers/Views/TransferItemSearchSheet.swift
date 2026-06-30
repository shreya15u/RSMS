//
//  TransferItemSearchSheet.swift
//  luxury
//

import SwiftUI

struct TransferItemSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = TransferItemSearchViewModel()
    
    let onItemSelected: (CatalogEntity) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.secondary)
                        TextField("Search by name or barcode...", text: $viewModel.searchText)
                            .font(AppFonts.sansSerif(size: 16))
                            .foregroundStyle(.white)
                            .autocorrectionDisabled(true)
                            .submitLabel(.search)
                            .onSubmit {
                                viewModel.search()
                            }
                            .onChange(of: viewModel.searchText) { _, _ in
                                viewModel.search()
                            }
                    }
                    .padding()
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView().tint(AppColors.gold)
                        Spacer()
                    } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                        Spacer()
                        Text("No items found.")
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(AppColors.secondary)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.searchResults) { item in
                                    let stock = 0 // Temporarily 0 for now
                                    
                                    Button(action: {
                                        onItemSelected(item)
                                        dismiss()
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.name)
                                                    .font(AppFonts.sansSerif(size: 16, weight: .medium))
                                                    .foregroundStyle(.white)
                                                Text(item.barCode)
                                                    .font(AppFonts.sansSerif(size: 12))
                                                    .foregroundStyle(AppColors.secondary)
                                            }
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text("\(stock)")
                                                    .font(AppFonts.serif(size: 18, weight: .bold))
                                                    .foregroundStyle(stock > 0 ? AppColors.success : AppColors.error)
                                                Text("Available")
                                                    .font(AppFonts.sansSerif(size: 10))
                                                    .foregroundStyle(AppColors.tertiary)
                                            }
                                        }
                                        .padding()
                                        .background(AppColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.gold)
                }
            }
            .onAppear {
                viewModel.search()
            }
        }
    }
}
