import SwiftUI
import PhotosUI

struct PlanogramManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PlanogramManagementViewModel()
    @State private var isShowingCreateSheet = false
    @State private var editingPlanogram: PlanogramEntity? = nil
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(AppFonts.sansSerif(size: 20, weight: .semibold))
                                .foregroundStyle(AppColors.gold)
                        }
                        Spacer()
                        Button(action: {
                            isShowingCreateSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(AppFonts.sansSerif(size: 20, weight: .semibold))
                                .foregroundStyle(AppColors.gold)
                        }
                    }
                    
                    Text("Planograms")
                        .font(AppFonts.sansSerif(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.text)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(AppColors.gold)
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else if viewModel.planograms.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "photo.artframe")
                            .font(.system(size: 60, weight: .light))
                            .foregroundStyle(AppColors.gold.opacity(0.8))
                        Text("No planograms active")
                            .font(AppFonts.serif(size: 24, weight: .medium))
                            .foregroundStyle(AppColors.text)
                        Text("Create a new planogram to direct your boutiques on visual merchandising.")
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(AppColors.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 20)], spacing: 20) {
                            ForEach(viewModel.planograms) { planogram in
                                PlanogramAdminCard(
                                    planogram: planogram,
                                    boutiques: viewModel.boutiques,
                                    onEdit: {
                                        editingPlanogram = planogram
                                    },
                                    onDelete: {
                                        Task {
                                            await viewModel.deletePlanogram(id: planogram.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(24)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.fetchData()
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            PlanogramFormSheet(viewModel: viewModel, editingPlanogram: nil)
        }
        .sheet(item: $editingPlanogram) { planogram in
            PlanogramFormSheet(viewModel: viewModel, editingPlanogram: planogram)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct PlanogramAdminCard: View {
    let planogram: PlanogramEntity
    let boutiques: [CorporateBoutique]
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CachedAsyncImage(url: URL(string: planogram.fileUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(AppColors.surface)
                    .frame(height: 180)
                    .overlay(ProgressView().tint(AppColors.gold))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(planogram.title)
                        .font(AppFonts.sansSerif(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.text)
                    Spacer()
                    Menu {
                        Button("Edit", action: onEdit)
                        Button("Delete", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(AppColors.secondary)
                    }
                }
                
                if let desc = planogram.description {
                    Text(desc)
                        .font(AppFonts.sansSerif(size: 13))
                        .foregroundStyle(AppColors.secondary)
                        .lineLimit(2)
                }
                
                Divider().background(AppColors.gold15).padding(.vertical, 4)
                
                HStack {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(AppColors.gold)
                        .font(.system(size: 12))
                    Text(targetStoreText)
                        .font(AppFonts.sansSerif(size: 12))
                        .foregroundStyle(AppColors.tertiary)
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(AppColors.gold)
                        .font(.system(size: 12))
                    Text(formatDate(planogram.validUntil))
                        .font(AppFonts.sansSerif(size: 12))
                        .foregroundStyle(AppColors.tertiary)
                }
            }
            .padding(16)
            .background(AppColors.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    private var targetStoreText: String {
        guard let bId = planogram.boutiqueId else { return "All Boutiques" }
        return boutiques.first(where: { $0.id == bId })?.name ?? "Unknown Boutique"
    }
    
    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return isoString }
        let out = DateFormatter()
        out.dateStyle = .medium
        return "Valid until \(out.string(from: date))"
    }
}

struct PlanogramFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: PlanogramManagementViewModel
    let editingPlanogram: PlanogramEntity?
    
    @State private var title: String
    @State private var description: String
    @State private var selectedBoutiqueId: UUID?
    @State private var validFrom: Date
    @State private var validUntil: Date
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    init(viewModel: PlanogramManagementViewModel, editingPlanogram: PlanogramEntity?) {
        self.viewModel = viewModel
        self.editingPlanogram = editingPlanogram
        
        let formatter = ISO8601DateFormatter()
        
        _title = State(initialValue: editingPlanogram?.title ?? "")
        _description = State(initialValue: editingPlanogram?.description ?? "")
        _selectedBoutiqueId = State(initialValue: editingPlanogram?.boutiqueId)
        
        if let from = editingPlanogram?.validFrom, let fDate = formatter.date(from: from) {
            _validFrom = State(initialValue: fDate)
        } else {
            _validFrom = State(initialValue: Date())
        }
        
        if let until = editingPlanogram?.validUntil, let uDate = formatter.date(from: until) {
            _validUntil = State(initialValue: uDate)
        } else {
            _validUntil = State(initialValue: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date())
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Details").foregroundStyle(AppColors.gold)) {
                    TextField("Title", text: $title)
                    TextField("Description (Optional)", text: $description)
                }
                .listRowBackground(AppColors.surface)
                
                Section(header: Text("Target Store").foregroundStyle(AppColors.gold)) {
                    Picker("Boutique", selection: $selectedBoutiqueId) {
                        Text("All Boutiques").tag(UUID?.none)
                        ForEach(viewModel.boutiques) { b in
                            Text(b.name).tag(Optional(b.id))
                        }
                    }
                }
                .listRowBackground(AppColors.surface)
                
                Section(header: Text("Validity").foregroundStyle(AppColors.gold)) {
                    DatePicker("Valid From", selection: $validFrom, displayedComponents: .date)
                    DatePicker("Valid Until", selection: $validUntil, displayedComponents: .date)
                }
                .listRowBackground(AppColors.surface)
                
                Section(header: Text("Image").foregroundStyle(AppColors.gold)) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo")
                            Text(selectedImageData == nil ? "Select Image" : "Image Selected")
                        }
                        .foregroundStyle(AppColors.gold)
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImageData = uiImage.jpegData(compressionQuality: 0.6)
                            }
                        }
                    }
                    
                    if let data = selectedImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else if let editingPlanogram = editingPlanogram {
                        CachedAsyncImage(url: URL(string: editingPlanogram.fileUrl)) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }
                .listRowBackground(AppColors.surface)
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(editingPlanogram == nil ? "New Planogram" : "Edit Planogram")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColors.gold)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if let existing = editingPlanogram {
                                let success = await viewModel.updatePlanogram(
                                    id: existing.id,
                                    title: title,
                                    description: description,
                                    boutiqueId: selectedBoutiqueId,
                                    validFrom: validFrom,
                                    validUntil: validUntil,
                                    imageData: selectedImageData,
                                    existingFileUrl: existing.fileUrl
                                )
                                if success { dismiss() }
                            } else {
                                guard let data = selectedImageData else { return }
                                let success = await viewModel.uploadPlanogram(
                                    title: title,
                                    description: description,
                                    boutiqueId: selectedBoutiqueId,
                                    validFrom: validFrom,
                                    validUntil: validUntil,
                                    imageData: data
                                )
                                if success { dismiss() }
                            }
                        }
                    }
                    .foregroundStyle(AppColors.gold)
                    .disabled(title.isEmpty || (editingPlanogram == nil && selectedImageData == nil) || viewModel.isUploading)
                }
            }
            .overlay {
                if viewModel.isUploading {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        ProgressView("Uploading...")
                            .padding()
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(AppColors.gold)
                            .tint(AppColors.gold)
                    }
                }
            }
        }
    }
}
