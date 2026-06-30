//
//  SFSVerificationView.swift
//  luxury
//
//  Created by Nalinish Ranjan on 22/05/26.
//

import SwiftUI
import Supabase

struct SFSVerificationView: View {
    let order: PurchasedItemEntity
    @Environment(Router.self) private var router
    @Environment(FulfillmentViewModel.self) private var viewModel
    
    @State private var scannerService = ScannerService()
    @State private var inputSku: String = ""
    @State private var isVerified: Bool = false
    @State private var scanError: String? = nil
    
    @State private var check1: Bool = false
    @State private var check2: Bool = false
    @State private var check3: Bool = false
    
    @State private var isUpdating: Bool = false
    @State private var laserOffset: CGFloat = -110
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var userRole: UserRole? = nil
    @State private var localQuantity: Int? = nil
    
    private var allChecked: Bool {
        check1 && check2 && check3
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
                HStack(spacing: 16) {
                    Button(action: { router.pop() }) {
                        Image(systemName: "chevron.left")
                            .font(AppFonts.sansSerif(size: 20, weight: .semibold))
                            .foregroundStyle(AppColors.gold)
                    }
                    .accessibilityLabel("Back")
                    Text("Verify & Match Item")
                        .font(AppFonts.sansSerif(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.gold)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ORDER DETAILS")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .accessibilityAddTraits(.isHeader)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Order ID")
                                        .font(AppFonts.sansSerif(size: 13))
                                        .foregroundStyle(AppColors.secondary)
                                    Spacer()
                                    Text(order.id.uuidString.prefix(8).uppercased())
                                        .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                
                                Divider().background(AppColors.border)
                                
                                HStack {
                                    Text("Watch Name")
                                        .font(AppFonts.sansSerif(size: 13))
                                        .foregroundStyle(AppColors.secondary)
                                    Spacer()
                                    Text(order.productName ?? "Premium Timepiece")
                                        .font(AppFonts.serif(size: 15, weight: .medium))
                                        .foregroundStyle(AppColors.text)
                                        .multilineTextAlignment(.trailing)
                                }
                                
                                Divider().background(AppColors.border)
                                
                                HStack {
                                    Text("Expected SKU")
                                        .font(AppFonts.sansSerif(size: 13))
                                        .foregroundStyle(AppColors.secondary)
                                    Spacer()
                                    Text(order.productSku ?? "N/A")
                                        .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                                        .foregroundStyle(AppColors.gold)
                                }
                                
                                Divider().background(AppColors.border)
                                
                                HStack {
                                    Text("Store Location")
                                        .font(AppFonts.sansSerif(size: 13))
                                        .foregroundStyle(AppColors.secondary)
                                    Spacer()
                                    Text(order.storeLocation ?? "Vault - Aisle A, Shelf 1")
                                        .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(20)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                            .accessibilityElement(children: .combine)
                        }
                        .padding(.horizontal, 24)
                        
                        Button(action: {
                            isUpdating = true
                            Task {
                                let success = await viewModel.flagItemAsMissing(orderId: order.id)
                                if success {
                                    router.pop()
                                } else {
                                    await MainActor.run {
                                        alertMessage = viewModel.errorMessage ?? "Failed to flag item as missing."
                                        showAlert = true
                                    }
                                }
                                isUpdating = false
                            }
                        }) {
                            Text("Flag Item as Missing")
                                .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppColors.error.opacity(0.8))
                                )
                        }
                        .disabled(isUpdating)
                        .padding(.horizontal, 24)
                        
                        if let qty = localQuantity, qty <= 0 {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(AppColors.warning)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Item Unavailable in Boutique Shelf")
                                            .font(AppFonts.sansSerif(size: 13, weight: .bold))
                                            .foregroundStyle(.white)
                                        Text("Available local stock: 0 units.")
                                            .font(AppFonts.sansSerif(size: 11))
                                            .foregroundStyle(AppColors.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(14)
                                .background(AppColors.warning.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.warning.opacity(0.3), lineWidth: 0.5))
                                
                                if let request = (
                                    EndlessAisleViewModel.shared.outgoingManagerRequests
                                    + EndlessAisleViewModel.shared.incomingManagerRequests
                                    + EndlessAisleViewModel.shared.sourceDispatchRequests
                                    + EndlessAisleViewModel.shared.destinationReceiveRequests
                                ).first(where: { $0.originalOrderId == order.id || $0.item.id == order.productId }) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Endless Aisle Sourcing Status")
                                                    .font(AppFonts.sansSerif(size: 13, weight: .bold))
                                                    .foregroundStyle(AppColors.gold)
                                                Text(request.history.last ?? "Transfer request initiated.")
                                                    .font(AppFonts.sansSerif(size: 11))
                                                    .foregroundStyle(AppColors.secondary)
                                                    .lineLimit(2)
                                            }
                                            Spacer()
                                            StatusBadge(text: LocalizedStringKey(endlessAisleStatusText(request.status)), status: endlessAisleBadgeStatus(request.status))
                                        }
                                        
                                        if request.status == .arrived {
                                            VStack(alignment: .leading, spacing: 10) {
                                                HStack(spacing: 8) {
                                                    Image(systemName: "bell.badge.fill")
                                                        .foregroundStyle(AppColors.success)
                                                    Text("Sourced item has arrived. Receive it from Endless Aisle before fulfillment.")
                                                        .font(AppFonts.sansSerif(size: 12, weight: .bold))
                                                        .foregroundStyle(AppColors.success)
                                                }
                                            }
                                            .padding(12)
                                            .background(AppColors.success.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.success.opacity(0.3), lineWidth: 0.5))
                                        }
                                    }
                                    .padding(14)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                } else {
                                    Button(action: {
                                        let endlessAisleItem = EndlessAisle.Item(
                                            id: order.productId,
                                            name: order.productName ?? "Premium Timepiece",
                                            sku: order.productSku ?? "N/A",
                                            price: 15000.0,
                                            localQuantity: 0
                                        )
                                        EndlessAisleViewModel.shared.requestManagerApproval(order: order, item: endlessAisleItem)
                                        localQuantity = 0
                                    }) {
                                        HStack {
                                            Image(systemName: "paperplane.fill")
                                            Text("Escalate to Manager (Endless-Aisle)")
                                        }
                                        .font(AppFonts.sansSerif(size: 13, weight: .bold))
                                        .foregroundStyle(AppColors.background)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 46)
                                        .background(AppColors.gold)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SCANNER MODULE")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .accessibilityAddTraits(.isHeader)
                            
                            ZStack {
                                AppColors.surface
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(isVerified ? AppColors.success.opacity(0.4) : AppColors.gold15, lineWidth: 1)
                                    )
                                
                                if isVerified {
                                    VStack(spacing: 16) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(AppFonts.sansSerif(size: 64))
                                            .foregroundStyle(AppColors.success)
                                            .accessibilityHidden(true)
                                        
                                        Text("VERIFICATION MATCH SUCCESSFUL")
                                            .font(AppFonts.sansSerif(size: 12, weight: .bold))
                                            .foregroundStyle(AppColors.success)
                                            .kerning(1)
                                        
                                        Text("SKU matches order target: \(order.productSku ?? "")")
                                            .font(AppFonts.sansSerif(size: 13))
                                            .foregroundStyle(AppColors.secondary)
                                    }
                                    .padding(40)
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("Verification Match Successful. SKU matches order target: \(order.productSku ?? "")")
                                } else {
                                    VStack(spacing: 20) {
                                        ZStack {
                                            if isSimulator {
                                                VStack(spacing: 12) {
                                                    Image(systemName: "watch.analog")
                                                        .font(.system(size: 40))
                                                        .foregroundStyle(AppColors.gold.opacity(0.6))
                                                        .accessibilityHidden(true)
                                                    Text("iOS Simulator — Camera Unavailable")
                                                        .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                                        .foregroundStyle(AppColors.secondary)
                                                }
                                                .frame(width: 240, height: 160)
                                                .background(Color.black.opacity(0.6))
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(AppColors.gold50, lineWidth: 1.5)
                                                )
                                                .accessibilityElement(children: .combine)
                                                .accessibilityLabel("iOS Simulator, Camera Unavailable")
                                            } else {
                                                QRScannerView(scannerService: scannerService)
                                                    .frame(width: 240, height: 160)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(AppColors.gold50, lineWidth: 1.5)
                                                    )
                                            }
                                            
                                            Rectangle()
                                                .fill(AppColors.error)
                                                .frame(width: 220, height: 2)
                                                .shadow(color: .red, radius: 4)
                                                .offset(y: laserOffset)
                                                .accessibilityHidden(true)
                                                .onAppear {
                                                    withAnimation(Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                                                        laserOffset = 70
                                                    }
                                                }
                                        }
                                        .frame(height: 180)
                                        
                                        if let scanError = scanError {
                                            Text(scanError)
                                                .font(AppFonts.sansSerif(size: 13))
                                                .foregroundStyle(AppColors.error)
                                        }
                                        
                                        if isSimulator {
                                            HStack(spacing: 12) {
                                                Button(action: {
                                                    handleScannedCode(order.productSku ?? "")
                                                }) {
                                                    Text("Scan Correct SKU")
                                                        .font(AppFonts.sansSerif(size: 13, weight: .bold))
                                                        .foregroundStyle(AppColors.background)
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 10)
                                                        .background(AppColors.gold)
                                                        .clipShape(Capsule())
                                                }
                                                
                                                Button(action: {
                                                    handleScannedCode("MISMATCH-SKU-\(Int.random(in: 100...999))")
                                                }) {
                                                    Text("Scan Mismatch")
                                                        .font(AppFonts.sansSerif(size: 13, weight: .bold))
                                                        .foregroundStyle(.white)
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 10)
                                                        .background(AppColors.error.opacity(0.8))
                                                        .clipShape(Capsule())
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 24)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        if !isVerified {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("TORN / UNREADABLE LABEL MANUAL ENTRY")
                                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1.5)
                                    .accessibilityAddTraits(.isHeader)
                                
                                HStack(spacing: 12) {
                                    TextField("Enter SKU or Product Code", text: $inputSku)
                                        .font(AppFonts.sansSerif(size: 14))
                                        .foregroundStyle(AppColors.text)
                                        .padding()
                                        .background(AppColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(AppColors.border, lineWidth: 1)
                                        )
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.characters)
                                        .accessibilityLabel("Manual SKU entry")
                                        .accessibilityHint("Enter SKU or Product Code manually if label is unreadable")
                                    
                                    Button(action: {
                                        handleScannedCode(inputSku)
                                    }) {
                                        Text("Verify")
                                            .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                            .foregroundStyle(AppColors.background)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 14)
                                            .background(AppColors.gold)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        } else {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("VERIFICATION CHECKLIST")
                                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1.5)
                                    .accessibilityAddTraits(.isHeader)
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    Toggle(isOn: $check1) {
                                        Text("Confirm timepiece matches requested model specifications")
                                            .font(AppFonts.sansSerif(size: 13))
                                            .foregroundStyle(AppColors.text)
                                    }
                                    .toggleStyle(LuxuryToggleStyle())
                                    
                                    Divider().background(AppColors.border)
                                    
                                    Toggle(isOn: $check2) {
                                        Text("Confirm physical watch shows zero defects or scratches")
                                            .font(AppFonts.sansSerif(size: 13))
                                            .foregroundStyle(AppColors.text)
                                    }
                                    .toggleStyle(LuxuryToggleStyle())
                                    
                                    Divider().background(AppColors.border)
                                    
                                    Toggle(isOn: $check3) {
                                        Text("Confirm certificates, warranty card, and luxury box are complete")
                                            .font(AppFonts.sansSerif(size: 13))
                                            .foregroundStyle(AppColors.text)
                                    }
                                    .toggleStyle(LuxuryToggleStyle())
                                }
                                .padding(20)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                                
                                if userRole == .inventoryController {
                                    Button(action: {
                                        guard userRole == .inventoryController else {
                                            alertMessage = "Unauthorized: Action is restricted to Inventory Controllers."
                                            showAlert = true
                                            return
                                        }
                                        isUpdating = true
                                        Task {
                                            let success = await viewModel.updateStatusToSecured(orderId: order.id)
                                            if success {
                                                router.pop()
                                            } else {
                                                await MainActor.run {
                                                    alertMessage = viewModel.errorMessage ?? "An unknown conflict occurred."
                                                    showAlert = true
                                                }
                                            }
                                            isUpdating = false
                                        }
                                    }) {
                                        HStack {
                                            if isUpdating {
                                                ProgressView()
                                                    .tint(AppColors.background)
                                                    .controlSize(.small)
                                            } else {
                                                Text("Mark as Secured")
                                            }
                                        }
                                        .font(AppFonts.sansSerif(size: 15, weight: .bold))
                                        .foregroundStyle(AppColors.background)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(AppColors.gold)
                                        )
                                        .opacity(allChecked && !isUpdating ? 1.0 : 0.5)
                                    }
                                    .disabled(!allChecked || isUpdating)
                                    .padding(.top, 8)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Fulfillment Alert"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            scannerService.onScannedCode = { code in
                handleScannedCode(code)
            }
        }
        .task {
            if let profile = try? await ProfileService().fetchCurrentProfile() {
                userRole = profile.0
                if let staff = profile.1 as? StaffModel, let storeId = staff.boutiqueId {
                    let units = try? await InventoryService.shared.fetchInventory(forCatalog: order.productId, boutiqueId: storeId)
                    let quantity = units?.filter { $0.status == .available }.count ?? 0
                    await MainActor.run {
                        self.localQuantity = quantity
                    }
                }
            }
            EndlessAisleViewModel.shared.loadRequests()
        }
    }
    
    private func handleScannedCode(_ code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let result = viewModel.verifyScannedSku(orderSku: order.productSku, scannedCode: trimmed)
        switch result {
        case .success:
            scannerService.playSuccessFeedback()
            withAnimation {
                isVerified = true
                scanError = nil
            }
        case .failure(let error):
            scannerService.playErrorFeedback()
            withAnimation {
                scanError = error.localizedDescription
            }
        }
    }
    
    private func endlessAisleBadgeStatus(_ status: EndlessAisle.RequestState) -> BadgeStatus {
        switch status {
        case .arrived, .received, .localInStock:
            return .success
        case .pendingSourceDispatch:
            return .warning
        case .noStockAnywhere:
            return .error
        default:
            return .pending
        }
    }
    
    private func endlessAisleStatusText(_ status: EndlessAisle.RequestState) -> String {
        switch status {
        case .checking:
            return "Checking"
        case .localInStock:
            return "Local"
        case .noStockAnywhere:
            return "No Stock"
        case .pendingBoutiqueManagerApproval:
            return "Manager Review"
        case .pendingSourceBoutiqueApproval:
            return "Source Review"
        case .pendingSourceDispatch:
            return "Dispatch"
        case .dispatched:
            return "In Transit"
        case .arrived:
            return "Arrived"
        case .received:
            return "Received"
        }
    }
}
