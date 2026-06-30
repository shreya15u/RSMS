//
//  AfterSalesViews.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI
import PhotosUI
import Supabase

struct AfterSalesIntakeView: View {
    @Environment(\.dismiss) private var dismiss
    
    let client: Client
    let serialNumber: String?
    let isWarrantyActive: Bool
    let purchaseId: UUID?
    
    @State private var serial: String
    @State private var issue = ""
    @State private var created = false
    @State private var isCreating = false
    @State private var errorMessage: String? = nil
    @State private var showSuccessAlert = false
    
    @State private var showCamera = false
    @State private var showPhotosPicker = false
    @State private var showMediaSourceMenu = false
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var uploadedImages: [UIImage] = []
    
    @State private var isDropdownOpen = false
    @State private var selectedPurchase: ClientPurchase? = nil
    @State private var clientPurchases: [ClientPurchase] = []
    
    @State private var dynamicIsWarrantyActive: Bool = true
    @State private var dynamicWarrantyText: String? = nil
    
    private var isReadOnly: Bool {
        return serialNumber != nil
    }
    
    init(client: Client, serialNumber: String? = nil, isWarrantyActive: Bool = true, purchaseId: UUID? = nil) {
        self.client = client
        self.serialNumber = serialNumber
        self.isWarrantyActive = isWarrantyActive
        self.purchaseId = purchaseId
        
        let localPurchases = PurchaseHistoryService.shared.fetchPurchases(clientId: client.id)
        self._clientPurchases = State(initialValue: localPurchases)
        
        if let sn = serialNumber {
            self._serial = State(initialValue: sn)
            // Look up corresponding purchase by ID or Serial
            let matchingPurchase = localPurchases.first { p in
                if let pid = purchaseId, p.id == pid { return true }
                let prodId = "PRD-" + String(p.id.uuidString.prefix(8).uppercased())
                return prodId == sn
            }
            if let purchase = matchingPurchase {
                let wInfo = Self.checkWarrantyStatus(purchaseDateStr: purchase.date)
                self._dynamicIsWarrantyActive = State(initialValue: wInfo.isActive)
                self._dynamicWarrantyText = State(initialValue: wInfo.expirationText)
                self._selectedPurchase = State(initialValue: purchase)
            } else {
                let wText = isWarrantyActive ? "Valid until 24 nov 2026" : "Expired on 24 nov 2026"
                self._dynamicIsWarrantyActive = State(initialValue: isWarrantyActive)
                self._dynamicWarrantyText = State(initialValue: wText)
            }
        } else {
            self._serial = State(initialValue: "")
            self._dynamicIsWarrantyActive = State(initialValue: true)
            self._dynamicWarrantyText = State(initialValue: nil)
        }
    }
    
    private static func checkWarrantyStatus(purchaseDateStr: String) -> (isActive: Bool, expirationText: String) {
        let formatters = [
            "MMM yyyy",
            "dd MMM yyyy",
            "yyyy-MM-dd",
            "d MMM yyyy",
            "MMM dd, yyyy"
        ]
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        var parsedDate: Date? = nil
        for format in formatters {
            df.dateFormat = format
            if let parsed = df.date(from: purchaseDateStr) {
                parsedDate = parsed
                break
            }
        }
        
        guard let pDate = parsedDate else {
            return (isActive: true, expirationText: "Valid until 24 nov 2026")
        }
        
        if let futureDate = Calendar.current.date(byAdding: .year, value: 2, to: pDate) {
            let isActive = futureDate > Date()
            df.dateFormat = "d MMM yyyy"
            let dateStr = df.string(from: futureDate).lowercased()
            let text = isActive ? "Valid until \(dateStr)" : "Expired on \(dateStr)"
            return (isActive: isActive, expirationText: text)
        }
        
        return (isActive: true, expirationText: "Valid until 24 nov 2026")
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        StatusBadge(
                            text: created ? LocalizedStringKey("Ticket Created") : (uploadedImages.isEmpty ? LocalizedStringKey("Photo Required") : LocalizedStringKey("Ready to Create")),
                            status: created ? .success : (uploadedImages.isEmpty ? .warning : .pending)
                        )
                        
                        // Client card (read-only)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Client")
                                .font(AppFonts.serif(size: 13, weight: .bold))
                                .foregroundStyle(AppColors.gold)
                                .kerning(0.5)
                            Text("\(client.name) · \(client.tier.rawValue.uppercased()) · Appointment linked")
                                .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.gold.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Serial Number / Selection card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Serial Number")
                                .font(AppFonts.serif(size: 13, weight: .bold))
                                .foregroundStyle(AppColors.gold)
                                .kerning(0.5)
                            
                            if isReadOnly {
                                Text(serial)
                                    .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                            } else {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isDropdownOpen.toggle()
                                    }
                                }) {
                                    HStack {
                                        Text(selectedPurchase?.name ?? "Select Product from History")
                                            .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                            .foregroundStyle(selectedPurchase == nil ? AppColors.secondary : .white)
                                        Spacer()
                                        Image(systemName: isDropdownOpen ? "chevron.up" : "chevron.down")
                                            .font(AppFonts.sansSerif(size: 12, weight: .bold))
                                            .foregroundStyle(AppColors.gold)
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                if isDropdownOpen {
                                    VStack(spacing: 8) {
                                        Divider().background(AppColors.gold.opacity(0.2))
                                        
                                        if clientPurchases.isEmpty {
                                            Text("No purchases found for this client")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.secondary)
                                                .padding(.vertical, 8)
                                        } else {
                                            ForEach(clientPurchases) { p in
                                                let prodId = "PRD-" + String(p.id.uuidString.prefix(8).uppercased())
                                                Button(action: {
                                                    selectedPurchase = p
                                                    serial = prodId
                                                    
                                                    let wInfo = Self.checkWarrantyStatus(purchaseDateStr: p.date)
                                                    dynamicIsWarrantyActive = wInfo.isActive
                                                    dynamicWarrantyText = wInfo.expirationText
                                                    
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        isDropdownOpen = false
                                                    }
                                                }) {
                                                    HStack {
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text(p.name)
                                                                .font(AppFonts.sansSerif(size: 13, weight: .medium))
                                                                .foregroundStyle(.white)
                                                            Text("SN: \(prodId) · \(p.date)")
                                                                .font(AppFonts.sansSerif(size: 11))
                                                                .foregroundStyle(AppColors.secondary)
                                                        }
                                                        Spacer()
                                                        if selectedPurchase?.id == p.id {
                                                            Image(systemName: "checkmark")
                                                                .font(AppFonts.sansSerif(size: 12, weight: .bold))
                                                                .foregroundStyle(AppColors.gold)
                                                        }
                                                    }
                                                    .padding(.vertical, 6)
                                                    .contentShape(Rectangle())
                                                }
                                                .buttonStyle(.plain)
                                                
                                                if p.id != clientPurchases.last?.id {
                                                    Divider().background(AppColors.gold.opacity(0.1))
                                                }
                                            }
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                                
                                if selectedPurchase != nil {
                                    Divider().background(AppColors.gold.opacity(0.2))
                                        .padding(.top, 4)
                                    
                                    HStack {
                                        Text("Serial:")
                                            .font(AppFonts.sansSerif(size: 11))
                                            .foregroundStyle(AppColors.secondary)
                                        Text(serial)
                                            .font(AppFonts.sansSerif(size: 12, weight: .semibold))
                                            .foregroundStyle(AppColors.gold)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(16)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.gold.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Service Details card
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Service Details")
                                .font(AppFonts.serif(size: 13, weight: .bold))
                                .foregroundStyle(AppColors.gold)
                                .kerning(0.5)
                            TextField("Issue and condition notes", text: $issue, axis: .vertical)
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.text)
                                .textFieldStyle(.plain)
                        }
                        .padding(16)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.gold.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Condition Photos card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Condition Photos")
                                .font(AppFonts.serif(size: 13, weight: .bold))
                                .foregroundStyle(AppColors.gold)
                                .kerning(0.5)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showMediaSourceMenu = true
                                        }
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "plus")
                                                .font(AppFonts.sansSerif(size: 20, weight: .medium))
                                                .foregroundStyle(AppColors.gold)
                                            Text("Add Photo")
                                                .font(AppFonts.sansSerif(size: 11, weight: .medium))
                                                .foregroundStyle(AppColors.gold)
                                        }
                                        .frame(width: 92, height: 92)
                                        .background(AppColors.surface2)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(AppColors.gold, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                        )
                                    }
                                    .confirmationDialog("Select Media Source", isPresented: $showMediaSourceMenu, titleVisibility: .hidden) {
                                        Button("Take Photo") {
                                            showCamera = true
                                        }
                                        Button("Choose from Library") {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                showPhotosPicker = true
                                            }
                                        }
                                        Button("Cancel", role: .cancel) {}
                                    }
                                    .buttonStyle(.plain)
                                    
                                    ForEach(Array(uploadedImages.enumerated()), id: \.offset) { index, image in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 92, height: 92)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            
                                            Button(action: {
                                                if index < uploadedImages.count {
                                                    uploadedImages.remove(at: index)
                                                }
                                                if index < selectedItems.count {
                                                    selectedItems.remove(at: index)
                                                }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.white, AppColors.tertiary)
                                                    .font(AppFonts.sansSerif(size: 20))
                                                    .padding(4)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.gold.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Glassmorphic Warranty card
                        if let wText = dynamicWarrantyText {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("WARRANTY")
                                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                    .foregroundStyle(dynamicIsWarrantyActive ? Color(hex: 0xA3E4D7) : Color(hex: 0xF5B7B1))
                                    .kerning(1.5)
                                
                                HStack(spacing: 8) {
                                    Text(dynamicIsWarrantyActive ? "ACTIVE" : "EXPIRED")
                                        .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(dynamicIsWarrantyActive ? Color(hex: 0x3D9E6A).opacity(0.6) : Color(hex: 0xC94C4C).opacity(0.6))
                                        )
                                    
                                    Text(wText)
                                        .font(AppFonts.sansSerif(size: 12, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                ZStack {
                                    dynamicIsWarrantyActive ? Color(hex: 0x3D9E6A).opacity(0.12) : Color(hex: 0xC94C4C).opacity(0.12)
                                    Color.clear.background(.ultraThinMaterial)
                                    LinearGradient(
                                        colors: [.white.opacity(0.18), .white.opacity(0.02), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                dynamicIsWarrantyActive ? Color(hex: 0x3D9E6A).opacity(0.8) : Color(hex: 0xC94C4C).opacity(0.8),
                                                dynamicIsWarrantyActive ? Color(hex: 0x3D9E6A).opacity(0.2) : Color(hex: 0xC94C4C).opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(
                                color: dynamicIsWarrantyActive ? Color(hex: 0x3D9E6A).opacity(0.25) : Color(hex: 0xC94C4C).opacity(0.25),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                        
                        // Action Button
                        Button(action: {
                            guard !uploadedImages.isEmpty else {
                                errorMessage = String(localized: "Please attach at least one photo.")
                                return
                            }
                            guard !serial.isEmpty else { 
                                errorMessage = String(localized: "Serial number is missing")
                                return 
                            }
                            isCreating = true
                            errorMessage = nil
                            
                            Task {
                                do {
                                    guard let profile = try await ProfileService().fetchCurrentProfile() else {
                                        await MainActor.run {
                                            errorMessage = String(localized: "Profile not found")
                                            isCreating = false 
                                        }
                                        return
                                    }
                                    
                                    let boutiqueId: UUID
                                    let creatorName: String
                                    if let staff = profile.1 as? StaffModel, let bid = staff.boutiqueId {
                                        boutiqueId = bid
                                        creatorName = staff.name
                                    } else if let manager = profile.1 as? CorporateBoutique {
                                        boutiqueId = manager.id
                                        creatorName = manager.managerName
                                    } else {
                                        await MainActor.run { 
                                            errorMessage = String(localized: "Boutique ID not found on profile")
                                            isCreating = false 
                                        }
                                        return
                                    }
                                    
                                    guard let pid = selectedPurchase?.id ?? purchaseId else {
                                        await MainActor.run {
                                            errorMessage = String(localized: "Purchase ID is missing")
                                            isCreating = false
                                        }
                                        return
                                    }
                                    
                                    let pItems = try await ASTService.shared.fetchPurchasedItems(for: client.id)
                                    let match = pItems.first(where: { $0.id == pid })
                                    let productId = match?.productId ?? pid
                                    
                                    let astId = UUID()
                                    var photoUrls: [String] = []
                                    
                                    for img in uploadedImages {
                                        // Resize image to prevent massive payload timeouts (Code=-1005)
                                        let targetSize = CGSize(width: 800, height: 800 * (img.size.height / img.size.width))
                                        let renderer = UIGraphicsImageRenderer(size: targetSize)
                                        let resizedImage = renderer.image { _ in
                                            img.draw(in: CGRect(origin: .zero, size: targetSize))
                                        }
                                        
                                        if let data = resizedImage.jpegData(compressionQuality: 0.3) {
                                            let asset = PickedImageAsset(data: data, fileExtension: "jpg", contentType: "image/jpeg")
                                            let url = try await StorageService().uploadASTPhoto(image: asset, astId: astId)
                                            photoUrls.append(url)
                                        }
                                    }
                                    
                                    _ = try await ASTService.shared.createAST(
                                        id: astId,
                                        productId: productId,
                                        clientId: client.id,
                                        boutiqueId: boutiqueId,
                                        warrantyStatus: dynamicWarrantyText ?? "Valid",
                                        description: issue,
                                        remark: "Created via AST Intake UI. \(photoUrls.count) photos uploaded.",
                                        photoUrls: photoUrls,
                                        createdBy: creatorName
                                    )
                                    
                                    await MainActor.run {
                                        created = true
                                        isCreating = false
                                        showSuccessAlert = true
                                    }
                                } catch {
                                    print("Failed to create AST: \(error)")
                                    await MainActor.run { 
                                        errorMessage = error.localizedDescription
                                        isCreating = false 
                                    }
                                }
                            }
                        }) {
                            HStack(spacing: 10) {
                                if isCreating {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "wrench.and.screwdriver")
                                }
                                Text(created ? "Ticket Created" : "Create Service Ticket")
                            }
                            .font(AppFonts.sansSerif(size: 15, weight: .bold))
                            .foregroundStyle(uploadedImages.isEmpty || serial.isEmpty || isCreating ? Color.white.opacity(0.3) : AppColors.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(uploadedImages.isEmpty || serial.isEmpty || isCreating ? Color.white.opacity(0.1) : AppColors.gold)
                            )
                        }
                        .disabled(uploadedImages.isEmpty || serial.isEmpty || isCreating || created)
                        
                        if let errorMsg = errorMessage {
                            Text(errorMsg)
                                .font(AppFonts.sansSerif(size: 13))
                                .foregroundStyle(AppColors.error)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            // Removed custom popup, using native confirmationDialog instead
        }

        .onChange(of: selectedItems) { _, newItems in
            loadImages(from: newItems)
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedItems, matching: .images)
        .sheet(isPresented: $showCamera) {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(AppFonts.sansSerif(size: 50))
                        .foregroundStyle(AppColors.gold)
                    Text("Camera Modal (Placeholder)")
                        .font(AppFonts.serif(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("In a production environment, this would display the device camera capture interface.")
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(AppColors.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Dismiss") {
                        showCamera = false
                    }
                    .font(AppFonts.sansSerif(size: 15, weight: .bold))
                    .foregroundStyle(AppColors.background)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.gold)
                    .clipShape(Capsule())
                }
            }
        }
        .navigationTitle("After-Sales Intake")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Ticket Created", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("The After Sales Ticket has been successfully generated and synced.")
        }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) {
        Task {
            var loadedImages: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    loadedImages.append(uiImage)
                }
            }
            DispatchQueue.main.async {
                self.uploadedImages = loadedImages
            }
        }
    }
}


struct ASTDetails: Codable, Hashable {
    let id: UUID
    let status: String
    let description: String?
    let remark: String?
    let catalogs: CatalogEntity?
    let client: ClientEntity?
}

struct AfterSalesTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    
    let ast: ASTDetails
    
    @State private var astStatus: String
    @State private var fetchedAST: ASTDetails
    
    init(ast: ASTDetails) {
        self.ast = ast
        self._astStatus = State(initialValue: ast.status)
        self._fetchedAST = State(initialValue: ast)
    }
    
    private enum StageState {
        case completed
        case active
        case upcoming
        case failed
    }
    
    private func rank(for status: String) -> Int {
        switch status.lowercased() {
        case "open": return 1
        case "approved": return 2
        case "rejected", "declined": return 2
        case "in_progress": return 3
        case "dispatched": return 4
        case "ready": return 5
        default: return 1
        }
    }
    
    private func rank(for stage: AfterSalesStage) -> Int {
        switch stage {
        case .intake: return 1
        case .managerReview: return 2
        case .inProgress: return 3
        case .dispatched: return 4
        case .ready: return 5
        }
    }
    
    private func stageState(for stage: AfterSalesStage) -> StageState {
        let isRejected = astStatus.lowercased() == "rejected" || astStatus.lowercased() == "declined"
        let statusLower = astStatus.lowercased()
        
        let currentRank = rank(for: astStatus)
        let stageRank = rank(for: stage)
        
        if isRejected {
            if stageRank < 2 { return .completed }
            else if stageRank == 2 { return .failed }
            else { return .upcoming }
        }
        
        if statusLower == "ready" {
            return .completed
        }
        
        if statusLower == "in_progress" {
            if stageRank < 3 { return .completed }
            else if stageRank == 3 { return .active }
            else { return .upcoming }
        }
        
        if statusLower == "dispatched" {
            if stageRank < 4 { return .completed }
            else if stageRank == 4 { return .active }
            else { return .upcoming }
        }
        
        // For "open" and "approved", the current stage is completed, next is active.
        if stageRank <= currentRank {
            return .completed
        } else if stageRank == currentRank + 1 {
            return .active
        } else {
            return .upcoming
        }
    }
    
    private var displayStatusText: String {
        let lower = astStatus.lowercased()
        if lower == "open" { return "Intake" }
        if lower == "approved" { return "Manager Review" }
        if lower == "rejected" || lower == "declined" { return "Declined" }
        if lower == "in_progress" { return "In Progress" }
        if lower == "dispatched" { return "Dispatched" }
        if lower == "ready" { return "Ready" }
        return "Intake"
    }
    
    private var badgeStatus: BadgeStatus {
        let lower = astStatus.lowercased()
        if lower == "ready" { return .success }
        if lower == "rejected" || lower == "declined" { return .error }
        return .pending
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(fetchedAST.catalogs?.name ?? "Service Ticket")
                                .font(AppFonts.serif(size: 22, weight: .medium))
                                .foregroundStyle(.white)
                            Text("\(fetchedAST.client?.name ?? "Unknown Client") · \(fetchedAST.catalogs?.catalogId ?? "Unknown ID")")
                                .font(AppFonts.sansSerif(size: 12))
                                .foregroundStyle(AppColors.secondary)
                            StatusBadge(text: LocalizedStringKey(displayStatusText), status: badgeStatus)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        VStack(spacing: 12) {
                            ForEach(AfterSalesStage.allCases, id: \.self) { stage in
                                let state = stageState(for: stage)
                                HStack(spacing: 12) {
                                    Group {
                                        switch state {
                                        case .completed:
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(AppColors.success)
                                        case .active:
                                            Image(systemName: "clock.fill")
                                                .foregroundStyle(AppColors.gold)
                                        case .failed:
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(AppColors.error)
                                        case .upcoming:
                                            Image(systemName: "circle")
                                                .foregroundStyle(.white.opacity(0.3))
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(LocalizedStringKey(stage.rawValue))
                                            .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                            .foregroundStyle(state == .upcoming ? .white.opacity(0.4) : .white)
                                        
                                        Group {
                                            switch state {
                                            case .completed:
                                                EmptyView()
                                            case .active:
                                                Text("Current stage")
                                                    .foregroundStyle(AppColors.gold)
                                            case .failed:
                                                Text("Declined by Manager")
                                                    .foregroundStyle(AppColors.error)
                                            case .upcoming:
                                                EmptyView()
                                            }
                                        }
                                        .font(AppFonts.sansSerif(size: 11))
                                    }
                                    Spacer()
                                }
                                .padding(14)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .opacity((state == .upcoming || state == .failed) ? 0.6 : 1.0)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationTitle("Service Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            fetchTicketDetails()
        }
    }
    
    private func fetchTicketDetails() {
        Task {
            do {
                let fetchedList: [ASTDetails] = try await SupabaseManager.shared.client
                    .from("ast")
                    .select("*, catalogs(*), client(*)")
                    .eq("id", value: ast.id.uuidString)
                    .execute()
                    .value
                
                if let latestAST = fetchedList.first {
                    await MainActor.run {
                        self.fetchedAST = latestAST
                        self.astStatus = latestAST.status
                    }
                }
            } catch {
                print("Failed to fetch latest AST details: \(error)")
            }
        }
    }
}
