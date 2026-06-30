//
//  ProductDetailView.swift
//  luxury
//
//  Created by Nalinish Ranjan on 21/05/26.
//

import SwiftUI

struct CatalogDetailView: View {
    let catalog: CatalogEntity
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(CatalogsViewModel.self) private var viewModel
    
    @State private var showingDeleteConfirm = false
    @State private var showingBatchScanner = false
    @State private var scannedSerials: [String] = []
    @State private var showingAllSerialsSheet = false
    
    @State private var showingBulkGenerateAlert = false
    @State private var bulkQuantity: String = ""
    
    @State private var inventoryUnits: [InventoryUnitEntity] = []
    @State private var isLoadingInventory = true
    @State private var sortedGroups: [(boutiqueId: UUID, boutiqueName: String, units: [InventoryUnitEntity])] = []
    @State private var soldStats: [(boutiqueName: String, soldCount: Int)] = []
    
    @State private var selectedBoutiqueId: UUID? = nil
    @State private var showingBoutiquePicker = false
    @State private var pendingAction: BoutiqueAction? = nil
    
    enum BoutiqueAction {
        case batchScan
        case bulkGenerate
    }
    
    private var currentCatalog: CatalogEntity {
        viewModel.catalogs.first(where: { $0.id == catalog.id }) ?? catalog
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(currentCatalog.name)
                        .font(AppFonts.serif(size: 24, weight: .bold))
                        .foregroundStyle(AppColors.text)
                    
                    HStack {
                        Text(currentCatalog.brand)
                            .font(AppFonts.sansSerif(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.gold)
                            .kerning(1.5)
                        
                        Spacer()
                        
                        Text(LocalizedStringKey(currentCatalog.status.rawValue)).textCase(.uppercase)
                            .font(AppFonts.sansSerif(size: 10, weight: .bold))
                            .foregroundStyle(statusTextColor(for: currentCatalog.status))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusBackgroundColor(for: currentCatalog.status))
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Catalog Details") {
                LabeledContent("Catalog ID", value: currentCatalog.catalogId)
                LabeledContent("Category", value: currentCatalog.category.rawValue)
                LabeledContent("Description", value: currentCatalog.description)
                LabeledContent("Total Stock", value: isLoadingInventory ? "Loading..." : "\(inventoryUnits.filter { $0.status == .available }.count)")
                LabeledContent("Amount", value: CurrencyManager.shared.format(amount: currentCatalog.amount))
                LabeledContent("Barcode", value: currentCatalog.barCode)
            }
            
            if let images = currentCatalog.productImages, !images.isEmpty {
                Section("Product Images") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(images.enumerated()), id: \.offset) { _, url in
                                if let parsedURL = URL(string: url) {
                                    CachedAsyncImage(url: parsedURL) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        } else if phase.error != nil {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(AppColors.surface)
                                                .frame(width: 100, height: 100)
                                                .overlay(Image(systemName: "photo").foregroundStyle(AppColors.secondary))
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(AppColors.surface)
                                                .frame(width: 100, height: 100)
                                                .overlay(ProgressView())
                                        }
                                    }
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppColors.surface)
                                        .frame(width: 100, height: 100)
                                        .overlay(Image(systemName: "photo").foregroundStyle(AppColors.secondary))
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            
            
            Section("Inventory / Serial Numbers") {
                Button(action: {
                    pendingAction = .batchScan
                    showingBoutiquePicker = true
                }) {
                    HStack {
                        Image(systemName: "plus.viewfinder")
                        Text("Add Product(s) / Scan Serials")
                    }
                    .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.gold)
                    .padding(.vertical, 4)
                }
                
                Button(action: {
                    pendingAction = .bulkGenerate
                    showingBoutiquePicker = true
                }) {
                    HStack {
                        Image(systemName: "number.square.fill")
                        Text("Create Bulk Serial Ids")
                    }
                    .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.gold)
                    .padding(.vertical, 4)
                }
                
                if isLoadingInventory {
                    ProgressView().padding()
                } else if !sortedGroups.isEmpty {
                    ForEach(sortedGroups, id: \.boutiqueId) { group in
                        NavigationLink(destination: BoutiqueSerialsView(
                            boutiqueName: group.boutiqueName,
                            units: group.units,
                            currentCatalog: currentCatalog,
                            onRefresh: { loadInventory() }
                        )) {
                            HStack {
                                Text(group.boutiqueName)
                                    .font(AppFonts.sansSerif(size: 16, weight: .bold))
                                    .foregroundStyle(AppColors.text)
                                Spacer()
                                let available = group.units.filter { $0.status == .available }.count
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(group.units.count) Total")
                                        .font(AppFonts.sansSerif(size: 12))
                                        .foregroundStyle(AppColors.secondary)
                                    Text("\(available) Available")
                                        .font(AppFonts.sansSerif(size: 12, weight: .bold))
                                        .foregroundStyle(AppColors.success)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } else {
                    Text("No physical products added yet.")
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(AppColors.secondary)
                }
            }
            
            if !isLoadingInventory {
                if !soldStats.isEmpty {
                    Section("Sales Performance") {
                        ForEach(soldStats, id: \.boutiqueName) { stat in
                            HStack {
                                Text(stat.boutiqueName)
                                    .font(AppFonts.sansSerif(size: 14))
                                    .foregroundStyle(AppColors.text)
                                Spacer()
                                Text("\(stat.soldCount) Sold")
                                    .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                    .foregroundStyle(AppColors.success)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            
            Section {
                Button(role: .destructive, action: {
                    showingDeleteConfirm = true
                }) {
                    Text("Delete Catalog")
                        .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Catalog Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    router.push(CARoute.catalogForm(editCatalog: currentCatalog))
                }
                .font(AppFonts.sansSerif(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.gold)
            }
        }
        .alert("Delete Catalog", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteCatalog(currentCatalog) {
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this catalog? This action cannot be undone.")
        }
        .fullScreenCover(isPresented: $showingBatchScanner) {
            BatchScannerSheet(scannedSerials: $scannedSerials, existingSerials: inventoryUnits.map { $0.serialNumber }) {
                if !scannedSerials.isEmpty, let bId = selectedBoutiqueId {
                    viewModel.addSerialNumbers(to: currentCatalog, serials: scannedSerials, boutiqueId: bId) {
                        showingBatchScanner = false
                        loadInventory()
                    }
                } else {
                    showingBatchScanner = false
                }
            }
        }
        .sheet(isPresented: $showingBoutiquePicker) {
            NavigationStack {
                List {
                    ForEach(viewModel.boutiques, id: \.id) { boutique in
                        Button(action: {
                            selectedBoutiqueId = boutique.id
                            showingBoutiquePicker = false
                            
                            // Delay presenting new view to allow sheet dismissal
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if pendingAction == .batchScan {
                                    scannedSerials.removeAll()
                                    showingBatchScanner = true
                                } else if pendingAction == .bulkGenerate {
                                    bulkQuantity = ""
                                    showingBulkGenerateAlert = true
                                }
                            }
                        }) {
                            HStack {
                                Text(boutique.name)
                                    .font(AppFonts.sansSerif(size: 16))
                                    .foregroundStyle(AppColors.text)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(AppFonts.sansSerif(size: 14))
                                    .foregroundStyle(AppColors.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Select Boutique")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showingBoutiquePicker = false
                        }
                        .foregroundStyle(AppColors.gold)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .alert("Create Bulk Serial IDs", isPresented: $showingBulkGenerateAlert) {
            TextField("Quantity", text: $bulkQuantity)
                .keyboardType(.numberPad)
            
            Button("Cancel", role: .cancel) { }
            
            Button("Generate") {
                if let quantity = Int(bulkQuantity), quantity > 0 {
                    generateBulkSerials(quantity: quantity)
                }
            }
        } message: {
            Text("Enter the number of random serials to generate for this catalog.")
        }
        .sheet(isPresented: $showingAllSerialsSheet) {
            NavigationStack {
                List {
                    ForEach(inventoryUnits, id: \.id) { unit in
                        HStack {
                            Text(unit.serialNumber)
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.text)
                            Spacer()
                            Text(unit.status.rawValue)
                                .font(AppFonts.sansSerif(size: 10))
                                .foregroundStyle(AppColors.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        let serialsToRemove = indexSet.map { inventoryUnits[$0].serialNumber }
                        viewModel.removeSerialNumbers(serials: serialsToRemove, from: currentCatalog)
                        loadInventory()
                    }
                }
                .navigationTitle("All Serial Numbers")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingAllSerialsSheet = false
                        }
                        .foregroundStyle(AppColors.gold)
                    }
                }
            }
        }
        .onAppear {
            loadInventory()
        }
    }
    
    private func loadInventory() {
        print("[CatalogDetailView] Loading inventory for catalog: \(currentCatalog.catalogId)")
        Task {
            do {
                let units = try await InventoryService.shared.fetchInventory(forCatalog: currentCatalog.id)
                print("[CatalogDetailView] Successfully fetched \(units.count) physical units!")
                
                // Process groupings in background
                let grouped = Dictionary(grouping: units, by: { $0.boutiqueId })
                let newSortedGroups = grouped.map { (key, value) in
                    let name = viewModel.boutiques.first(where: { $0.id == key })?.name ?? "Unknown Boutique"
                    return (boutiqueId: key, boutiqueName: name, units: value)
                }.sorted { $0.boutiqueName < $1.boutiqueName }
                
                let newSoldStats = Dictionary(grouping: units.filter { $0.status == .sold }, by: { $0.boutiqueId })
                    .map { (key, value) in
                        let name = viewModel.boutiques.first(where: { $0.id == key })?.name ?? "Unknown Boutique"
                        return (boutiqueName: name, soldCount: value.count)
                    }
                    .sorted { $0.soldCount > $1.soldCount }
                
                await MainActor.run {
                    self.inventoryUnits = units
                    self.sortedGroups = newSortedGroups
                    self.soldStats = newSoldStats
                    self.isLoadingInventory = false
                }
            } catch {
                print("[CatalogDetailView] ERROR fetching inventory: \(error)")
                await MainActor.run {
                    self.isLoadingInventory = false
                }
            }
        }
    }
    
    private func generateBulkSerials(quantity: Int) {
        let rawPrefix = currentCatalog.catalogId
        var prefix = String(rawPrefix.prefix(4)).uppercased()
        
        while prefix.count < 4 {
            prefix.append("0")
        }
        
        let existingSerials = Set(inventoryUnits.map { $0.serialNumber })
        var newSerials: [String] = []
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        while newSerials.count < quantity {
            let random16 = String((0..<16).map { _ in characters.randomElement()! })
            let generatedSerial = "\(prefix)\(random16)"
            
            if !existingSerials.contains(generatedSerial) && !newSerials.contains(generatedSerial) {
                newSerials.append(generatedSerial)
            }
        }
        
        if let bId = selectedBoutiqueId {
            viewModel.addSerialNumbers(to: currentCatalog, serials: newSerials, boutiqueId: bId) {
                loadInventory()
            }
        }
    }
    
    private func statusTextColor(for status: CatalogStatus) -> Color {
        switch status {
        case .active: return AppColors.success
        case .paused: return AppColors.gold
        case .archived: return AppColors.error
        }
    }
    
    private func statusBackgroundColor(for status: CatalogStatus) -> Color {
        statusTextColor(for: status).opacity(0.1)
    }
}

struct BoutiqueSerialsView: View {
    let boutiqueName: String
    let units: [InventoryUnitEntity]
    let currentCatalog: CatalogEntity
    let onRefresh: () -> Void
    @Environment(CatalogsViewModel.self) private var viewModel
    
    @State private var searchText = ""
    
    var filteredUnits: [InventoryUnitEntity] {
        if searchText.isEmpty { return units }
        return units.filter { $0.serialNumber.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List {
            ForEach(filteredUnits, id: \.id) { unit in
                HStack {
                    Text(unit.serialNumber)
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(AppColors.text)
                    Spacer()
                    Text(unit.status.rawValue)
                        .font(AppFonts.sansSerif(size: 10))
                        .foregroundStyle(unit.status == .available ? AppColors.success : AppColors.secondary)
                }
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                let serialsToRemove = indexSet.map { filteredUnits[$0].serialNumber }
                viewModel.removeSerialNumbers(serials: serialsToRemove, from: currentCatalog)
                onRefresh()
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.defaultMinListHeaderHeight, 0)
        .padding(.top, -24)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search serial numbers")
        .navigationTitle(boutiqueName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
