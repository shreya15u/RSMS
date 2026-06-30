//
//  POScannerView.swift
//  luxury
//
//  Created by Kaushiki Rai on 29/05/26.
//

import SwiftUI

struct POScannerView: View {
    let poId: UUID
    @State var viewModel: ReceivingViewModel
    let onDismiss: () -> Void
    
    @State private var scannerService = ScannerService()
    @State private var showingUnexpectedAlert = false
    @State private var unexpectedItemName = ""
    
    @State private var hudMessage: String? = nil
    @State private var hudStatus: POScanHUDStatus = .success
    @State private var scanLineOffset: CGFloat = -120
    
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
                            .fill(Color.red)
                            .frame(height: 2)
                            .offset(y: scanLineOffset)
                            .onAppear {
                                withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: true)) {
                                    scanLineOffset = 120
                                }
                            }
                    )
                
                Text("Align item barcode within the frame")
                    .font(AppFonts.sansSerif(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.gold)
                    .padding(.top, 16)
                
                Spacer()
            }
            
            HStack {
                Button("Close") {
                    onDismiss()
                }
                .font(AppFonts.sansSerif(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.gold)
                
                Spacer()
                
                Text("Scan PO Items")
                    .font(AppFonts.sansSerif(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Spacer()
                    .frame(width: 50)
            }
            .padding()
            .background(Color.black.opacity(0.6))
            
            VStack {
                Spacer().frame(height: 80)
                if let message = hudMessage {
                    HStack(spacing: 8) {
                        Image(systemName: hudStatus == .success ? "checkmark.circle.fill" : (hudStatus == .warning ? "exclamationmark.triangle.fill" : "exclamationmark.octagon.fill"))
                            .foregroundColor(.white)
                        Text(message)
                            .font(AppFonts.sansSerif(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(hudStatus == .success ? AppColors.success : (hudStatus == .warning ? AppColors.warning : AppColors.error))
                    .clipShape(Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .shadow(radius: 5)
                }
            }
        }
        .onAppear {
            scannerService.onScannedCode = handleScannedCode
            _ = scannerService.configure()
            scannerService.start()
        }
        .onDisappear {
            scannerService.stop()
        }
        .alert("Unexpected Item Scanned", isPresented: $showingUnexpectedAlert) {
            TextField("Item Name", text: $unexpectedItemName)
            Button("Cancel", role: .cancel) {
                scannerService.start()
            }
            Button("Verify & Include") {
                viewModel.forceAddUnexpectedItem(poId: poId, itemName: unexpectedItemName.isEmpty ? "Unexpected Item" : unexpectedItemName)
                showHUD(message: "Added unexpected item: \(unexpectedItemName)", status: .success)
                scannerService.start()
                unexpectedItemName = ""
            }
        } message: {
            Text("This item is not listed on the Purchase Order. Would you like to verify and include it?")
        }
    }
    
    private func handleScannedCode(_ code: String) {
        let result = viewModel.processScan(poId: poId, code: code)
        
        switch result {
        case .success(let name, let isOvercount):
            if isOvercount {
                scannerService.playErrorFeedback()
                showHUD(message: "Warning: Overcount for \(name)", status: .warning)
            } else {
                scannerService.playSuccessFeedback()
                showHUD(message: "Matched: \(name)", status: .success)
            }
        case .completed(let name, let isOvercount):
            scannerService.playSuccessFeedback()
            if isOvercount {
                showHUD(message: "Warning: Overcount for \(name) & PO Completed!", status: .warning)
            } else {
                showHUD(message: "Matched: \(name). PO Completed!", status: .success)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onDismiss()
            }
        case .unexpected(let name):
            scannerService.playErrorFeedback()
            scannerService.stop()
            unexpectedItemName = name
            showingUnexpectedAlert = true
        case .error(let err):
            scannerService.playErrorFeedback()
            showHUD(message: err, status: .error)
        }
    }
    
    private func showHUD(message: String, status: POScanHUDStatus) {
        hudMessage = message
        hudStatus = status
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if hudMessage == message {
                withAnimation {
                    hudMessage = nil
                }
            }
        }
    }
}
