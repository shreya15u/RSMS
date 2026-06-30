//
//  DashboardView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct DashboardView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(Router.self) private var router
    @State private var viewModel = DashboardViewModel()


    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text(viewModel.boutiqueName)
                        .font(AppFonts.serif(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .background(AppColors.background)

                if viewModel.isOffline {
                    HStack(spacing: 10) {
                        Image(systemName: "wifi.slash")
                            .font(AppFonts.sansSerif(size: 12))
                            .foregroundStyle(AppColors.error)
                        Text("Offline · Last synced \(viewModel.lastSyncedText)")
                            .font(AppFonts.sansSerif(size: 12))
                            .foregroundStyle(AppColors.error)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(AppColors.error.opacity(0.08))
                }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {

                        VStack(alignment: .leading, spacing: 16) {
                            Text("TODAY'S PERFORMANCE")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)

                            SalesTargetCard(
                                actual:             viewModel.todaySales,
                                target:             viewModel.salesTarget,
                                actualProgress:     viewModel.salesProgress,
                                pacingProgress:     viewModel.pacingProgress,
                                projectedSales:     viewModel.projectedSales,
                                pacingStatus:       viewModel.pacingStatus,
                                isTargetConfigured: viewModel.isTargetConfigured
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        if viewModel.pendingAuditsCount > 0 {
                            Button(action: {
                                router.push(BMRoute.cycleCountSignoff)
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "exclamationmark.shield.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(AppColors.background)
                                        .frame(width: 40, height: 40)
                                        .background(AppColors.gold)
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Inventory Audit Pending Review")
                                            .font(AppFonts.serif(size: 16, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text("\(viewModel.pendingAuditsCount) count submitted and awaiting sign-off.")
                                            .font(AppFonts.sansSerif(size: 12))
                                            .foregroundStyle(AppColors.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(AppColors.gold)
                                }
                                .padding(16)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(AppColors.gold.opacity(0.4), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 24)
                            .padding(.bottom, 4)
                        }

                        HStack(spacing: 10) {
                            CustomOutlineButton(
                                title: "After Sales Tickets",
                                icon: AnyView(Image(systemName: "arrow.uturn.backward.circle")),
                                action: { router.push(BMRoute.astQueue) }
                            )
                            CustomOutlineButton(
                                title: "Write-Off",
                                icon: AnyView(Image(systemName: "exclamationmark.triangle")),
                                action: { router.push(BMRoute.writeOffApproval) }
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)

                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("APPOINTMENTS")
                                    .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1.5)
                                Spacer()
                                if !viewModel.pendingAppointments.isEmpty {
                                    StatusBadge(text: LocalizedStringKey("\(viewModel.pendingAppointments.count) Pending"), status: .warning)
                                }
                            }
                            .padding(.horizontal, 24)

                            if viewModel.pendingAppointments.isEmpty && viewModel.appointments.isEmpty {
                                Text("No appointments found")
                                    .font(AppFonts.sansSerif(size: 13))
                                    .foregroundStyle(AppColors.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.pendingAppointments) { appointment in
                                        Button(action: {
                                            router.push(BMRoute.appointmentDetail(appointment))
                                        }) {
                                            HStack(spacing: 12) {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(appointment.formattedTime)
                                                        .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                                        .foregroundStyle(AppColors.gold)
                                                    Text(appointment.displayAppointmentType.uppercased())
                                                        .font(AppFonts.sansSerif(size: 8, weight: .bold))
                                                        .foregroundStyle(AppColors.tertiary)
                                                }
                                                .frame(width: 65, alignment: .leading)
                                                
                                                VStack(alignment: .leading, spacing: 6) {
                                                    Text(appointment.client?.name ?? "Unknown Client")
                                                        .font(AppFonts.serif(size: 17, weight: .medium))
                                                        .foregroundStyle(AppColors.text)
                                                        .lineLimit(1)
                                                        .minimumScaleFactor(0.8)
                                                    
                                                    Text("Unassigned")
                                                        .font(AppFonts.sansSerif(size: 10, weight: .semibold))
                                                        .foregroundStyle(AppColors.warning)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 3)
                                                        .background(AppColors.warning.opacity(0.15))
                                                        .clipShape(Capsule())
                                                }
                                                
                                                Spacer(minLength: 8)
                                                
                                                Text("Review")
                                                    .font(AppFonts.sansSerif(size: 12, weight: .bold))
                                                    .foregroundStyle(AppColors.background)
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 8)
                                                    .background(AppColors.gold)
                                                    .clipShape(Capsule())
                                            }
                                            .padding(.vertical, 16)
                                            .padding(.horizontal, 16)
                                            .background(AppColors.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(AppColors.gold15, lineWidth: 0.5)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    ForEach(viewModel.appointments) { appointment in
                                        Button(action: {
                                            router.presentFullScreen(BMRoute.appointmentDetail(appointment))
                                        }) {
                                            HStack(spacing: 16) {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(appointment.formattedTime)
                                                        .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                                        .foregroundStyle(AppColors.gold)
                                                    Text(appointment.displayAppointmentType.uppercased())
                                                        .font(AppFonts.sansSerif(size: 8, weight: .bold))
                                                        .foregroundStyle(AppColors.tertiary)
                                                }
                                                .frame(width: 70, alignment: .leading)
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(appointment.client?.name ?? "Unknown Client")
                                                        .font(AppFonts.serif(size: 17, weight: .medium))
                                                        .foregroundStyle(AppColors.text)
                                                    Text("Advisor: \(viewModel.advisorName(for: appointment.assignedTo))")
                                                        .font(AppFonts.sansSerif(size: 12))
                                                        .foregroundStyle(AppColors.secondary)
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(AppFonts.sansSerif(size: 12))
                                                    .foregroundStyle(AppColors.tertiary)
                                            }
                                            .padding(20)
                                            .background(AppColors.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(AppColors.gold15, lineWidth: 0.5)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            Text("SFS FULFILLMENT STATUS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)

                            if viewModel.sfsFulfillments.isEmpty {
                                Text("No SFS fulfillments active")
                                    .font(AppFonts.sansSerif(size: 13))
                                    .foregroundStyle(AppColors.secondary)
                                    .padding(.horizontal, 24)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(Array(viewModel.sfsFulfillments.prefix(5))) { item in
                                        Button(action: {
                                            router.push(BMRoute.sfsTicketDetail(item))
                                        }) {
                                            HStack(spacing: 16) {
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
                                                    .stroke(AppColors.gold15, lineWidth: 0.5)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    
                                    if viewModel.sfsFulfillments.count > 5 {
                                        Button(action: {
                                            router.push(BMRoute.sfsTicketsList(viewModel.sfsFulfillments))
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
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                .refreshable {
                    await viewModel.refreshAll()
                }
                .task {
                    viewModel.startRealTimeUpdates()
                }
                .onDisappear {
                    viewModel.stopRealTimeUpdates()
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("RefreshAppointments"))) { _ in
                    viewModel.fetchAppointments()
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environment(AppCoordinator())
            .environment(Router())
    }
}
