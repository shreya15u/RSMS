//
//  ProductFormView.swift
//  luxury
//
//  Created by Nalinish Ranjan on 21/05/26.
//

import SwiftUI
import PhotosUI

struct CatalogFormView: View {
    @Environment(CatalogsViewModel.self) private var viewModel
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    
    var editCatalog: CatalogEntity?
    
    @State private var showingScanner = false
    @State private var scannerService = ScannerService()
    
    @State private var showSaveAlert = false
    @State private var showDeleteImageAlert = false
    @State private var showUnsavedChangesAlert = false
    @State private var pendingImageToDelete: Int? = nil
    @State private var pendingImageType: ImageType? = nil
    
    enum ImageType {
        case existing
        case new
    }
    
    var body: some View {
        @Bindable var bindableViewModel = viewModel
        
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {

                        
                        Text(editCatalog != nil ? "Edit\nCatalog." : "Catalog\nEntry.")
                            .font(AppFonts.serif(size: 52, weight: .light))
                            .italic()
                            .foregroundStyle(AppColors.text)
                            .lineSpacing(-5)
                            .padding(.bottom, 16)
                        
                        Text(editCatalog != nil ? "Update the details for this catalog" : "Add a new catalog item")
                            .font(AppFonts.sansSerif(size: 13, weight: .light))
                            .foregroundStyle(AppColors.secondary)
                            .padding(.bottom, 40)
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(AppFonts.sansSerif(size: 12))
                            .foregroundStyle(AppColors.error)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 16)
                    }
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        CatalogFormTextField(title: "CATALOG NAME", text: $bindableViewModel.newName)
                        CatalogFormTextField(title: "DESCRIPTION", text: $bindableViewModel.newDescription)
                        CatalogFormTextField(title: "BRAND", text: $bindableViewModel.newBrand)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CATEGORY")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                            
                            Menu {
                                ForEach(CatalogCategory.allCases, id: \.self) { category in
                                    Button(category.rawValue) {
                                        bindableViewModel.newCategory = category
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(LocalizedStringKey(viewModel.newCategory.rawValue))
                                        .font(AppFonts.sansSerif(size: 15))
                                        .foregroundStyle(AppColors.text)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(AppFonts.sansSerif(size: 12))
                                        .foregroundStyle(AppColors.secondary)
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 18)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 1))
                            }
                        }
                        
                        HStack(spacing: 16) {
                            CatalogFormTextField(title: "AMOUNT (\(CurrencyManager.shared.symbol))", text: $bindableViewModel.newAmount, keyboardType: .decimalPad)
                        }
                        
                        if editCatalog != nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("STATUS")
                                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1.5)
                                
                                Menu {
                                    ForEach([CatalogStatus.active, .paused], id: \.self) { status in
                                        Button(status.rawValue) {
                                            bindableViewModel.newStatus = status
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(LocalizedStringKey(viewModel.newStatus.rawValue))
                                            .font(AppFonts.sansSerif(size: 15))
                                            .foregroundStyle(viewModel.newStatus == .active ? AppColors.success : AppColors.gold)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(AppFonts.sansSerif(size: 12))
                                            .foregroundStyle(AppColors.secondary)
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 18)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 1))
                                }
                            }
                        }
                    }
                    .padding(.bottom, 32)
                    
                    // Product Images Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("PRODUCT IMAGES")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                            
                            Spacer()
                            
                            PhotosPicker(
                                selection: $bindableViewModel.selectedPhotoItems,
                                maxSelectionCount: 8,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Text("Select Photos (Max 8)")
                                    .font(AppFonts.sansSerif(size: 12, weight: .semibold))
                                    .foregroundStyle(AppColors.gold)
                            }
                            .onChange(of: viewModel.selectedPhotoItems) { _, _ in
                                viewModel.loadSelectedImages()
                            }
                        }
                        
                        if !viewModel.existingImageURLs.isEmpty || !viewModel.selectedPhotoItems.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(viewModel.existingImageURLs.enumerated()), id: \.offset) { index, url in
                                        if let parsedURL = URL(string: url) {
                                            CachedAsyncImage(url: parsedURL) { phase in
                                                if let image = phase.image {
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 80, height: 80)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                        .overlay(alignment: .topTrailing) {
                                                            Button(action: {
                                                                pendingImageToDelete = index
                                                                pendingImageType = .existing
                                                                showDeleteImageAlert = true
                                                            }) {
                                                                Image(systemName: "xmark.circle.fill")
                                                                    .font(AppFonts.sansSerif(size: 20))
                                                                    .foregroundStyle(AppColors.error)
                                                                    .background(Circle().fill(Color.white).frame(width: 16, height: 16))
                                                                    .padding(4)
                                                            }
                                                        }
                                                } else if phase.error != nil {
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(AppColors.surface)
                                                        .frame(width: 80, height: 80)
                                                        .overlay(Image(systemName: "photo").foregroundStyle(AppColors.secondary))
                                                } else {
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(AppColors.surface)
                                                        .frame(width: 80, height: 80)
                                                        .overlay(ProgressView())
                                                }
                                            }
                                        } else {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(AppColors.surface)
                                                .frame(width: 80, height: 80)
                                                .overlay(Image(systemName: "photo").foregroundStyle(AppColors.secondary))
                                        }
                                    }
                                    
                                    ForEach(Array(viewModel.selectedImagesData.enumerated()), id: \.offset) { index, data in
                                        if let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(alignment: .topTrailing) {
                                                    Button(action: {
                                                        pendingImageToDelete = index
                                                        pendingImageType = .new
                                                        showDeleteImageAlert = true
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .font(AppFonts.sansSerif(size: 20))
                                                            .foregroundStyle(AppColors.error)
                                                            .background(Circle().fill(Color.white).frame(width: 16, height: 16))
                                                            .padding(4)
                                                    }
                                                }
                                        } else {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(AppColors.surface)
                                                .frame(width: 80, height: 80)
                                                .overlay(
                                                    Image(systemName: "photo")
                                                        .foregroundStyle(AppColors.secondary)
                                                )
                                        }
                                    }
                                }
                            }
                        } else {
                            Text("No images selected")
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.tertiary)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.bottom, 32)
                    
                    // Save Button
                    if editCatalog != nil {
                        CustomButton(title: "Save Changes", isLoading: viewModel.isSaving) {
                            showSaveAlert = true
                        }
                    } else {
                        CustomButton(title: "Scan QR & Save", icon: AnyView(Image(systemName: "qrcode.viewfinder")), isLoading: viewModel.isSaving) {
                            showingScanner = true
                        }
                    }
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 28)
            }
        }
        .navigationTitle(editCatalog != nil ? "Edit Catalog" : "New Catalog")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $showingScanner) {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    QRScannerView(scannerService: scannerService)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
            .toolbar(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .navigationTitle("Scan QR")
            .onAppear {
                scannerService.continuousMode = false
                scannerService.onScannedCode = { code in
                    showingScanner = false
                    bindableViewModel.newBarCode = code
                    viewModel.addCatalog {
                        router.pop() // Return to catalogs list after saving
                    }
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            if let catalog = editCatalog {
                viewModel.populateForm(with: catalog)
            } else {
                viewModel.resetForm()
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    if viewModel.hasUnsavedChanges(comparedTo: editCatalog) {
                        showUnsavedChangesAlert = true
                    } else {
                        dismiss()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.backward")
                        Text("Back")
                    }
                }
            }
        }
        .alert("Unsaved Changes", isPresented: $showUnsavedChangesAlert) {
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Are you sure you want to go back? Your changes will be lost.")
        }
        .alert("Save Changes", isPresented: $showSaveAlert) {
            Button("Save", role: .none) {
                if let catalog = editCatalog {
                    viewModel.updateCatalog(catalog) {
                        router.pop()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to save these changes?")
        }
        .alert("Delete Image", isPresented: $showDeleteImageAlert) {
            Button("Delete", role: .destructive) {
                if let index = pendingImageToDelete, let type = pendingImageType {
                    if type == .existing {
                        viewModel.removeExistingImage(at: index)
                    } else {
                        viewModel.removeSelectedImage(at: index)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this image?")
        }
    }
}

private struct CatalogFormTextField: View {
    let title: String
    var placeholder: String = ""
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                .foregroundStyle(AppColors.secondary)
                .kerning(1.5)
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(AppColors.tertiary))
                .font(AppFonts.sansSerif(size: 15))
                .foregroundStyle(AppColors.text)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.vertical, 16)
                .padding(.horizontal, 18)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.gold15, lineWidth: 1)
                )
        }
    }
}
