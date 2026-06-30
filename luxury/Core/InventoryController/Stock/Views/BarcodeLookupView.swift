//
//  BarcodeLookupView.swift
//  luxury
//

import SwiftUI

struct BarcodeLookupView: View {
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = BarcodeLookupViewModel()
    @State private var scannerService = ScannerService()
    @State private var manualEntry: String = ""
    
    @State private var showingDuplicateAlert = false
    @State private var duplicateAlertItem = ""
    
    @State private var showingUnexpectedAlert = false
    @State private var unexpectedAlertItem = ""
    
    @State private var hudMessage: String? = nil
    @State private var hudStatus: ScanHUDStatus = .success
    
    @State private var showingSummary = false
    @State private var showingSuccessAlert = false
    
    private enum ScanHUDStatus {
        case success, duplicate, unexpected
    }
    
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Barcode Lookup", showBackButton: true, backAction: { dismiss() }, isInline: true)
                
                // Camera / Scanner View
                ZStack {
                    if isSimulator {
                        VStack(spacing: 12) {
                            Image(systemName: "watch.analog")
                                .font(.system(size: 40))
                                .foregroundStyle(AppColors.gold.opacity(0.6))
                            Text("iOS Simulator — Camera Unavailable")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding()
                    } else {
                        QRScannerView(scannerService: scannerService)
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding()
                    }
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.gold, lineWidth: 2)
                        .frame(width: 160, height: 160)
                    
                    if let message = hudMessage {
                        VStack {
                            HStack(spacing: 8) {
                                Image(systemName: hudStatus == .success ? "checkmark.circle.fill" : (hudStatus == .duplicate ? "exclamationmark.triangle.fill" : "questionmark.circle.fill"))
                                    .foregroundColor(.white)
                                Text(message)
                                    .font(AppFonts.sansSerif(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(hudStatus == .success ? AppColors.success : (hudStatus == .duplicate ? AppColors.error : AppColors.warning))
                            .clipShape(Capsule())
                            .shadow(radius: 5)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                
                HStack {
                    TextField("Enter Barcode Manually...", text: $manualEntry)
                        .font(AppFonts.sansSerif(size: 16))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled(true)
                        .submitLabel(.search)
                        .padding(12)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onSubmit {
                            handleScannedCode(manualEntry)
                            manualEntry = ""
                        }
                    
                    Button(action: {
                        handleScannedCode(manualEntry)
                        manualEntry = ""
                    }) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(AppFonts.sansSerif(size: 32))
                            .foregroundStyle(manualEntry.isEmpty ? AppColors.tertiary : AppColors.gold)
                    }
                    .disabled(manualEntry.isEmpty)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                

                
                ScrollView {
                    VStack(spacing: 20) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(AppColors.gold)
                                .padding(.top, 20)
                        } else if let error = viewModel.errorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(AppFonts.sansSerif(size: 24))
                                    .foregroundStyle(AppColors.error)
                                Text(error)
                                    .font(AppFonts.sansSerif(size: 14))
                                    .foregroundStyle(AppColors.secondary)
                            }
                            .padding(.top, 20)
                        } else if let item = viewModel.scannedItem {
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.brand)
                                            .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                            .foregroundStyle(AppColors.gold)
                                            .kerning(1.5)
                                            .textCase(.uppercase)
                                        
                                        Text(item.name)
                                            .font(AppFonts.serif(size: 20, weight: .medium))
                                            .foregroundStyle(AppColors.text)
                                        
                                        Text("UPC: \(item.barCode)")
                                            .font(AppFonts.sansSerif(size: 12))
                                            .foregroundStyle(AppColors.tertiary)
                                    }
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("\(viewModel.liveStockCount)")
                                            .font(AppFonts.serif(size: 32, weight: .bold))
                                            .foregroundStyle(viewModel.liveStockCount > 0 ? AppColors.success : AppColors.error)
                                        Text("In Stock")
                                            .font(AppFonts.sansSerif(size: 11))
                                            .foregroundStyle(AppColors.secondary)
                                    }
                                }
                                
                                Divider().background(AppColors.surface)
                                
                                HStack {
                                    Text("Category")
                                        .font(AppFonts.sansSerif(size: 13))
                                        .foregroundStyle(AppColors.secondary)
                                    Spacer()
                                    Text(item.category.rawValue.capitalized)
                                        .font(AppFonts.sansSerif(size: 13, weight: .semibold))
                                        .foregroundStyle(AppColors.text)
                                }
                                
                                HStack {
                                    Text("Price")
                                        .font(AppFonts.sansSerif(size: 13))
                                        .foregroundStyle(AppColors.secondary)
                                    Spacer()
                                    Text("\(CurrencyManager.shared.symbol)\(String(format: "%.2f", item.amount))")
                                        .font(AppFonts.sansSerif(size: 13, weight: .semibold))
                                        .foregroundStyle(AppColors.text)
                                }
                            }
                            .padding(16)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.surface2, lineWidth: 1)
                            )
                            .padding(.horizontal, 24)
                        }
                        
                        VStack(alignment: .leading, spacing: 14) {
                            Text("COUNT SESSION STATISTICS")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                            
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                                MetricCard(title: "Scanned", value: "\(viewModel.scannedBarcodes.count)", subtitle: "Items in count", icon: "barcode.viewfinder")
                                MetricCard(title: "Expected Remaining", value: "\(viewModel.missingItems.count)", subtitle: "Unscanned expected", icon: "archivebox")
                            }
                            
                            if !viewModel.scannedBarcodes.isEmpty {
                                HStack {
                                    CustomOutlineButton(title: "Reset Session", icon: AnyView(Image(systemName: "arrow.clockwise"))) {
                                        viewModel.resetSession()
                                    }
                                    
                                    CustomButton(title: "Complete Count", icon: AnyView(Image(systemName: "checkmark.circle"))) {
                                        showingSummary = true
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(16)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                        
                        if !viewModel.scannedItems.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("SCANNED ITEMS (\(viewModel.scannedItems.count))")
                                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                    .foregroundStyle(AppColors.success)
                                    .kerning(1.5)
                                    .padding(.horizontal, 24)
                                
                                VStack(spacing: 1) {
                                    ForEach(viewModel.scannedItems) { item in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name)
                                                    .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                                    .foregroundStyle(.white)
                                                Text(item.barCode)
                                                    .font(AppFonts.sansSerif(size: 11))
                                                    .foregroundStyle(AppColors.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(AppColors.success)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(AppColors.surface)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        if !viewModel.unexpectedBarcodes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("UNEXPECTED SKU ITEMS (\(viewModel.unexpectedBarcodes.count))")
                                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                    .foregroundStyle(AppColors.error)
                                    .kerning(1.5)
                                    .padding(.horizontal, 24)
                                
                                VStack(spacing: 1) {
                                    ForEach(viewModel.unexpectedBarcodes, id: \.self) { barcode in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Unexpected Item")
                                                    .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                                    .foregroundStyle(AppColors.error)
                                                Text(barcode)
                                                    .font(AppFonts.sansSerif(size: 11))
                                                    .foregroundStyle(AppColors.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundStyle(AppColors.error)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(AppColors.surface)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
        }
        .navigationTitle("Barcode Lookup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.loadExpectedItems()
            scannerService.onScannedCode = { code in
                handleScannedCode(code)
            }
        }
        .alert("Duplicate Item", isPresented: $showingDuplicateAlert) {
            Button("Dismiss", role: .cancel) {}
        } message: {
            Text("The item '\(duplicateAlertItem)' has already been scanned in this session.")
        }
        .alert("Unexpected Item", isPresented: $showingUnexpectedAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Verify & Include") {
                withAnimation {
                    viewModel.addScannedBarcode(unexpectedAlertItem)
                }
                showHUD(message: "Scanned: \(unexpectedAlertItem)", status: .success)
                scannerService.playSuccessFeedback()
                viewModel.lookupItem(by: unexpectedAlertItem)
            }
        } message: {
            Text("The item '\(unexpectedAlertItem)' does not match the expected count list. Verify before including.")
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) {
                viewModel.resetSession()
            }
        } message: {
            Text("Count Submitted. Inventory record updated successfully.")
        }
        .sheet(isPresented: $showingSummary) {
            SessionSummarySheet(
                expectedCount: viewModel.expectedBarcodes.count,
                scannedCount: viewModel.scannedBarcodes.count,
                unexpectedCount: viewModel.unexpectedBarcodes.count,
                missingItems: viewModel.missingItems
            ) {
                showingSummary = false
                showingSuccessAlert = true
            }
        }
    }
    
    private func handleScannedCode(_ code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if viewModel.scannedBarcodes.contains(trimmed) {
            scannerService.playErrorFeedback()
            showHUD(message: "Duplicate: \(trimmed)", status: .duplicate)
            duplicateAlertItem = trimmed
            showingDuplicateAlert = true
            return
        }
        
        if !viewModel.expectedBarcodes.contains(trimmed) {
            scannerService.playErrorFeedback()
            showHUD(message: "Unexpected: \(trimmed)", status: .unexpected)
            unexpectedAlertItem = trimmed
            showingUnexpectedAlert = true
            return
        }
        
        withAnimation {
            viewModel.addScannedBarcode(trimmed)
        }
        showHUD(message: "Scanned: \(trimmed)", status: .success)
        scannerService.playSuccessFeedback()
        viewModel.lookupItem(by: trimmed)
    }
    
    private func showHUD(message: String, status: ScanHUDStatus) {
        withAnimation {
            hudMessage = message
            hudStatus = status
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                if hudMessage == message {
                    hudMessage = nil
                }
            }
        }
    }
}

struct SessionSummarySheet: View {
    let expectedCount: Int
    let scannedCount: Int
    let unexpectedCount: Int
    let missingItems: [CatalogEntity]
    let onSubmit: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("SESSION TOTALS")
                                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1.5)
                                
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                                    MetricCard(title: "Scanned Qty", value: "\(scannedCount)", subtitle: "Physical counted", icon: "checkmark.circle")
                                    MetricCard(title: "Expected Qty", value: "\(expectedCount)", subtitle: "Inventory record", icon: "archivebox")
                                    MetricCard(title: "Missing Qty", value: "\(missingItems.count)", subtitle: "Not scanned", icon: "xmark.circle")
                                    MetricCard(title: "Unexpected Qty", value: "\(unexpectedCount)", subtitle: "Unexpected SKUs", icon: "exclamationmark.triangle")
                                }
                            }
                            .padding(16)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("MISSING EXPECTED ITEMS (\(missingItems.count))")
                                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                    .foregroundStyle(AppColors.error)
                                    .kerning(1.5)
                                    .padding(.horizontal, 24)
                                
                                if missingItems.isEmpty {
                                    Text("All expected items have been scanned.")
                                        .font(AppFonts.sansSerif(size: 13))
                                        .foregroundStyle(AppColors.secondary)
                                        .padding(.horizontal, 24)
                                } else {
                                    VStack(spacing: 1) {
                                        ForEach(missingItems) { item in
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(item.name)
                                                        .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                                        .foregroundStyle(AppColors.secondary)
                                                    Text("UPC: \(item.barCode)")
                                                        .font(AppFonts.sansSerif(size: 11))
                                                        .foregroundStyle(AppColors.tertiary)
                                                }
                                                Spacer()
                                                Text("NOT SCANNED")
                                                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                                    .foregroundStyle(AppColors.error)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(AppColors.surface)
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .padding(.horizontal, 24)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        CustomButton(title: "Sign Off & Submit Count", icon: AnyView(Image(systemName: "checkmark.shield"))) {
                            onSubmit()
                            dismiss()
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Session Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.gold)
                }
            }
        }
    }
}
