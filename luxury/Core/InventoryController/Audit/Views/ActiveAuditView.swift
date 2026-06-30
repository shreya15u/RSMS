//
//  ActiveAuditView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct ActiveAuditView: View {
    let audit: RSMSCycleCount
    @Environment(Router.self) private var router
    @State private var viewModel: ActiveAuditViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingBatchScanner = false
    @State private var tempScannedSerials: [String] = []
    @State private var showingSubmitAlert = false
    @State private var showingErrorAlert = false
    
    init(audit: RSMSCycleCount) {
        self.audit = audit
        self._viewModel = State(initialValue: ActiveAuditViewModel(audit: audit))
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
 
            VStack(spacing: 0) {
                CustomHeader(title: LocalizedStringKey(audit.title), showBackButton: true, backAction: { dismiss() })
 
                VStack(spacing: 8) {
                    HStack {
                        Text("Audit Progress")
                            .font(AppFonts.sansSerif(size: 11, weight: .bold))
                            .foregroundStyle(AppColors.secondary)
                        Spacer()
                        Text("\(viewModel.totalScanned)/\(viewModel.totalExpected) items")
                            .font(AppFonts.sansSerif(size: 11, weight: .bold))
                            .foregroundStyle(AppColors.gold)
                    }
 
                    ZStack(alignment: .leading) {
                        Capsule().fill(AppColors.surface).frame(height: 4)
                        if viewModel.totalExpected > 0 {
                            Capsule().fill(AppColors.gold)
                                .frame(width: min(300, 300 * viewModel.progress), height: 4)
                                .animation(.spring(), value: viewModel.progress)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
 
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
 
                        Text("SCANNED ITEMS")
                            .font(AppFonts.sansSerif(size: 11, weight: .bold))
                            .foregroundStyle(AppColors.tertiary)
                            .kerning(1.5)
                            .padding(.horizontal, 24)
                        
                        if viewModel.scannedItems.isEmpty {
                            Text("No items scanned yet")
                                .font(AppFonts.sansSerif(size: 13))
                                .foregroundStyle(AppColors.secondary)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                        } else {
                            VStack(spacing: 1) {
                                ForEach(viewModel.scannedItems) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.name)
                                                .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                                .foregroundStyle(item.ok ? .white : AppColors.error)
                                            Text(item.ok ? "MATCHED" : "UNEXPECTED SKU")
                                                .font(AppFonts.sansSerif(size: 9, weight: .bold))
                                                .foregroundStyle(item.ok ? AppColors.success : AppColors.error)
                                        }
                                        Spacer()
                                        Image(systemName: item.ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                            .foregroundStyle(item.ok ? AppColors.success : AppColors.error)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 14)
                                    .background(AppColors.surface)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 24)
                        }
 
                        if !viewModel.newlyAddedItems.isEmpty {
                            Text("NEW ITEMS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(Color.blue)
                                .kerning(1.5)
                                .padding(.top, 8)
                                .padding(.horizontal, 24)
 
                            VStack(spacing: 1) {
                                ForEach(viewModel.newlyAddedItems) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.name)
                                                .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                                .foregroundStyle(AppColors.secondary)
                                            Text("UNEXPECTED SKU")
                                                .font(AppFonts.sansSerif(size: 9, weight: .bold))
                                                .foregroundStyle(Color.blue)
                                        }
                                        Spacer()
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundStyle(Color.blue)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 14)
                                    .background(AppColors.surface)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 24)
                        }
 
                        if !viewModel.yetToScanItems.isEmpty {
                            Text("MISSING ITEMS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.error)
                                .kerning(1.5)
                                .padding(.top, 8)
                                .padding(.horizontal, 24)
 
                            VStack(spacing: 1) {
                                ForEach(viewModel.yetToScanItems) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.name)
                                                .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                                .foregroundStyle(AppColors.secondary)
                                            Text("NOT SCANNED")
                                                .font(AppFonts.sansSerif(size: 9, weight: .bold))
                                                .foregroundStyle(AppColors.error)
                                        }
                                        Spacer()
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(AppColors.error)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 14)
                                    .background(AppColors.surface)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 24)
                        }
                    }
                }
 
                Spacer()
 
                HStack(spacing: 10) {
                    CustomOutlineButton(title: "Scan Items", icon: AnyView(Image(systemName: "barcode.viewfinder")), action: {
                        tempScannedSerials = viewModel.scannedItems.map { $0.name }
                        showingBatchScanner = true
                    })
                    CustomOutlineButton(title: "Recount", icon: AnyView(Image(systemName: "arrow.clockwise")), action: {
                        Task {
                            await viewModel.loadExpectedItems()
                            viewModel.saveSessionState()
                        }
                    })
                    CustomButton(title: "Submit", icon: AnyView(Image(systemName: "checkmark.shield")), action: {
                        showingSubmitAlert = true
                    })
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Submit Audit", isPresented: $showingSubmitAlert) {
            Button("Yes, Submit") {
                Task {
                    let result = await viewModel.submitCount()
                    switch result {
                    case .success:
                        router.dismissModal()
                        router.push(ICRoute.varianceReport(audit))
                    case .failure:
                        showingErrorAlert = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Do you want to mark all not scanned items as missing? This will create a report containing \(viewModel.yetToScanItems.count) missing items and \(viewModel.newlyAddedItems.count) new items.")
        }
        .alert("Submission Failed", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred while submitting the audit.")
        }
        .task {
            await viewModel.startSession()
        }
        .fullScreenCover(isPresented: $showingBatchScanner) {
            BatchScannerSheet(
                scannedSerials: $tempScannedSerials,
                existingSerials: [],
                allowsDamageReporting: false,
                productName: "Inventory Count",
                expectedSerials: viewModel.yetToScanItems.map { $0.serialNumber }
            ) {
                showingBatchScanner = false
                Task { await viewModel.addScannedItems(barcodes: tempScannedSerials) }
            }
        }
    }
}

#Preview {
    ActiveAuditView(audit: RSMSCycleCount(id: UUID(), title: "Test", date: "May 2026", scope: "Test", status: "In Progress", badgeStatus: .warning))
        .environment(InventoryControllerAppState())
}
