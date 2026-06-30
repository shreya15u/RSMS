//
//  StockReconciliationView.swift
//  luxury
//
//  Created by Codex on 27/05/26.
//

import SwiftUI

struct StockReconciliationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = StockReconciliationViewModel()
    @State private var scannerService = ScannerService()

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        ZStack {
                            QRScannerView(scannerService: scannerService)
                                .frame(height: 260)
                                .clipShape(RoundedRectangle(cornerRadius: 18))

                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.gold, lineWidth: 2)
                                .frame(width: 210, height: 210)
                        }
                        .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Damaged or unreadable barcode?")
                                .font(AppFonts.serif(size: 20, weight: .medium))
                                .foregroundStyle(AppColors.text)

                            Text("Enter the SKU manually to continue the count.")
                                .font(AppFonts.sansSerif(size: 13))
                                .foregroundStyle(AppColors.secondary)

                            HStack(spacing: 12) {
                                TextField("Enter SKU", text: $viewModel.manualSKU)
                                    .font(AppFonts.sansSerif(size: 15))
                                    .foregroundStyle(AppColors.text)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled(true)
                                    .submitLabel(.search)
                                    .padding(.horizontal, 16)
                                    .frame(height: 54)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(AppColors.gold15, lineWidth: 1)
                                    )
                                    .onSubmit {
                                        viewModel.submitManualLookup()
                                    }

                                Button(action: {
                                    viewModel.submitManualLookup()
                                }) {
                                    Image(systemName: "magnifyingglass")
                                        .font(AppFonts.sansSerif(size: 18, weight: .semibold))
                                        .foregroundStyle(AppColors.background)
                                        .frame(width: 54, height: 54)
                                        .background(AppColors.gold)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(20)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(AppColors.gold15, lineWidth: 1)
                        )
                        .padding(.horizontal, 24)

                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .tint(AppColors.gold)
                                Spacer()
                            }
                            .padding(.top, 8)
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(AppFonts.sansSerif(size: 13))
                                .foregroundStyle(AppColors.error)
                                .padding(.horizontal, 24)
                        }

                        if let successMessage = viewModel.successMessage {
                            Text(successMessage)
                                .font(AppFonts.sansSerif(size: 13))
                                .foregroundStyle(AppColors.success)
                                .padding(.horizontal, 24)
                        }

                        if let catalog = viewModel.currentCatalog {
                            VStack(alignment: .leading, spacing: 20) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(catalog.brand.uppercased())
                                        .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                        .foregroundStyle(AppColors.gold)
                                        .kerning(1.4)
                                    Text(catalog.name)
                                        .font(AppFonts.serif(size: 24, weight: .medium))
                                        .foregroundStyle(AppColors.text)
                                    Text("SKU \(catalog.catalogId)")
                                        .font(AppFonts.sansSerif(size: 12))
                                        .foregroundStyle(AppColors.secondary)
                                }

                                HStack(spacing: 12) {
                                    MetricCard(title: "Expected", value: "\(viewModel.expectedQuantity)", subtitle: "Current inventory record", icon: "archivebox")
                                    MetricCard(title: "Scanned", value: "\(viewModel.scannedQuantity)", subtitle: "Physical count", icon: "barcode.viewfinder")
                                }

                                HStack(spacing: 12) {
                                    CountAdjustButton(systemName: "minus", isEnabled: viewModel.scannedQuantity > 0) {
                                        viewModel.decrementScannedQuantity()
                                    }

                                    Text("\(viewModel.scannedQuantity)")
                                        .font(AppFonts.serif(size: 28, weight: .bold))
                                        .foregroundStyle(AppColors.text)
                                        .frame(maxWidth: .infinity)

                                    CountAdjustButton(systemName: "plus", isEnabled: true) {
                                        viewModel.incrementScannedQuantity()
                                    }
                                }

                                Text(viewModel.hasMismatch ? "Mismatch detected. Submit the scanned quantity to correct inventory." : "Expected and scanned quantities match.")
                                    .font(AppFonts.sansSerif(size: 13))
                                    .foregroundStyle(viewModel.hasMismatch ? AppColors.warning : AppColors.success)

                                CustomButton(
                                    title: viewModel.isSaving ? "Applying Correction" : "Submit Correction",
                                    icon: AnyView(Image(systemName: "square.and.pencil")),
                                    isLoading: viewModel.isSaving
                                ) {
                                    viewModel.applyCorrection()
                                }
                                .disabled(!viewModel.canSubmitCorrection)
                            }
                            .padding(20)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(AppColors.gold15, lineWidth: 1)
                            )
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Stock Reconciliation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            viewModel.loadContext()
            scannerService.onScannedCode = { code in
                scannerService.playSuccessFeedback()
                viewModel.handleScannedCode(code)
            }
        }
    }
}

private struct CountAdjustButton: View {
    let systemName: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(AppFonts.sansSerif(size: 18, weight: .bold))
                .foregroundStyle(isEnabled ? AppColors.gold : AppColors.tertiary)
                .frame(width: 54, height: 54)
                .background(AppColors.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isEnabled ? AppColors.gold15 : AppColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
