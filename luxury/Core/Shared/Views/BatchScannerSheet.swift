//
//  BatchScannerSheet.swift
//  luxury
//
//  Created by Kaushiki Rai on 27/05/26.
//

import SwiftUI

struct BatchScannerSheet: View {
    @Binding var scannedSerials: [String]
    @Binding var damagedItems: [DamagedDeliveryItemDraft]

    let existingSerials: [String]
    let allowsDamageReporting: Bool
    let productName: String
    let expectedSerials: [String]?
    let onDone: () -> Void

    @State private var scannerService = ScannerService()
    @State private var showingList = true
    @State private var showingDuplicateAlert = false
    @State private var duplicateAlertItem = ""
    @State private var showingUnexpectedAlert = false
    @State private var unexpectedAlertItem = ""
    @State private var scanLineOffset: CGFloat = -120
    @State private var hudMessage: String? = nil
    @State private var hudStatus: ScanHUDStatus = .success

    init(
        scannedSerials: Binding<[String]>,
        existingSerials: [String],
        allowsDamageReporting: Bool = false,
        damagedItems: Binding<[DamagedDeliveryItemDraft]> = .constant([]),
        productName: String = "",
        expectedSerials: [String]? = nil,
        onDone: @escaping () -> Void
    ) {
        _scannedSerials = scannedSerials
        _damagedItems = damagedItems
        self.existingSerials = existingSerials
        self.allowsDamageReporting = allowsDamageReporting
        self.productName = productName
        self.expectedSerials = expectedSerials
        self.onDone = onDone
    }

    var body: some View {
        ZStack(alignment: .top) {
            QRScannerView(scannerService: scannerService)
                .ignoresSafeArea()

            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.gold, lineWidth: 2)
                    .frame(width: 250, height: 250)
                    .overlay(
                        Rectangle()
                            .fill(AppColors.error)
                            .frame(height: 2)
                            .offset(y: scanLineOffset)
                            .onAppear {
                                withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: true)) {
                                    scanLineOffset = 120
                                }
                            }
                    )
                
                Text("Align barcode / QR code within the frame")
                    .font(AppFonts.sansSerif(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.gold)
                    .padding(.top, 16)
                
                Spacer()
            }

            HStack {
                Button("Cancel") { onDone() }
                    .font(AppFonts.sansSerif(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.gold)

                Spacer()

                Text("Batch Scan")
                    .font(AppFonts.sansSerif(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button("Done") { onDone() }
                    .font(AppFonts.sansSerif(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.gold)
            }
            .padding()
            .background(Color.black.opacity(0.6))

            VStack {
                Spacer().frame(height: 80)
                if let message = hudMessage {
                    HStack(spacing: 8) {
                        Image(systemName: hudStatus == .success ? "checkmark.circle.fill" : (hudStatus == .duplicate ? "exclamationmark.triangle.fill" : "questionmark.circle.fill"))
                            .foregroundColor(.white)
                        Text(message)
                            .font(AppFonts.sansSerif(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(hudStatus == .success ? AppColors.success : (hudStatus == .duplicate ? AppColors.error : Color.blue))
                    .clipShape(Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .shadow(radius: 5)
                }
            }
        }
        .sheet(isPresented: $showingList) {
            ScannedSerialsListView(
                scannedSerials: $scannedSerials,
                damagedItems: $damagedItems,
                allowsDamageReporting: allowsDamageReporting,
                productName: productName,
                onManualEntry: handleScannedCode
            )
            .presentationDetents([.fraction(0.25), .medium, .large])
            .presentationBackgroundInteraction(.enabled(upThrough: .large))
            .presentationBackground(.ultraThinMaterial)
            .interactiveDismissDisabled()
        }
        .onAppear {
            scannerService.onScannedCode = handleScannedCode
        }
        .alert("Duplicate Item", isPresented: $showingDuplicateAlert) {
            Button("Dismiss", role: .cancel) {}
        } message: {
            Text("The item '\(duplicateAlertItem)' has already been scanned in this session.")
        }
    }

    private func handleScannedCode(_ code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if scannedSerials.contains(trimmed) || existingSerials.contains(trimmed) {
            scannerService.playErrorFeedback()
            showHUD(message: "Duplicate: \(trimmed)", status: .duplicate)
            duplicateAlertItem = trimmed
            showingDuplicateAlert = true
            return
        }

        if let expected = expectedSerials, !expected.contains(trimmed) {
            scannerService.playSuccessFeedback()
            showHUD(message: "New Item Found: \(trimmed)", status: .unexpected)
            withAnimation {
                scannedSerials.append(trimmed)
            }
            return
        }

        withAnimation {
            scannedSerials.append(trimmed)
        }
        showHUD(message: "Scanned: \(trimmed)", status: .success)
        scannerService.playSuccessFeedback()
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

private enum ScanHUDStatus {
    case success, duplicate, unexpected
}

struct ScannedSerialsListView: View {
    @Binding var scannedSerials: [String]
    @Binding var damagedItems: [DamagedDeliveryItemDraft]

    let allowsDamageReporting: Bool
    let productName: String
    let onManualEntry: (String) -> Void

    @State private var manualEntry = ""
    @State private var reportingSerial: ReportedSerial?

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Manual Entry")) {
                    HStack {
                        TextField("Type barcode or serial...", text: $manualEntry)
                            .font(AppFonts.sansSerif(size: 16))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled(true)
                            .submitLabel(.done)
                            .onSubmit {
                                submitManualEntry()
                            }

                        Button(action: submitManualEntry) {
                            Image(systemName: "plus.circle.fill")
                                .font(AppFonts.sansSerif(size: 24))
                                .foregroundStyle(manualEntry.isEmpty ? AppColors.tertiary : AppColors.gold)
                        }
                        .disabled(manualEntry.isEmpty)
                        .buttonStyle(.plain)
                    }
                }

                Section(header: Text("Scanned Serials (\(scannedSerials.count))")) {
                    if scannedSerials.isEmpty {
                        Text("Scan items to add them here.")
                            .foregroundStyle(AppColors.secondary)
                    } else {
                        ForEach(Array(scannedSerials.reversed().enumerated()), id: \.offset) { _, serial in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: damageReport(for: serial) == nil ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundStyle(damageReport(for: serial) == nil ? AppColors.success : AppColors.error)
                                    Text(serial)
                                        .foregroundStyle(AppColors.text)

                                    Spacer()

                                    Button(action: {
                                        withAnimation {
                                            scannedSerials.removeAll { $0 == serial }
                                            damagedItems.removeAll { $0.serial == serial }
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundStyle(AppColors.error)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }

                                if let report = damageReport(for: serial) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Damaged on arrival")
                                            .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                            .foregroundStyle(AppColors.error)
                                        Text(report.description)
                                            .font(AppFonts.sansSerif(size: 12))
                                            .foregroundStyle(AppColors.secondary)
                                            .lineLimit(2)
                                    }
                                }

                                if allowsDamageReporting {
                                    Button(action: {
                                        reportingSerial = ReportedSerial(value: serial)
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: damageReport(for: serial) == nil ? "camera.fill" : "square.and.pencil")
                                            Text(damageReport(for: serial) == nil ? "Mark Damaged" : "Edit Damage Report")
                                        }
                                        .font(AppFonts.sansSerif(size: 12, weight: .semibold))
                                        .foregroundStyle(AppColors.gold)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            let realIndices = indexSet.map { scannedSerials.count - 1 - $0 }
                            for index in realIndices.sorted(by: >) {
                                damagedItems.removeAll { $0.serial == scannedSerials[index] }
                                scannedSerials.remove(at: index)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Scanned Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .sheet(item: $reportingSerial) { item in
            DamagedItemReportSheet(
                serial: item.value,
                productName: productName,
                existingReport: damageReport(for: item.value)
            ) { report in
                if let index = damagedItems.firstIndex(where: { $0.serial == report.serial }) {
                    damagedItems[index] = report
                } else {
                    damagedItems.append(report)
                }
            }
        }
    }

    private func submitManualEntry() {
        let code = manualEntry.trimmingCharacters(in: .whitespacesAndNewlines)
        if !code.isEmpty {
            onManualEntry(code)
            manualEntry = ""
        }
    }

    private func damageReport(for serial: String) -> DamagedDeliveryItemDraft? {
        damagedItems.first(where: { $0.serial == serial })
    }
}

private struct ReportedSerial: Identifiable {
    let value: String

    var id: String {
        value
    }
}

#Preview {
    BatchScannerSheet(
        scannedSerials: .constant([]),
        existingSerials: [],
        onDone: {}
    )
}
