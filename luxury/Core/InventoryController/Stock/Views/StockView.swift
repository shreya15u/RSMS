//
//  StockView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct StockView: View {
    @Environment(Router.self) private var router
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(StockViewModel.self) private var viewModel
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Stock")
                        .font(AppFonts.serif(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()

                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .background(AppColors.background)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible())], spacing: 16) {
                            Button(action: {
                                router.push(ICRoute.stockSearch)
                            }) {
                                MetricCard(title: "Total SKU", value: viewModel.totalItems, subtitle: "Tap to Search", icon: "magnifyingglass")
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                router.push(ICRoute.barcodeScan)
                            }) {
                                MetricCard(title: "Scan", value: "Scan", subtitle: "Barcode Lookup", icon: "barcode.viewfinder")
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                router.push(ICRoute.alerts)
                            }) {
                                MetricCard(title: "Pending Alerts", value: "\(viewModel.alerts.count)", subtitle: "Action Required", icon: "bell.badge")
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                router.push(ICRoute.sfsOrders)
                            }) {
                                MetricCard(title: "SFS Orders", value: viewModel.sfsOrdersCount, subtitle: "Fulfillment Hub", icon: "shippingbox")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        
                        HStack(spacing: 12) {
                            CustomOutlineButton(title: "Endless Aisle", icon: AnyView(Image(systemName: "square.grid.3x3.fill")), action: {
                                router.push(ICRoute.endlessAisleSelection)
                            })
                            
                            CustomOutlineButton(title: "Repair Queue", icon: AnyView(Image(systemName: "wrench.and.screwdriver")), action: {
                                router.push(ICRoute.repairQueue)
                            })
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("LIVE INVENTORY ALERTS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                ForEach(viewModel.alerts) { alert in
                                    Button(action: {
                                        router.push(ICRoute.stockDetail(alert))
                                    }) {
                                        HStack(spacing: 16) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(alert.itemName)
                                                    .font(AppFonts.serif(size: 17, weight: .medium))
                                                    .foregroundStyle(AppColors.text)
                                                Text(alert.sku)
                                                    .font(AppFonts.sansSerif(size: 12))
                                                    .foregroundStyle(AppColors.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: 6) {
                                                StatusBadge(text: alert.currentQty == 0 ? LocalizedStringKey("Out of Stock") : LocalizedStringKey("\(alert.currentQty) Left"), status: alert.status)
                                            }
                                        }
                                        .padding(16)
                                        .background(AppColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                .refreshable {
                    viewModel.fetchInventoryStats()
                    viewModel.fetchSFSCount()
                }
            }
        }
        .task {
            viewModel.fetchInventoryStats()
            viewModel.fetchSFSCount()
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.fetchInventoryStats()
            viewModel.fetchSFSCount()
        }

    }
}

#Preview {
    StockView()
        .environment(Router())
        .environment(AppCoordinator())
        .environment(StockViewModel())
}
