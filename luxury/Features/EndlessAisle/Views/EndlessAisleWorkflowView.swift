//
//  EndlessAisleWorkflowView.swift
//  luxury
//
//  Created by Nalinish Ranjan on 26/05/26.
//

import SwiftUI

public struct EndlessAisleWorkflowView: View {
    @State private var viewModel = EndlessAisleViewModel.shared
    @State private var receiveDrafts: [UUID: String] = [:]
    @State private var receiveModes: [UUID: ReceiveInputMode] = [:]
    @State private var activeScannerRequest: EndlessAisle.SourcingRequest?
    @State private var scannerService = ScannerService()
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        dispatchSection
                        receiveSection

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
        }
        .sheet(item: $activeScannerRequest) { request in
            scannerSheet(for: request)
        }
    }
    
    private var header: some View {
        CustomHeader(
            title: "Endless Aisle",
            showBackButton: true,
            backAction: { dismiss() },
            trailingIcon: "arrow.clockwise",
            trailingAction: { viewModel.loadRequests() },
            isInline: true
        )
    }
    
    private var dispatchSection: some View {
        requestSection(
            title: "OUTGOING ENDLESS-AISLE",
            emptyText: "No approved source requests are waiting for dispatch.",
            requests: viewModel.sourceDispatchRequests
        ) { request in
            VStack(alignment: .leading, spacing: 14) {
                requestHeader(request, badge: request.status == .dispatched ? "In Transit" : "Ready", status: request.status == .dispatched ? .pending : .warning)
                Text("Prepare serial \(request.serialNumber ?? "reserved unit") for \(request.destinationStore).")
                    .font(AppFonts.sansSerif(size: 12))
                    .foregroundStyle(AppColors.secondary)
                
                if request.status == .pendingSourceDispatch {
                    Button(action: { viewModel.dispatchSourceRequest(request: request) }) {
                        actionLabel("Dispatch Item", color: AppColors.gold)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSaving)
                }
            }
            .padding(16)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
        }
    }
    
    private var receiveSection: some View {
        requestSection(
            title: "INCOMING ENDLESS-AISLE",
            emptyText: "No sourced items have arrived for this boutique.",
            requests: viewModel.destinationReceiveRequests
        ) { request in
            VStack(alignment: .leading, spacing: 14) {
                requestHeader(request, badge: "Arrived", status: .success)
                
                Picker("Input Mode", selection: receiveModeBinding(for: request)) {
                    Text("Manual").tag(ReceiveInputMode.manual)
                    Text("Scan").tag(ReceiveInputMode.scan)
                }
                .pickerStyle(.segmented)

                if receiveMode(for: request) == .manual {
                    TextField("Enter SKU or serial number", text: receiveDraftBinding(for: request))
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(AppColors.text)
                        .padding(12)
                        .background(AppColors.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled(true)

                    Button(action: {
                        submitReceivedStock(for: request)
                    }) {
                        actionLabel("Receive Into Inventory", color: AppColors.success)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSaving || receiveCode(for: request).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } else {
                    Text("Use the scanner to capture the SKU or serial number for this arrival.")
                        .font(AppFonts.sansSerif(size: 12))
                        .foregroundStyle(AppColors.secondary)

                    Button(action: {
                        activeScannerRequest = request
                    }) {
                        actionLabel("Scan SKU", color: AppColors.gold)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSaving)
                }
            }
            .padding(16)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
        }
    }
    
    @ViewBuilder
    private func requestSection<Content: View>(title: String, emptyText: String, requests: [EndlessAisle.SourcingRequest], @ViewBuilder content: @escaping (EndlessAisle.SourcingRequest) -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(title)
            
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
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(AppFonts.sansSerif(size: 10, weight: .bold))
            .foregroundStyle(AppColors.secondary)
            .kerning(1.5)
            .padding(.horizontal, 24)
    }
    
    private func requestHeader(_ request: EndlessAisle.SourcingRequest, badge: LocalizedStringKey, status: BadgeStatus) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(request.item.name)
                    .font(AppFonts.serif(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.text)
                Text("\(request.sourceStore) -> \(request.destinationStore)")
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
    
    private func receiveDraftBinding(for request: EndlessAisle.SourcingRequest) -> Binding<String> {
        Binding(
            get: { receiveDrafts[request.id, default: ""] },
            set: { receiveDrafts[request.id] = $0 }
        )
    }
    
    private func receiveModeBinding(for request: EndlessAisle.SourcingRequest) -> Binding<ReceiveInputMode> {
        Binding(
            get: { receiveModes[request.id] ?? .manual },
            set: { receiveModes[request.id] = $0 }
        )
    }
    
    private func receiveMode(for request: EndlessAisle.SourcingRequest) -> ReceiveInputMode {
        receiveModes[request.id] ?? .manual
    }
    
    private func receiveCode(for request: EndlessAisle.SourcingRequest) -> String {
        receiveDrafts[request.id, default: ""]
    }
    
    private func submitReceivedStock(for request: EndlessAisle.SourcingRequest) {
        let code = receiveCode(for: request).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        viewModel.receiveSourcedStock(request: request, scannedCode: code)
        receiveDrafts[request.id] = ""
    }
    
    @ViewBuilder
    private func scannerSheet(for request: EndlessAisle.SourcingRequest) -> some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Text("Scan SKU")
                        .font(AppFonts.serif(size: 22, weight: .semibold))
                        .foregroundStyle(AppColors.text)
                    Spacer()
                    Button(action: { activeScannerRequest = nil }) {
                        Image(systemName: "xmark")
                            .font(AppFonts.sansSerif(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.gold)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                QRScannerView(scannerService: scannerService)
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 24)
                
                Text("Point the camera at the SKU or serial number for \(request.item.name).")
                    .font(AppFonts.sansSerif(size: 13))
                    .foregroundStyle(AppColors.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                Button(action: {
                    activeScannerRequest = nil
                }) {
                    actionLabel("Close Scanner", color: AppColors.surface2)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            scannerService.resetDebounce()
            scannerService.onScannedCode = { code in
                Task { @MainActor in
                    viewModel.receiveSourcedStock(request: request, scannedCode: code)
                    receiveDrafts[request.id] = ""
                    activeScannerRequest = nil
                }
            }
        }
        .onDisappear {
            scannerService.onScannedCode = nil
        }
    }
}

private enum ReceiveInputMode: String, CaseIterable, Identifiable {
    case manual
    case scan
    
    var id: String { rawValue }
}

#Preview {
    EndlessAisleWorkflowView()
}
