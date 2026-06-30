//
//  BMEndlessAisleRequestsView.swift
//  luxury
//
//  Created by Nalinish Ranjan on 26/05/26.
//

import SwiftUI

public struct BMEndlessAisleRequestsView: View {
    @State private var viewModel = EndlessAisleViewModel.shared
    @State private var sentRequestIDs: Set<UUID> = []
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        requestSection(
                            title: "OUTGOING ESCALATIONS",
                            emptyText: "No local Endless Aisle escalations need review.",
                            requests: viewModel.outgoingManagerRequests
                        ) { request in
                            OutgoingRequestCard(
                                request: request,
                                viewModel: viewModel,
                                isSent: sentRequestIDs.contains(request.id),
                                onSent: {
                                    sentRequestIDs.insert(request.id)
                                }
                            )
                        }
                        
                        requestSection(
                            title: "INCOMING BOUTIQUE REQUESTS",
                            emptyText: "No other boutiques are requesting assistance.",
                            requests: viewModel.incomingManagerRequests
                        ) { request in
                            incomingCard(for: request)
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(AppFonts.sansSerif(size: 12, weight: .semibold))
                                .foregroundStyle(AppColors.error)
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            viewModel.loadRequests()
            await viewModel.startObservingRequests()
        }
        .onDisappear {
            Task {
                await viewModel.stopObservingRequests()
            }
        }
    }
    
    private var header: some View {
        CustomHeader(
            title: "Endless Aisle Approvals",
            showBackButton: true,
            backAction: { dismiss() },
            trailingIcon: "arrow.clockwise",
            trailingAction: { viewModel.loadRequests() },
            isInline: true
        )
    }
    
    @ViewBuilder
    private func requestSection<Content: View>(title: String, emptyText: String, requests: [EndlessAisle.SourcingRequest], @ViewBuilder content: @escaping (EndlessAisle.SourcingRequest) -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                .foregroundStyle(AppColors.secondary)
                .kerning(1.5)
                .padding(.horizontal, 24)
            
            if requests.isEmpty {
                HStack {
                    Spacer()
                    Text(emptyText)
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(AppColors.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 24)
                    Spacer()
                }
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
            } else {
                VStack(spacing: 12) {
                    ForEach(requests, content: content)
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private func incomingCard(for request: EndlessAisle.SourcingRequest) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            requestHeader(request, badge: "Action Needed", status: .warning)
            
            Text("\(request.destinationStore) is requesting this item from your boutique.")
                .font(AppFonts.sansSerif(size: 12))
                .foregroundStyle(AppColors.secondary)
            
            Button(action: { viewModel.approveSourceManager(requestId: request.id) }) {
                actionLabel("Reserve Unit for Dispatch", color: AppColors.gold)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSaving)
        }
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
    }
    
    private func requestHeader(_ request: EndlessAisle.SourcingRequest, badge: LocalizedStringKey, status: BadgeStatus) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(request.item.name)
                    .font(AppFonts.serif(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.text)
                Text("SKU \(request.item.sku)")
                    .font(AppFonts.sansSerif(size: 12))
                    .foregroundStyle(AppColors.secondary)
            }
            Spacer()
            StatusBadge(text: badge, status: status)
        }
    }
    
    private func actionLabel(_ title: String, color: Color) -> some View {
        Text(title)
            .font(AppFonts.sansSerif(size: 13, weight: .semibold))
            .foregroundStyle(AppColors.background)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct OutgoingRequestCard: View {
    let request: EndlessAisle.SourcingRequest
    let viewModel: EndlessAisleViewModel
    let isSent: Bool
    let onSent: @MainActor () -> Void
    
    @State private var sourceOptions: [EndlessAisle.BoutiqueStock] = []
    @State private var selectedSource: EndlessAisle.BoutiqueStock?
    @State private var isLoadingOptions = true
    @State private var isSending = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            requestHeader(request, badge: isSent ? "Sent" : "Needs Review", status: isSent ? .success : .pending)
            
            Text("Requested by local inventory control for \(request.destinationStore).")
                .font(AppFonts.sansSerif(size: 12))
                .foregroundStyle(AppColors.secondary)
            
            if isSent {
                Text("Request sent to the source boutique manager.")
                    .font(AppFonts.sansSerif(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.success)
            } else if isLoadingOptions {
                ProgressView()
                    .tint(AppColors.gold)
            } else if sourceOptions.isEmpty {
                Text("No boutiques currently have an available serial-numbered unit.")
                    .font(AppFonts.sansSerif(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.error)
            } else {
                Menu {
                    ForEach(sourceOptions) { source in
                        Button("\(source.name), \(source.city) · \(source.quantity)") {
                            selectedSource = source
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedSource.map { "\($0.name), \($0.city)" } ?? "Select source boutique")
                            .font(AppFonts.sansSerif(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.text)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(AppFonts.sansSerif(size: 12, weight: .bold))
                            .foregroundStyle(AppColors.gold)
                    }
                    .padding(12)
                    .background(AppColors.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button(action: {
                    guard let source = selectedSource ?? sourceOptions.first else { return }
                    isSending = true
                    Task {
                        do {
                            try await viewModel.approveRequesterManager(request: request, sourceBoutique: source)
                            await MainActor.run {
                                onSent()
                                isSending = false
                            }
                        } catch {
                            await MainActor.run {
                                isSending = false
                            }
                        }
                    }
                }) {
                    actionLabel("Send Request", color: AppColors.gold)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSaving || isSending)
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
        .task(id: request.id) {
            guard !isSent else {
                return
            }
            await MainActor.run {
                isLoadingOptions = true
            }
            let fetchedOptions = await viewModel.availableSourceBoutiques(for: request)
            await MainActor.run {
                sourceOptions = fetchedOptions
                isLoadingOptions = false
            }
        }
    }
    
    private func requestHeader(_ request: EndlessAisle.SourcingRequest, badge: LocalizedStringKey, status: BadgeStatus) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(request.item.name)
                    .font(AppFonts.serif(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.text)
                Text("SKU \(request.item.sku)")
                    .font(AppFonts.sansSerif(size: 12))
                    .foregroundStyle(AppColors.secondary)
            }
            Spacer()
            StatusBadge(text: badge, status: status)
        }
    }
    
    private func actionLabel(_ title: String, color: Color) -> some View {
        Text(title)
            .font(AppFonts.sansSerif(size: 13, weight: .semibold))
            .foregroundStyle(AppColors.background)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    BMEndlessAisleRequestsView()
}
