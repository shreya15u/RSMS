//
//  POSView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct POSView: View {
    @Environment(Router.self) private var router
    @Environment(SalesAssociateAppState.self) private var saAppState
    @State private var viewModel = POSViewModel.shared
    @State private var showClientSheet = false
    @State private var showCampaignSheet = false
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Cart")
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        if let client = viewModel.selectedClient {
                            HStack(spacing: 7) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(AppColors.gold15)
                                        .frame(width: 22, height: 22)
                                    Text(String(client.name.prefix(2)).uppercased())
                                        .font(AppFonts.serif(size: 10, weight: .bold))
                                        .foregroundStyle(AppColors.gold)
                                }
                                Text(client.name)
                                    .font(AppFonts.sansSerif(size: 12, weight: .medium))
                                    .foregroundStyle(.white)
                                if let tier = client.tier {
                                    StatusBadge(text: LocalizedStringKey(tier), status: .success)
                                }
                                Spacer()
                                Button("Change") {
                                    showClientSheet = true
                                }
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.gold)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppColors.gold08)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(AppColors.gold15, lineWidth: 0.5))
                            .padding(.horizontal, 24)
                            .padding(.bottom, 18)
                        } else {
                            HStack(spacing: 7) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .foregroundStyle(AppColors.gold)
                                Text("Attach Client")
                                    .font(AppFonts.sansSerif(size: 12, weight: .medium))
                                    .foregroundStyle(AppColors.gold)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppColors.gold08)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(AppColors.gold15, lineWidth: 0.5))
                            .padding(.horizontal, 24)
                            .padding(.bottom, 18)
                            .onTapGesture {
                                showClientSheet = true
                            }
                        }
                        
                        HStack {
                            Text("ITEMS")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.8)
                            Spacer()
                            Button(action: {
                                saAppState.selectedTab = .selling
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("Add Product")
                                }
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.gold)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        
                        if viewModel.cartItems.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "cart")
                                    .font(AppFonts.sansSerif(size: 32))
                                    .foregroundStyle(AppColors.gold.opacity(0.5))
                                Text("Your cart is empty")
                                    .font(AppFonts.sansSerif(size: 14))
                                    .foregroundStyle(AppColors.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 10) {
                            ForEach(viewModel.cartItems) { item in
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(AppColors.surface2)
                                            .frame(width: 48, height: 48)
                                        
                                        ProductImageView(imageUrl: item.product.productImages?.first, size: 48)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.product.brand.uppercased())
                                            .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                            .foregroundStyle(AppColors.gold)
                                            .kerning(1)
                                        Text(item.product.name)
                                            .font(AppFonts.sansSerif(size: 12, weight: .medium))
                                            .foregroundStyle(.white)
                                        Text(viewModel.formatCurrency(Int(item.product.amount)))
                                            .font(AppFonts.serif(size: 15, weight: .semibold))
                                            .foregroundStyle(AppColors.gold)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        Button(action: { viewModel.decreaseQty(of: item.id) }) {
                                            Circle()
                                                .stroke(AppColors.gold15, lineWidth: 0.5)
                                                .background(AppColors.surface2)
                                                .frame(width: 26, height: 26)
                                                .overlay(Text("−").font(AppFonts.sansSerif(size: 14)).foregroundStyle(AppColors.secondary))
                                        }
                                        
                                        Text("\(item.qty)")
                                            .font(AppFonts.serif(size: 16, weight: .medium))
                                            .foregroundStyle(.white)
                                        
                                        Button(action: { viewModel.increaseQty(of: item.id) }) {
                                            Circle()
                                                .stroke(AppColors.gold15, lineWidth: 0.5)
                                                .background(AppColors.surface2)
                                                .frame(width: 26, height: 26)
                                                .overlay(Text("+").font(AppFonts.sansSerif(size: 14)).foregroundStyle(AppColors.secondary))
                                        }
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            if !viewModel.activeCampaigns.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("APPLY CAMPAIGN")
                                        .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                        .foregroundStyle(AppColors.secondary)
                                        .kerning(1.5)
                                    
                                    Button(action: { showCampaignSheet = true }) {
                                        HStack {
                                            if let applied = viewModel.appliedCampaign {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(applied.title)
                                                        .font(AppFonts.serif(size: 14, weight: .semibold))
                                                        .foregroundStyle(.white)
                                                    Text("\(applied.discountPercentage / 100, format: .percent.precision(.fractionLength(0))) OFF")
                                                        .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                                        .foregroundStyle(AppColors.gold)
                                                }
                                            } else {
                                                Text("Select Campaign")
                                                    .font(AppFonts.sansSerif(size: 13, weight: .medium))
                                                    .foregroundStyle(AppColors.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundStyle(AppColors.gold)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(AppColors.surface2)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(viewModel.appliedCampaign != nil ? AppColors.gold : AppColors.gold15, lineWidth: viewModel.appliedCampaign != nil ? 1 : 0.5))
                                    }
                                }
                                Divider().background(AppColors.gold15).padding(.vertical, 4)
                            }
                            
                            Toggle("Tax-free eligible client", isOn: $viewModel.taxFree)
                                .font(AppFonts.sansSerif(size: 12))
                                .foregroundStyle(AppColors.text)
                                .toggleStyle(LuxuryToggleStyle())
                                
                            Divider().background(AppColors.gold15).padding(.vertical, 4)
                            
                            Toggle("Gift Invoice (Hide Prices)", isOn: $viewModel.isGiftInvoice)
                                .font(AppFonts.sansSerif(size: 12))
                                .foregroundStyle(AppColors.text)
                                .toggleStyle(LuxuryToggleStyle())
                        }
                        .padding(14)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.gold15, lineWidth: 0.5))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)
                        
                        VStack(spacing: 10) {
                            PriceRow(label: "Subtotal", value: viewModel.formatCurrency(viewModel.subtotal))
                            if let campaign = viewModel.appliedCampaign, viewModel.campaignDiscountAmount > 0 {
                                PriceRow(label: "\(campaign.title) (\((campaign.discountPercentage / 100.0).formatted(.percent)))", value: "−\(viewModel.formatCurrency(viewModel.campaignDiscountAmount))")
                            }
                            PriceRow(label: viewModel.taxFree ? "GST" : "GST (\((0.03).formatted(.percent)))", value: "+\(viewModel.formatCurrency(viewModel.tax))")
                            
                            Divider().background(AppColors.gold15).padding(.vertical, 4)
                            
                            HStack {
                                Text("Total")
                                    .font(AppFonts.sansSerif(size: 15, weight: .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(viewModel.formatCurrency(viewModel.total))
                                    .font(AppFonts.serif(size: 22, weight: .bold))
                                    .foregroundStyle(AppColors.gold)
                            }
                        }
                        .padding(16)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                    }
                    .padding(.top, 14)
                }
                
                VStack(spacing: 0) {
                    Button(action: {
                        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                              let rootVC = scene.windows.first?.rootViewController else { return }
                        
                        Task {
                            let success = await viewModel.processPayment(presentingViewController: rootVC)
                            if success {
                                router.push(SARoute.receipt)
                            } else if let error = viewModel.paymentError {
                                router.push(SARoute.paymentFailed(error))
                            }
                        }
                    }) {
                        HStack(spacing: 10) {
                            if viewModel.isProcessingPayment {
                                ProgressView()
                                    .tint(AppColors.background)
                            } else {
                                Text("Checkout · \(viewModel.formatCurrency(viewModel.total))")
                                Image(systemName: "arrow.right")
                                    .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                            }
                        }
                        .font(AppFonts.sansSerif(size: 15, weight: .medium))
                        .foregroundStyle(AppColors.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.gold))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.cartItems.isEmpty || viewModel.isProcessingPayment)
                    .opacity(viewModel.cartItems.isEmpty || viewModel.isProcessingPayment ? 0.45 : 1)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .background(AppColors.background)
            }
        }
        .onAppear {
            viewModel.fetchProducts()
        }
        .sheet(isPresented: $showClientSheet) {
            ClientSelectionSheet { client in
                viewModel.attachClient(client)
            }
        }
        .sheet(isPresented: $showCampaignSheet) {
            CampaignSelectionSheet(
                activeCampaigns: viewModel.activeCampaigns,
                selectedCampaign: $viewModel.appliedCampaign
            )
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct PriceRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppFonts.sansSerif(size: 13))
                .foregroundStyle(AppColors.secondary)
            Spacer()
            Text(value)
                .font(AppFonts.serif(size: 13))
                .foregroundStyle(.white)
        }
    }
}

struct ProductImageView: View {
    let imageUrl: String?
    let size: CGFloat
    
    var body: some View {
        if let imgUrlStr = imageUrl, let url = URL(string: imgUrlStr) {
            CachedAsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView().scaleEffect(0.5)
                case .success(let image):
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                case .failure:
                    placeholder
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            placeholder
        }
    }
    
    private var placeholder: some View {
        Image(systemName: "circle.grid.cross")
            .font(AppFonts.sansSerif(size: 20))
            .foregroundStyle(AppColors.gold)
            .opacity(0.3)
    }
}
