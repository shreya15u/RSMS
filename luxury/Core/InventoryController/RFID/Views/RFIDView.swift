//
//  RFIDView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct RFIDView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = RFIDViewModel()
    @State private var showingProductSelection = false
    @State private var showingScanner = false
    @State private var selectedCatalog: CatalogEntity?
    @State private var scannedSerials: [String] = []
    @State private var damagedItems: [DamagedDeliveryItemDraft] = []
    
    @AppStorage("saved_scanned_serials") private var savedScannedSerialsRaw: String = ""
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Scan")
                
                VStack(spacing: 20) {
                    CustomButton(
                        title: scannedSerials.isEmpty ? "Start New Scan Session" : "Resume Scan Session (\(scannedSerials.count) items)",
                        icon: AnyView(Image(systemName: "barcode.viewfinder"))
                    ) {
                        showingProductSelection = true
                    }
                    
                    Text("Point device at QR or Barcodes to track")
                        .font(AppFonts.sansSerif(size: 12))
                        .foregroundStyle(AppColors.secondary)
                }
                .padding(24)
                .padding(.bottom, 8)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("RECENT SCAN SESSIONS")
                            .font(AppFonts.sansSerif(size: 11, weight: .bold))
                            .foregroundStyle(AppColors.secondary)
                            .kerning(1.5)
                        
                        if viewModel.recentSessions.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(AppFonts.sansSerif(size: 32))
                                    .foregroundStyle(AppColors.secondary)
                                
                                Text("No recent scan sessions")
                                    .font(AppFonts.sansSerif(size: 14))
                                    .foregroundStyle(AppColors.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            VStack(spacing: 12) {
                                ForEach(viewModel.recentSessions) { session in
                                    Button(action: { router.presentFullScreen(ICRoute.scanSessionDetail(session)) }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(session.zone)
                                                    .font(AppFonts.serif(size: 18, weight: .medium))
                                                    .foregroundStyle(AppColors.text)
                                                Text(session.date)
                                                    .font(AppFonts.sansSerif(size: 12))
                                                    .foregroundStyle(AppColors.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text("\(session.scannedCount)")
                                                    .font(AppFonts.sansSerif(size: 18, weight: .semibold))
                                                    .foregroundStyle(AppColors.success)
                                                Text("Items")
                                                    .font(AppFonts.sansSerif(size: 10))
                                                    .foregroundStyle(AppColors.tertiary)
                                            }
                                        }
                                        .padding(16)
                                        .background(AppColors.surface2)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppColors.surface.opacity(0.5), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingProductSelection) {
            ProductSelectionSheet(viewModel: viewModel) { catalog in
                selectedCatalog = catalog
                damagedItems = []
                showingScanner = true
            }
        }
        .fullScreenCover(isPresented: $showingScanner) {
            BatchScannerSheet(
                scannedSerials: $scannedSerials,
                existingSerials: [],
                allowsDamageReporting: true,
                damagedItems: $damagedItems,
                productName: selectedCatalog?.name ?? ""
            ) {
                showingScanner = false
                if let catalog = selectedCatalog, (!scannedSerials.isEmpty || !damagedItems.isEmpty) {
                    let damagedSerials = Set(damagedItems.map(\.serial))
                    let acceptedSerials = scannedSerials.filter { !damagedSerials.contains($0) }
                    viewModel.saveDeliveryItems(to: catalog, acceptedSerials: acceptedSerials, damagedItems: damagedItems) {
                        scannedSerials.removeAll()
                        damagedItems.removeAll()
                        selectedCatalog = nil
                    }
                } else {
                    scannedSerials.removeAll()
                    damagedItems.removeAll()
                    selectedCatalog = nil
                }
            }
        }
        .onAppear {
            if !savedScannedSerialsRaw.isEmpty {
                scannedSerials = savedScannedSerialsRaw.components(separatedBy: ",")
            }
        }
        .onChange(of: scannedSerials) { _, newValue in
            savedScannedSerialsRaw = newValue.joined(separator: ",")
        }
    }
}
