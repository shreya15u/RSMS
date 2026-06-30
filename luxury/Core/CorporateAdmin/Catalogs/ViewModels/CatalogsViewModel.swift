//
//  CatalogsViewModel.swift
//  luxury
//
//  Created by Nalinish Ranjan on 21/05/26.
//

import Foundation
import Observation
import PhotosUI
import SwiftUI
import Supabase
import PostgREST

@Observable
final class CatalogsViewModel {
    var searchText: String = ""
    var catalogs: [CatalogEntity] = []
    var boutiques: [CorporateBoutique] = []
    var stockLevels: [UUID: Int] = [:]
    
    var isLoading = false
    var isSaving = false
    var errorMessage: String?
    
    // Form fields
    var newName: String = ""
    var newDescription: String = ""
    var newBrand: String = ""
    var newCategory: CatalogCategory = .watches
    var newAmount: String = ""
    var newBarCode: String = ""
    var newStatus: CatalogStatus = .active
    
    // Image fields
    var selectedPhotoItems: [PhotosPickerItem] = []
    var existingImageURLs: [String] = []
    var selectedImagesData: [Data] = []
    
    var showScanner = false
    
    private let catalogService = CatalogService()
    private let imagePickerService = ImagePickerService()
    private let storageService = StorageService()
    
    var filteredCatalogs: [CatalogEntity] {
        if searchText.isEmpty {
            return catalogs
        }
        return catalogs.filter { catalog in
            catalog.name.localizedCaseInsensitiveContains(searchText) ||
            catalog.brand.localizedCaseInsensitiveContains(searchText) ||
            catalog.catalogId.localizedCaseInsensitiveContains(searchText) ||
            catalog.barCode.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func fetchData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedCatalogs = try await catalogService.fetchCatalogs()
                let fetchedBoutiques: [CorporateBoutique] = try await SupabaseManager.shared.client
                    .from("boutiques")
                    .select()
                    .execute()
                    .value
                
                await MainActor.run {
                    self.catalogs = fetchedCatalogs.reversed() // Show newest first
                    self.boutiques = fetchedBoutiques
                    self.isLoading = false
                }
                
                let fetchedInventory = try await InventoryService.shared.fetchGlobalInventory()
                var newStockLevels: [UUID: Int] = [:]
                for unit in fetchedInventory where unit.status == .available {
                    newStockLevels[unit.catalogId, default: 0] += 1
                }
                
                await MainActor.run {
                    self.stockLevels = newStockLevels
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to load data: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
    
    func addCatalog(completion: @escaping () -> Void) {
        guard let amountStr = Double(newAmount) else {
            self.errorMessage = String(localized: "Invalid amount.")
            return
        }
        let amount = CurrencyManager.shared.baseAmount(fromConverted: amountStr)
        
        guard !newBarCode.isEmpty else {
            self.errorMessage = String(localized: "QR/Barcode string is required.")
            return
        }
        
        if catalogs.contains(where: { $0.catalogId == newBarCode }) {
            self.errorMessage = String(localized: "Duplicate catalog detected! A catalog with this barcode already exists.")
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        let newCatalog = CatalogEntity(
            id: UUID(),
            catalogId: newBarCode, // Treat fetched string as catalogId
            name: newName,
            description: newDescription,
            brand: newBrand,
            category: newCategory,
            amount: amount,
            barCode: newBarCode,
            status: newStatus,
            productImages: nil
        )
        
        Task {
            do {
                // Upload images first
                var uploadedURLs: [String] = []
                
                for item in selectedPhotoItems {
                    if let asset = try? await imagePickerService.loadImage(from: item) {
                        if let url = try? await storageService.uploadCatalogImage(image: asset) {
                            uploadedURLs.append(url)
                        }
                    }
                }
                
                var catalogToSave = newCatalog
                catalogToSave.productImages = uploadedURLs
                
                try await catalogService.addCatalog(catalogToSave)
                SystemLogService.shared.logAction(category: .inventory, severity: .info, message: "Added new catalog \(catalogToSave.name) (\(catalogToSave.catalogId))")
                await MainActor.run {
                    self.catalogs.insert(catalogToSave, at: 0)
                    self.isSaving = false
                    self.resetForm()
                    completion()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to add catalog: \(error.localizedDescription)")
                    self.isSaving = false
                }
            }
        }
    }
    
    func populateForm(with catalog: CatalogEntity) {
        newName = catalog.name
        newDescription = catalog.description
        newBrand = catalog.brand
        newCategory = catalog.category
        
        let convertedAmt = CurrencyManager.shared.convertedAmount(fromINR: catalog.amount)
        newAmount = convertedAmt.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", convertedAmt) : String(format: "%.2f", convertedAmt)
        newBarCode = catalog.barCode
        newStatus = catalog.status
        existingImageURLs = catalog.productImages ?? []
        selectedPhotoItems = []
    }
    
    func updateCatalog(_ existingCatalog: CatalogEntity, completion: @escaping () -> Void) {
        guard let amountStr = Double(newAmount) else {
            self.errorMessage = String(localized: "Invalid amount.")
            return
        }
        let amount = CurrencyManager.shared.baseAmount(fromConverted: amountStr)
        
        isSaving = true
        errorMessage = nil
        
        let updatedCatalog = CatalogEntity(
            id: existingCatalog.id,
            catalogId: existingCatalog.catalogId,
            name: newName,
            description: newDescription,
            brand: newBrand,
            category: newCategory,
            amount: amount,
            barCode: newBarCode,
            status: newStatus,
            productImages: existingCatalog.productImages
        )
        
        Task {
            do {
                // Upload new images
                var uploadedURLs: [String] = existingImageURLs
                
                for item in selectedPhotoItems {
                    if let asset = try? await imagePickerService.loadImage(from: item) {
                        if let url = try? await storageService.uploadCatalogImage(image: asset) {
                            uploadedURLs.append(url)
                        }
                    }
                }
                
                var catalogToUpdate = updatedCatalog
                catalogToUpdate.productImages = uploadedURLs
                
                try await catalogService.updateCatalog(catalogToUpdate)
                SystemLogService.shared.logAction(category: .inventory, severity: .info, message: "Updated catalog \(catalogToUpdate.name) (\(catalogToUpdate.catalogId))")
                await MainActor.run {
                    if let index = self.catalogs.firstIndex(where: { $0.id == updatedCatalog.id }) {
                        self.catalogs[index] = catalogToUpdate
                    }
                    self.isSaving = false
                    self.resetForm()
                    completion()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to update catalog: \(error.localizedDescription)")
                    self.isSaving = false
                }
            }
        }
    }
    
    func deleteCatalog(_ catalog: CatalogEntity, completion: @escaping () -> Void) {
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                try await catalogService.deleteCatalog(id: catalog.id)
                SystemLogService.shared.logAction(category: .inventory, severity: .warning, message: "Deleted catalog \(catalog.name) (\(catalog.catalogId))")
                await MainActor.run {
                    self.catalogs.removeAll { $0.id == catalog.id }
                    self.isSaving = false
                    completion()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to delete catalog: \(error.localizedDescription)")
                    self.isSaving = false
                }
            }
        }
    }
    
    func addSerialNumbers(to catalog: CatalogEntity, serials: [String], boutiqueId: UUID, completion: @escaping () -> Void) {
        isSaving = true
        errorMessage = nil
        
        let newUnits = serials.map { serial in
            InventoryUnitEntity(
                id: UUID(),
                catalogId: catalog.id,
                boutiqueId: boutiqueId,
                serialNumber: serial,
                status: .available,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        Task {
            print("[CatalogsViewModel] Starting bulk creation of \(newUnits.count) units...")
            do {
                try await InventoryService.shared.createInventoryUnits(newUnits)
                print("[CatalogsViewModel] Successfully created \(newUnits.count) units in Supabase.")
                SystemLogService.shared.logAction(category: .inventory, severity: .info, message: "Added \(serials.count) serial numbers to catalog \(catalog.name) for boutique \(boutiqueId)")
                await MainActor.run {
                    self.stockLevels[catalog.id, default: 0] += newUnits.count
                    self.isSaving = false
                    completion()
                }
            } catch {
                print("[CatalogsViewModel] ERROR creating units: \(error)")
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to add products: \(error.localizedDescription)")
                    self.isSaving = false
                }
            }
        }
    }
    
    func removeSerialNumbers(serials: [String], from catalog: CatalogEntity) {
        Task {
            do {
                try await InventoryService.shared.deleteInventoryUnits(serials: serials)
                SystemLogService.shared.logAction(category: .inventory, severity: .warning, message: "Removed \(serials.count) serial numbers from catalog \(catalog.name) (\(catalog.catalogId))")
                await MainActor.run {
                    self.stockLevels[catalog.id, default: 0] = max(0, self.stockLevels[catalog.id, default: 0] - serials.count)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to remove products: \(error.localizedDescription)")
                }
            }
        }
    }

    func removeImage(at index: Int, from catalog: CatalogEntity) {
        var updatedCatalog = catalog
        var images = updatedCatalog.productImages ?? []
        guard index >= 0 && index < images.count else { return }
        
        images.remove(at: index)
        updatedCatalog.productImages = images
        
        Task {
            do {
                try await catalogService.updateCatalog(updatedCatalog)
                await MainActor.run {
                    if let idx = self.catalogs.firstIndex(where: { $0.id == updatedCatalog.id }) {
                        self.catalogs[idx] = updatedCatalog
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to remove image: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func resetForm() {
        newName = ""
        newDescription = ""
        newBrand = ""
        newCategory = .watches
        newAmount = ""
        newBarCode = ""
        newStatus = .active
        existingImageURLs = []
        selectedPhotoItems = []
        selectedImagesData = []
    }
    
    func removeExistingImage(at index: Int) {
        guard index >= 0 && index < existingImageURLs.count else { return }
        existingImageURLs.remove(at: index)
    }
    
    func removeSelectedImage(at index: Int) {
        guard index >= 0 && index < selectedImagesData.count else { return }
        selectedImagesData.remove(at: index)
        selectedPhotoItems.remove(at: index)
    }
    
    func loadSelectedImages() {
        Task {
            var loadedData: [Data] = []
            for item in selectedPhotoItems {
                if let asset = try? await imagePickerService.loadImage(from: item) {
                    loadedData.append(asset.data)
                }
            }
            await MainActor.run {
                self.selectedImagesData = loadedData
            }
        }
    }
    
    func hasUnsavedChanges(comparedTo editCatalog: CatalogEntity?) -> Bool {
        if let catalog = editCatalog {
            let parsedAmount = CurrencyManager.shared.baseAmount(fromConverted: Double(newAmount) ?? 0.0)
            return newName != catalog.name ||
                   newDescription != catalog.description ||
                   newBrand != catalog.brand ||
                   newCategory != catalog.category ||
                   parsedAmount != catalog.amount ||
                   newBarCode != catalog.barCode ||
                   newStatus != catalog.status ||
                   existingImageURLs != (catalog.productImages ?? []) ||
                   !selectedPhotoItems.isEmpty
        } else {
            return !newName.isEmpty ||
                   !newDescription.isEmpty ||
                   !newBrand.isEmpty ||
                   !newAmount.isEmpty ||
                   !newBarCode.isEmpty ||
                   !existingImageURLs.isEmpty ||
                   !selectedPhotoItems.isEmpty
        }
    }
}
