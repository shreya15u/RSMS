//
//  GlobalAnalyticsView.swift
//  luxury
//
//  Created by Aditya Chauhan on 18/05/26.
//

import SwiftUI
import Charts

struct GlobalAnalyticsView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(Router.self) private var router
    @State private var viewModel = GlobalAnalyticsViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
                HStack {
                    Text("Global Overview")
                        .font(AppFonts.serif(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .background(AppColors.background)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible())], spacing: 16) {
                            ForEach(viewModel.kpis) { kpi in
                                if kpi.label == "Total Staff" {
                                    GlobalMetricCard(kpi: kpi)
                                        .onTapGesture {
                                            router.push(CARoute.staffList)
                                        }
                                } else if kpi.label == "Global Revenue" {
                                    GlobalMetricCard(kpi: kpi)
                                        .onTapGesture {
                                            router.push(CARoute.globalRevenue)
                                        }
                                } else if kpi.label == "Active Boutiques" {
                                    GlobalMetricCard(kpi: kpi)
                                        .onTapGesture {
                                            router.push(CARoute.activeBoutiques)
                                        }
                                } else {
                                    GlobalMetricCard(kpi: kpi)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("7-DAY REVENUE GLIMPSE (₹)")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                            
                            Chart {
                                ForEach(viewModel.revenueChartData) { data in
                                    BarMark(
                                        x: .value("Day", data.month),
                                        y: .value("Amount", data.amount)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [AppColors.gold, AppColors.gold.opacity(0.5)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .cornerRadius(6)
                                }
                            }
                            .frame(height: 180)
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
                                    AxisValueLabel()
                                        .font(AppFonts.sansSerif(size: 10))
                                        .foregroundStyle(AppColors.tertiary)
                                }
                            }
                            .chartXAxis {
                                AxisMarks { value in
                                    AxisValueLabel()
                                        .font(AppFonts.sansSerif(size: 10))
                                        .foregroundStyle(AppColors.tertiary)
                                }
                            }
                        }
                        .padding(24)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                        .padding(.horizontal, 24)
                        


                        VStack(alignment: .leading, spacing: 16) {
                            Text("SFS FULFILLMENT STATUS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)

                            if viewModel.sfsFulfillments.isEmpty {
                                Text("No SFS fulfillments active")
                                    .font(AppFonts.sansSerif(size: 13))
                                    .foregroundStyle(AppColors.secondary)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(Array(viewModel.sfsFulfillments.prefix(5))) { item in
                                        Button(action: {
                                            router.push(CARoute.sfsTicketDetail(item))
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
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                        }
                                    }
                                    
                                    if viewModel.sfsFulfillments.count > 5 {
                                        Button(action: {
                                            router.push(CARoute.sfsTicketsList(viewModel.sfsFulfillments))
                                        }) {
                                            Text("View All Tickets")
                                                .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                                                .foregroundStyle(AppColors.gold)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 16)
                                                .background(AppColors.surface)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 60)
                    }
                    .padding(.top, 20)
                }
                .refreshable {
                    viewModel.fetchData()
                }
            }
        .background(AppColors.background.ignoresSafeArea())
        .onAppear {
            viewModel.fetchData()
            viewModel.startFulfillmentPolling()
        }
        .onDisappear {
            viewModel.stopFulfillmentPolling()
        }
    }
}

struct GlobalMetricCard: View {
    let kpi: GlobalKPI
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: kpi.icon)
                    .font(AppFonts.sansSerif(size: 18))
                    .foregroundStyle(AppColors.gold)
                    .frame(height: 20)
                Spacer()
            }
            
            Spacer(minLength: 16)
            
            VStack(alignment: .leading, spacing: 4) {
                Group {
                    switch kpi.type {
                    case .string(let str):
                        Text(str)
                    case .currency(let val):
                        Text(CurrencyManager.shared.formatCompact(amount: val))
                    }
                }
                .font(AppFonts.serif(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                Text(kpi.label.uppercased())
                    .font(AppFonts.sansSerif(size: 9, weight: .bold))
                    .foregroundStyle(AppColors.secondary)
                    .kerning(1)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
    }
}
