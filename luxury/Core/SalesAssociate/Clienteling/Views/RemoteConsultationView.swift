//
//  RemoteConsultationView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct RemoteConsultationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RemoteConsultationViewModel()
    
    @State private var clientToConfirm: Client?
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                FlowHeader(title: "Remote Consultation", dismiss: dismiss)
                
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
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    if viewModel.clients.isEmpty {
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
                                    clientToConfirm = client
                                }) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(AppColors.gold08)
                                                .frame(width: 40, height: 40)
                                            Text(client.initial)
                                                .font(AppFonts.serif(size: 13, weight: .bold))
                                                .foregroundStyle(AppColors.gold)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack(spacing: 6) {
                                                Text(client.name)
                                                    .font(AppFonts.sansSerif(size: 13, weight: .medium))
                                                    .foregroundStyle(.white)
                                                StatusBadge(text: LocalizedStringKey(client.tier.rawValue), status: client.tier.badgeStatus)
                                            }
                                            if let email = client.email {
                                                Text(email)
                                                    .font(AppFonts.sansSerif(size: 11))
                                                    .foregroundStyle(AppColors.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "video.fill")
                                            .font(AppFonts.sansSerif(size: 14))
                                            .foregroundStyle(AppColors.gold)
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
            }
            .background(AppColors.background.ignoresSafeArea())
            
            if viewModel.isGeneratingLink {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView().tint(AppColors.gold).scaleEffect(1.5)
                        Text("Creating secure video room...")
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(.white)
                    }
                    .padding(30)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 1))
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadClients()
        }
        .alert("Start Consultation", isPresented: Binding(
            get: { clientToConfirm != nil },
            set: { if !$0 { clientToConfirm = nil } }
        )) {
            Button("Cancel", role: .cancel) { }
            Button("Start") {
                if let client = clientToConfirm {
                    Task {
                        await viewModel.startConsultation(for: client)
                    }
                }
            }
        } message: {
            if let client = clientToConfirm {
                Text("Send a video consultation link to \(client.name) at \(client.email ?? "their email")?")
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: viewModel.didSucceed) { oldValue, newValue in
            if newValue {
                dismiss()
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { viewModel.generatedUrl != nil },
            set: { if !$0 { viewModel.generatedUrl = nil } }
        )) {
            if let url = viewModel.generatedUrl {
                ZStack(alignment: .topTrailing) {
                    JitsiWebView(url: url)
                        .ignoresSafeArea()
                    
                    Button(action: { viewModel.generatedUrl = nil }) {
                        Text("Close")
                            .font(AppFonts.sansSerif(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.text)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding()
                }
            }
        }
    }
}

private struct FlowHeader: View {
    let title: String
    let dismiss: DismissAction
    
    var body: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(AppFonts.sansSerif(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(AppColors.surface)
                    .clipShape(Circle())
            }
            Spacer()
            Text(title)
                .font(AppFonts.serif(size: 20, weight: .medium))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(AppColors.surface)
    }
}
