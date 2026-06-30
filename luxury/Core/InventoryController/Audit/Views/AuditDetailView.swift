//
//  AuditDetailView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct AuditDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Router.self) private var router
    let audit: RSMSCycleCount
    @State private var showInstructions = false
    @State private var viewModel: ActiveAuditViewModel
    
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
                // Top Custom Centered Inline Toolbar
                ZStack {
                    Text(audit.title)
                        .font(AppFonts.sansSerif(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(AppFonts.sansSerif(size: 20, weight: .semibold))
                                .foregroundStyle(AppColors.gold)
                        }
                        
                        Spacer()
                        
                        Button(action: { showInstructions = true }) {
                            Image(systemName: "info.circle")
                                .font(AppFonts.sansSerif(size: 20))
                                .foregroundStyle(AppColors.gold)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(AppColors.background)
                
 
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // Premium card for title info (without repeated title)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(audit.scope.uppercased())
                                    .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                    .foregroundStyle(AppColors.gold)
                                    .kerning(1.5)
                                Spacer()
                                StatusBadge(text: LocalizedStringKey(audit.status), status: audit.badgeStatus)
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.secondary)
                                Text("Scheduled for \(audit.date)")
                                    .font(AppFonts.sansSerif(size: 13))
                                    .foregroundStyle(AppColors.secondary)
                            }
                        }
                        .padding(20)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                        .padding(.horizontal, 24)
                        
                        // Checklist (only shown if not monthly and not full)
                        if !audit.title.localizedCaseInsensitiveContains("monthly") && !audit.title.localizedCaseInsensitiveContains("full") {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("PREPARATION CHECKLIST")
                                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1.5)
                                    .padding(.horizontal, 24)
                                
                                VStack(spacing: 1) {
                                    ChecklistRow(text: String(localized: "Device Battery > \((0.80).formatted(.percent.precision(.fractionLength(0))))"), checked: true)
                                    ChecklistRow(text: "Scanner Synced", checked: true)
                                    ChecklistRow(text: "Floor area cleared", checked: false)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        // Loading state or Scan simulator
                        if viewModel.isLoading {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .tint(AppColors.gold)
                                    .scaleEffect(1.2)
                                Text("Loading Boutique Inventory...")
                                    .font(AppFonts.sansSerif(size: 13))
                                    .foregroundStyle(AppColors.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                            .padding(.horizontal, 24)
                        } else {
 
                            
                            // SCANNED ITEMS
                            VStack(alignment: .leading, spacing: 16) {
                                Text("SCANNED ITEMS")
                                    .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                    .foregroundStyle(AppColors.tertiary)
                                    .kerning(1.5)
                                    .padding(.horizontal, 24)
                                
                                if viewModel.scannedItems.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "barcode.viewfinder")
                                            .font(.system(size: 28))
                                            .foregroundStyle(AppColors.tertiary)
                                        Text("No items scanned yet")
                                            .font(AppFonts.sansSerif(size: 13))
                                            .foregroundStyle(AppColors.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 28)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                                    .padding(.horizontal, 24)
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
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                                    .padding(.horizontal, 24)
                                }
                            }
                            
                            // NEW ITEMS
                            if !viewModel.newlyAddedItems.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("NEW ITEMS")
                                        .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                        .foregroundStyle(Color.blue)
                                        .kerning(1.5)
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
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                                    .padding(.horizontal, 24)
                                }
                            }
                            
                            // MISSING ITEMS
                            if !viewModel.yetToScanItems.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("MISSING ITEMS")
                                        .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                        .foregroundStyle(AppColors.error)
                                        .kerning(1.5)
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
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                                    .padding(.horizontal, 24)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
                
                // Bottom layout - 2 side-by-side outline buttons, 1 full-width submit button below
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
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
                    }
                    
                    CustomButton(title: "Submit Audit", icon: AnyView(Image(systemName: "checkmark.shield.fill")), isLoading: viewModel.isLoading, action: {
                        showingSubmitAlert = true
                    })
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 34)
                .background(AppColors.background)
            }
        }
        .sheet(isPresented: $showInstructions) {
            InstructionsView(scope: audit.scope)
                .presentationDetents([.height(280), .medium])
                .presentationDragIndicator(.visible)
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
        .navigationTitle("")
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
    }
}

private struct InstructionsView: View {
    let scope: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Instructions")
                        .font(AppFonts.serif(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppColors.secondary)
                    }
                }
                .padding(.bottom, 8)
                
                VStack(alignment: .leading, spacing: 16) {
                    BulletPoint(text: "Ensure all items in \(scope) are tagged.")
                    BulletPoint(text: "Scan QR/Barcodes for items with damaged tags.")
                }
                Spacer()
            }
            .padding(24)
        }
    }
}

private struct BulletPoint: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(AppColors.gold).frame(width: 4, height: 4).padding(.top, 6)
            Text(text)
                .font(AppFonts.sansSerif(size: 13))
                .foregroundStyle(AppColors.text)
                .lineSpacing(4)
        }
    }
}

private struct ChecklistRow: View {
    let text: String
    let checked: Bool
    var body: some View {
        HStack {
            Text(text)
                .font(AppFonts.sansSerif(size: 14))
                .foregroundStyle(checked ? AppColors.text : AppColors.secondary)
            Spacer()
            Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(checked ? AppColors.success : AppColors.tertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.surface)
    }
}

#Preview {
    AuditDetailView(audit: RSMSCycleCount(
        title: "Full Audit",
        date: "31 May 2026",
        scope: "Full Store",
        status: "Scheduled",
        badgeStatus: .neutral
    ))
    .environment(Router())
}
