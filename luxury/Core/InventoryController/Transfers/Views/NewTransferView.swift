//
//  NewTransferView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct NewTransferView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = NewTransferViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmationAlert = false
    
    private func submitTransfer() {
        Task {
            let result = await viewModel.confirmTransfer()
            switch result {
            case .success:
                await MainActor.run {
                    dismiss()
                }
            case .failure(let error):
                await MainActor.run {
                    viewModel.alertTitle = "Transfer Blocked"
                    viewModel.alertMessage = error.localizedDescription
                    viewModel.showAlert = true
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "New Transfer", showBackButton: true, backAction: { dismiss() }, isInline: true)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("SOURCE")
                                        .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                        .foregroundStyle(AppColors.secondary)
                                        .kerning(1.5)
                                    
                                    HStack {
                                        Text(viewModel.sourceStore?.name ?? "Resolving Source...")
                                            .font(AppFonts.serif(size: 18, weight: .medium))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                Image(systemName: "building.2")
                                    .foregroundStyle(AppColors.gold)
                            }
                            .padding()
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Image(systemName: "arrow.down")
                                .foregroundStyle(AppColors.tertiary)
                                .padding(.vertical, 4)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("DESTINATION")
                                        .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                        .foregroundStyle(AppColors.secondary)
                                        .kerning(1.5)
                                    
                                    Menu {
                                        Button("Select Destination") { viewModel.destinationStore = nil }
                                        ForEach(viewModel.availableBoutiques) { boutique in
                                            Button(boutique.name) { viewModel.destinationStore = boutique }
                                        }
                                    } label: {
                                        HStack {
                                            Text(viewModel.destinationStore?.name ?? "Select Destination")
                                                .font(AppFonts.serif(size: 18, weight: .medium))
                                                .foregroundStyle(viewModel.destinationStore == nil ? AppColors.tertiary : .white)
                                                .lineLimit(1)
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(AppFonts.sansSerif(size: 10))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                    }
                                }
                                Spacer()
                                Image(systemName: "building.2")
                                    .foregroundStyle(AppColors.gold)
                            }
                            .padding()
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("BARCODE SCAN SIMULATOR")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            if viewModel.destinationStore == nil {
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(AppColors.gold)
                                    Text("Please select a destination boutique to unlock scanner.")
                                        .font(AppFonts.sansSerif(size: 13))
                                        .foregroundStyle(AppColors.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                .padding(.horizontal, 24)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.availableProducts) { product in
                                            Button(action: {
                                                Task {
                                                    let result = await viewModel.scanItem(barcode: product.barCode)
                                                    switch result {
                                                    case .success:
                                                        break
                                                    case .failure(let error):
                                                        await MainActor.run {
                                                            viewModel.alertTitle = "Scan Warning"
                                                            viewModel.alertMessage = error.localizedDescription
                                                            viewModel.showAlert = true
                                                        }
                                                    }
                                                }
                                            }) {
                                                HStack {
                                                    Image(systemName: "barcode.viewfinder")
                                                        .font(AppFonts.sansSerif(size: 14))
                                                    Text("Scan \(product.name)")
                                                        .font(AppFonts.sansSerif(size: 13, weight: .semibold))
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(AppColors.surface2)
                                                .foregroundStyle(AppColors.gold)
                                                .clipShape(Capsule())
                                                .overlay(Capsule().stroke(AppColors.gold50, lineWidth: 0.5))
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("ITEMS TO TRANSFER")
                                    .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1.5)
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(spacing: 1) {
                                ForEach(viewModel.items) { item in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 16) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name)
                                                    .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                                    .foregroundStyle(.white)
                                                Text(item.sku)
                                                    .font(AppFonts.sansSerif(size: 11))
                                                    .foregroundStyle(AppColors.tertiary)
                                            }
                                            
                                            Spacer()
                                            
                                            HStack(spacing: 16) {
                                                Button(action: {
                                                    viewModel.decrementQty(for: item.id)
                                                }) {
                                                    Image(systemName: "minus.circle")
                                                        .foregroundStyle(AppColors.secondary)
                                                }
                                                
                                                Text("\(item.qty)")
                                                    .font(AppFonts.serif(size: 18, weight: .bold))
                                                    .foregroundStyle(AppColors.gold)
                                                    .frame(width: 24)
                                                
                                                Button(action: {
                                                    viewModel.incrementQty(for: item.id)
                                                }) {
                                                    Image(systemName: "plus.circle.fill")
                                                        .foregroundStyle(AppColors.gold)
                                                }
                                            }
                                        }
                                        
                                        if item.qty > item.availableQty {
                                            Text("Insufficient stock. Only \(item.availableQty) units available.")
                                                .font(AppFonts.sansSerif(size: 12, weight: .medium))
                                                .foregroundStyle(AppColors.error)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                    .background(AppColors.surface)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                
                VStack {
                    HStack(spacing: 10) {
                        CustomButton(title: "Submit Request", action: {
                            if viewModel.destinationStore == nil {
                                viewModel.alertTitle = "Destination Required"
                                viewModel.alertMessage = "Please select a destination store."
                                viewModel.showAlert = true
                                return
                            }
                            if viewModel.items.isEmpty {
                                viewModel.alertTitle = "No Items"
                                viewModel.alertMessage = "Please scan or add at least one item to transfer."
                                viewModel.showAlert = true
                                return
                            }
                            if viewModel.hasStockError {
                                viewModel.alertTitle = "Insufficient Stock"
                                viewModel.alertMessage = "One or more items in the transfer exceed available stock levels. Please correct the quantities before submitting."
                                viewModel.showAlert = true
                                return
                            }
                            showConfirmationAlert = true
                        })
                        .disabled(viewModel.items.isEmpty)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
                .background(AppColors.background)
            }
        }
        .navigationTitle("New Transfer Request")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.fetchBoutiques()
            viewModel.fetchAvailableProducts()
        }
        .alert(
            viewModel.alertTitle,
            isPresented: Binding(
                get: { viewModel.showAlert },
                set: { viewModel.showAlert = $0 }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
        .alert(
            "Confirm Transfer Details",
            isPresented: $showConfirmationAlert
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm & Submit", role: .none) {
                submitTransfer()
            }
        } message: {
            if let source = viewModel.sourceStore?.name,
               let dest = viewModel.destinationStore?.name {
                Text("Please confirm the following transfer details before final submission:\n\n" +
                     "• Source: \(source)\n" +
                     "• Destination: \(dest)\n\n" +
                     "Items:\n" +
                     viewModel.items.map { "• \($0.name) (Qty: \($0.qty))" }.joined(separator: "\n"))
            } else {
                Text("Are you sure you want to submit this transfer request?")
            }
        }
    }
}
