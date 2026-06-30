//
//  PODetailView.swift
//  luxury
//
//  Created by Kaushiki Rai on 29/05/26.
//

import SwiftUI

struct PODetailView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = ReceivingViewModel()
    let poId: UUID
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingScanner = false
    @State private var showingUnexpectedAlert = false
    @State private var unexpectedItemName = ""
    @State private var manualBarcode = ""
    
    @State private var hudMessage: String? = nil
    @State private var hudStatus: POScanHUDStatus = .success
    
    init(po: PurchaseOrder) {
        self.poId = po.id
    }
    
    var po: PurchaseOrder? {
        viewModel.purchaseOrders.first { $0.id == poId }
    }
    
    var totalExpected: Int {
        po?.items.reduce(0) { $0 + $1.expectedQty } ?? 0
    }
    
    var totalReceived: Int {
        po?.items.reduce(0) { $0 + $1.receivedQty } ?? 0
    }
    
    var progressFraction: Double {
        guard totalExpected > 0 else { return 0.0 }
        return Double(totalReceived) / Double(totalExpected)
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            if let po = po {
                VStack(spacing: 0) {
                    CustomHeader(title: "PO Details", showBackButton: true, backAction: { dismiss() })
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("SUPPLIER")
                                            .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                            .foregroundStyle(AppColors.secondary)
                                            .kerning(1.5)
                                        Text(po.supplier)
                                            .font(AppFonts.serif(size: 20, weight: .semibold))
                                            .foregroundStyle(.white)
                                    }
                                    Spacer()
                                }
                                
                                Divider().background(AppColors.gold15)
                                
                                HStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("RECEIVED")
                                            .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                            .foregroundStyle(AppColors.secondary)
                                        Text("\(totalReceived) / \(totalExpected) units")
                                            .font(AppFonts.serif(size: 18, weight: .semibold))
                                            .foregroundStyle(AppColors.gold)
                                    }
                                    
                                    Spacer()
                                    
                                    CircularProgressView(progress: progressFraction)
                                        .frame(width: 44, height: 44)
                                }
                            }
                            .padding(20)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.gold15, lineWidth: 1)
                            )
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("EXPECTED ITEMS")
                                    .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1.5)
                                
                                ForEach(po.items) { item in
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.brand.uppercased())
                                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                                .foregroundStyle(AppColors.gold)
                                                .kerning(1)
                                            
                                            Text(item.name)
                                                .font(AppFonts.serif(size: 16, weight: .medium))
                                                .foregroundStyle(.white)
                                            
                                            Text("SKU: \(item.sku)")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 6) {
                                            Text("\(item.receivedQty) / \(item.expectedQty)")
                                                .font(AppFonts.serif(size: 18, weight: .bold))
                                                .foregroundStyle(
                                                    item.receivedQty > item.expectedQty ? AppColors.warning : 
                                                    (item.receivedQty == item.expectedQty ? AppColors.success : AppColors.secondary)
                                                )
                                            
                                            if item.receivedQty > item.expectedQty {
                                                Text("OVERCOUNT")
                                                    .font(AppFonts.sansSerif(size: 9, weight: .bold))
                                                    .foregroundStyle(AppColors.warning)
                                            } else if item.receivedQty == item.expectedQty {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundStyle(AppColors.success)
                                            } else {
                                                Text("\(item.expectedQty - item.receivedQty) pending")
                                                    .font(AppFonts.sansSerif(size: 11))
                                                    .foregroundStyle(AppColors.secondary)
                                            }
                                        }
                                    }
                                    .padding(16)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            
                            if po.status != .fullyReceived {
                                CustomButton(
                                    title: "Open Camera Scanner",
                                    icon: AnyView(Image(systemName: "barcode.viewfinder"))
                                ) {
                                    showingScanner = true
                                }
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("SIMULATED SCANNING CONSOLE")
                                        .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                        .foregroundStyle(AppColors.secondary)
                                        .kerning(1.5)
                                    
                                    VStack(spacing: 12) {
                                        HStack {
                                            TextField("Enter manual barcode...", text: $manualBarcode)
                                                .font(AppFonts.sansSerif(size: 14))
                                                .padding(12)
                                                .background(AppColors.background)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .textInputAutocapitalization(.characters)
                                                .autocorrectionDisabled(true)
                                            
                                            Button(action: {
                                                submitManualScan()
                                            }) {
                                                Text("Scan")
                                                    .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                                    .foregroundStyle(AppColors.background)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(AppColors.gold)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                            .disabled(manualBarcode.isEmpty)
                                        }
                                        
                                        Text("Quick simulation buttons:")
                                            .font(AppFonts.sansSerif(size: 12))
                                            .foregroundStyle(AppColors.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        ForEach(po.items) { item in
                                            Button(action: {
                                                simulateScan(code: item.sku)
                                            }) {
                                                HStack {
                                                    Text("Scan \(item.name)")
                                                        .font(AppFonts.sansSerif(size: 13, weight: .medium))
                                                    Spacer()
                                                    Image(systemName: "play.circle.fill")
                                                }
                                                .padding(12)
                                                .background(AppColors.surface2)
                                                .foregroundStyle(AppColors.gold)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                        }
                                        
                                        Button(action: {
                                            simulateScan(code: "UNKNOWN_SKU_\(Int.random(in: 100...999))")
                                        }) {
                                            HStack {
                                                Text("Scan Unexpected Item")
                                                    .font(AppFonts.sansSerif(size: 13, weight: .medium))
                                                Spacer()
                                                Image(systemName: "exclamationmark.triangle.fill")
                                            }
                                            .padding(12)
                                            .background(AppColors.surface2)
                                            .foregroundStyle(AppColors.error)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                    .padding(16)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            } else {
                Text("Purchase Order not found")
                    .font(AppFonts.serif(size: 20))
                    .foregroundStyle(AppColors.text)
            }
            
            if let msg = hudMessage {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: hudStatus == .success ? "checkmark.circle.fill" : (hudStatus == .warning ? "exclamationmark.triangle.fill" : "exclamationmark.octagon.fill"))
                        Text(msg)
                            .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 24)
                    .background(hudStatus == .success ? AppColors.success : (hudStatus == .warning ? AppColors.warning : AppColors.error))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: hudMessage)
            }
        }
        .sheet(isPresented: $showingScanner) {
            if let po = po {
                POScannerView(poId: po.id, viewModel: viewModel) {
                    showingScanner = false
                }
            }
        }
        .alert("Unexpected Item Scanned", isPresented: $showingUnexpectedAlert) {
            TextField("Item Name", text: $unexpectedItemName)
            Button("Cancel", role: .cancel) {}
            Button("Verify & Include") {
                if let po = po {
                    viewModel.forceAddUnexpectedItem(poId: po.id, itemName: unexpectedItemName.isEmpty ? "Unexpected Item" : unexpectedItemName)
                    showHUD(message: "Added unexpected item: \(unexpectedItemName)", status: .success)
                }
                unexpectedItemName = ""
            }
        } message: {
            Text("This item is not listed on the Purchase Order. Would you like to verify and include it?")
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.loadPurchaseOrders()
        }
    }
    
    private func simulateScan(code: String) {
        guard let po = po else { return }
        let result = viewModel.processScan(poId: po.id, code: code)
        
        switch result {
        case .success(let name, let isOvercount):
            if isOvercount {
                showHUD(message: "Warning: Overcount for \(name)", status: .warning)
            } else {
                showHUD(message: "Matched: \(name)", status: .success)
            }
        case .completed(let name, let isOvercount):
            if isOvercount {
                showHUD(message: "Warning: Overcount for \(name) & PO Completed!", status: .warning)
            } else {
                showHUD(message: "Matched: \(name). PO Completed!", status: .success)
            }
        case .unexpected(let name):
            unexpectedItemName = name
            showingUnexpectedAlert = true
        case .error(let err):
            showHUD(message: err, status: .error)
        }
    }
    
    private func submitManualScan() {
        let code = manualBarcode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !code.isEmpty {
            simulateScan(code: code)
            manualBarcode = ""
        }
    }
    
    private func showHUD(message: String, status: POScanHUDStatus) {
        hudMessage = message
        hudStatus = status
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if hudMessage == message {
                withAnimation {
                    hudMessage = nil
                }
            }
        }
    }
}

enum POScanHUDStatus {
    case success
    case warning
    case error
}

struct CircularProgressView: View {
    var progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.gold15, lineWidth: 4)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(AppColors.gold, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeOut, value: progress)
        }
    }
}

#Preview {
    PODetailView(po: PurchaseOrder(poNumber: "PO-MOCK", supplier: "Mock Supplier", items: []))
        .environment(Router())
}
