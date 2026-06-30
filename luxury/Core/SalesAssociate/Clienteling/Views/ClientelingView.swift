//
//  ClientelingView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct ClientelingView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = ClientelingViewModel()
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                CustomHeader(title: "Clients")
            
            VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.tertiary)
                        
                        TextField("Search by name, phone, email…", text: $viewModel.searchText)
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(AppColors.text)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.gold15, lineWidth: 0.5)
                    )
                    
                    HStack(spacing: 6) {
                        ForEach(viewModel.stats) { stat in
                            let filterValue = stat.label == "Total" ? "All" : stat.label
                            let isSelected = viewModel.selectedFilter == filterValue
                            
                            VStack(spacing: 2) {
                                Text(stat.value)
                                    .font(AppFonts.serif(size: 20, weight: .medium))
                                    .foregroundStyle(isSelected ? AppColors.background : AppColors.text)
                                Text(stat.label)
                                    .font(AppFonts.sansSerif(size: 10))
                                    .foregroundStyle(isSelected ? AppColors.background.opacity(0.8) : AppColors.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? AppColors.gold : AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? Color.clear : AppColors.gold15, lineWidth: 0.5)
                            )
                            .onTapGesture {
                                withAnimation {
                                    viewModel.selectedFilter = filterValue
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    if viewModel.isLoading && viewModel.clients.isEmpty {
                        VStack {
                            Spacer()
                            ProgressView()
                                .tint(AppColors.gold)
                                .scaleEffect(1.2)
                                .padding(.top, 60)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 1) {
                            let clients = viewModel.filteredClients
                            ForEach(clients, id: \.id) { client in
                                Button(action: {
                                    router.push(SARoute.clientProfile(client))
                                }) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(AppColors.gold08)
                                                .frame(width: 40, height: 40)
                                            Text(client.initial)
                                                .font(AppFonts.serif(size: 13, weight: .bold))
                                                .foregroundStyle(AppColors.gold)
                                            
                                            if client.isHot {
                                                Circle()
                                                    .fill(Color(hex: 0xFF9F3F))
                                                    .frame(width: 8, height: 8)
                                                    .overlay(Circle().stroke(AppColors.background, lineWidth: 1.5))
                                                    .offset(x: 14, y: -14)
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack(spacing: 6) {
                                                Text(client.name)
                                                    .font(AppFonts.sansSerif(size: 13, weight: .medium))
                                                    .foregroundStyle(.white)
                                                StatusBadge(text: LocalizedStringKey(client.tier.rawValue), status: client.tier.badgeStatus)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(AppFonts.sansSerif(size: 12))
                                            .foregroundStyle(AppColors.tertiary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(AppColors.surface)
                                    .overlay(
                                        VStack {
                                            Spacer()
                                            if client.id != clients.last?.id {
                                                Divider().background(AppColors.gold08).padding(.horizontal, 14)
                                            }
                                        }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.gold15, lineWidth: 0.5)
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                    }
                }
                .refreshable {
                    await viewModel.loadClients()
                }
            }
            .background(AppColors.background.ignoresSafeArea())
            
            Menu {
                        Button(action: {
                            router.presentFullScreen(SARoute.newClient)
                        }) {
                            Label("New Client", systemImage: "person.badge.plus")
                        }
                        
                        Button(action: {
                            router.presentFullScreen(SARoute.createAppointment(nil))
                        }) {
                            Label("New Appointment", systemImage: "calendar.badge.plus")
                        }
                        
                        Button(action: {
                            router.push(SARoute.sfsHandover)
                        }) {
                            Label("SFS Handover", systemImage: "shippingbox.fill")
                        }
                        
                        Button(action: {
                            router.presentFullScreen(SARoute.remoteConsultation)
                        }) {
                            Label("Remote Consultation", systemImage: "video.fill")
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(AppColors.gold)
                                .frame(width: 48, height: 48)
                                .shadow(color: AppColors.gold.opacity(0.3), radius: 10, y: 4)
                            
                            Image(systemName: "plus")
                                .font(AppFonts.sansSerif(size: 20, weight: .bold))
                                .foregroundStyle(AppColors.background)
                        }
                        .contentShape(Circle())
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadClients()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshClients"))) { _ in
            Task {
                await viewModel.loadClients()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ClientDeleted"))) { notification in
            if let clientId = notification.userInfo?["clientId"] as? UUID {
                viewModel.removeClient(id: clientId)
            }
        }
    }
}
