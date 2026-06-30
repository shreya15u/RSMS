//
//  VarianceReportView.swift
//  luxury
//
//  Created by Nalinish Ranjan on 27/05/26.
//

import SwiftUI
import Supabase

struct VarianceReportView: View {
    @Environment(\.dismiss) private var dismiss
    let audit: RSMSCycleCount
    
    @State private var dbAudit: DBStoreAudit?
    @State private var verifiedItems: [YetToScanItem] = []
    @State private var isLoadingVerified = false
    
    @State private var missingExpanded = true
    @State private var newExpanded = true
    @State private var successfulExpanded = false
    
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    
    private var report: VarianceReport {
        if let session = AuditPersistence.shared.loadSession(id: audit.id), let rep = session.varianceReport {
            return rep
        }
        return VarianceReport(
            id: audit.id,
            boutiqueName: audit.scope,
            date: Date(),
            controllerName: "Unknown",
            items: []
        )
    }
    
    private var filteredItems: [VarianceReportItem] {
        var list: [VarianceReportItem] = []
        for item in missingItems {
            list.append(
                VarianceReportItem(
                    id: UUID(),
                    productName: item.name ?? "Unknown Item",
                    sku: item.detail ?? "Missing",
                    expectedQty: 1,
                    countedQty: 0,
                    variance: -1,
                    isArchivedProduct: false
                )
            )
        }
        for item in newItems {
            list.append(
                VarianceReportItem(
                    id: UUID(),
                    productName: item.name ?? "Unknown Item",
                    sku: item.detail ?? "New",
                    expectedQty: 0,
                    countedQty: 1,
                    variance: 1,
                    isArchivedProduct: false
                )
            )
        }
        for item in verifiedItems {
            list.append(
                VarianceReportItem(
                    id: UUID(),
                    productName: item.name,
                    sku: "Serial: \(item.serialNumber)",
                    expectedQty: 1,
                    countedQty: 1,
                    variance: 0,
                    isArchivedProduct: false
                )
            )
        }
        return list.sorted { abs($0.variance) > abs($1.variance) }
    }
    
    private var missingItems: [DiscrepancyItem] {
        dbAudit?.discrepancies?.filter { $0.type == "missing" } ?? []
    }
    
    private var newItems: [DiscrepancyItem] {
        dbAudit?.discrepancies?.filter { $0.type == "new" } ?? []
    }
    
    private func fetchVerifiedItems() async {
        guard let scannedUnitIds = dbAudit?.scannedUnitIds, !scannedUnitIds.isEmpty else { return }
        await MainActor.run { isLoadingVerified = true }
        do {
            var allResponses: [YetToScanNetworkResponse] = []
            let chunkSize = 1000
            for i in stride(from: 0, to: scannedUnitIds.count, by: chunkSize) {
                let chunk = Array(scannedUnitIds[i..<min(i + chunkSize, scannedUnitIds.count)])
                let response: [YetToScanNetworkResponse] = try await SupabaseManager.shared.client
                    .from("inventory_units")
                    .select("id, serial_number, catalog_id, catalogs(id, name, brand, catalog_id)")
                    .in("id", values: chunk)
                    .execute()
                    .value
                allResponses.append(contentsOf: response)
            }
            
            let items: [YetToScanItem] = allResponses.map { res in
                YetToScanItem(
                    id: res.id,
                    serialNumber: res.serial_number,
                    catalogId: res.catalog_id,
                    name: res.catalogs?.name ?? "Unknown",
                    brand: res.catalogs?.brand ?? "Unknown"
                )
            }
            await MainActor.run {
                self.verifiedItems = items
                self.isLoadingVerified = false
            }
        } catch {
            print("Failed to fetch verified items in VarianceReportView: \(error)")
            await MainActor.run { isLoadingVerified = false }
        }
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Variance Report", showBackButton: true, backAction: { dismiss() })
                
                if dbAudit == nil {
                    VStack {
                        Spacer()
                        ProgressView().tint(AppColors.gold)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 28) {
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(report.boutiqueName.uppercased())
                                    .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                    .foregroundStyle(AppColors.gold)
                                    .kerning(1.5)
                                
                                Text("Inventory Count Result")
                                    .font(AppFonts.serif(size: 28, weight: .semibold))
                                    .foregroundStyle(.white)
                                
                                Text("Counted on \(report.date.formatted())")
                                    .font(AppFonts.sansSerif(size: 14))
                                    .foregroundStyle(AppColors.secondary)
                            }
                            .padding(.horizontal, 24)
                            
                            // Dynamic Database Metrics Mapping Summary Cards
                            if let db = dbAudit {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        MetricCard(title: "Total Expected", value: "\(db.totalExpected)", subtitle: nil, icon: "doc.text")
                                            .frame(width: 160, height: 160)
                                        MetricCard(title: "Total Scanned", value: "\(db.totalScanned)", subtitle: nil, icon: "barcode.viewfinder")
                                            .frame(width: 160, height: 160)
                                        MetricCard(title: "Variance", value: "\(db.variance)", subtitle: nil, icon: "exclamationmark.triangle")
                                            .frame(width: 160, height: 160)
                                        MetricCard(title: "Accuracy", value: String(format: "%.1f%%", db.accuracy), subtitle: nil, icon: "percent")
                                            .frame(width: 160, height: 160)
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                            
                            VStack(spacing: 20) {
                                // Missing Items Card
                                ReportCardView(
                                    title: "MISSING ITEMS",
                                    quantity: missingItems.count,
                                    skuCount: missingItems.count,
                                    iconName: "xmark.circle.fill",
                                    themeColor: AppColors.error,
                                    isExpanded: $missingExpanded
                                ) {
                                    if missingItems.isEmpty {
                                        Text("No missing items.")
                                            .font(AppFonts.sansSerif(size: 14))
                                            .foregroundStyle(AppColors.secondary)
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    } else {
                                        LazyVStack(spacing: 12) {
                                            ForEach(missingItems, id: \.detail) { item in
                                                DiscrepancyRow(name: item.name ?? "Unknown Item", detail: item.detail ?? "No details provided", status: "", statusColor: AppColors.error)
                                            }
                                        }
                                    }
                                }
                                
                                // New Items Card
                                ReportCardView(
                                    title: "NEW ITEMS",
                                    quantity: newItems.count,
                                    skuCount: newItems.count,
                                    iconName: "plus.circle.fill",
                                    themeColor: AppColors.blue,
                                    isExpanded: $newExpanded
                                ) {
                                    if newItems.isEmpty {
                                        Text("No new items.")
                                            .font(AppFonts.sansSerif(size: 14))
                                            .foregroundStyle(AppColors.secondary)
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    } else {
                                        LazyVStack(spacing: 12) {
                                            ForEach(newItems, id: \.detail) { item in
                                                DiscrepancyRow(name: item.name ?? "Unknown Item", detail: item.detail ?? "No details provided", status: "New Item", statusColor: AppColors.warning)
                                            }
                                        }
                                    }
                                }
                                
                                // Successful/Matched Items Card
                                ReportCardView(
                                    title: "SUCCESSFUL ITEMS",
                                    quantity: verifiedItems.count,
                                    skuCount: verifiedItems.count,
                                    iconName: "checkmark.circle.fill",
                                    themeColor: AppColors.success,
                                    isExpanded: $successfulExpanded
                                ) {
                                    if isLoadingVerified {
                                        ProgressView().tint(AppColors.gold)
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    } else if verifiedItems.isEmpty {
                                        Text("No successful items.")
                                            .font(AppFonts.sansSerif(size: 14))
                                            .foregroundStyle(AppColors.secondary)
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    } else {
                                        LazyVStack(spacing: 12) {
                                            ForEach(verifiedItems) { item in
                                                DiscrepancyRow(name: item.name, detail: "Serial: \(item.serialNumber) • Brand: \(item.brand)", status: "Verified", statusColor: AppColors.success)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.vertical, 20)
                    }
                }
                
                HStack(spacing: 12) {
                    Button(action: {
                        if let url = generateCSV() {
                            shareURL = url
                            showShareSheet = true
                        }
                    }) {
                        Label("Export CSV", systemImage: "doc.text.fill")
                            .font(AppFonts.sansSerif(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Button(action: {
                        if let url = generatePDF() {
                            shareURL = url
                            showShareSheet = true
                        }
                    }) {
                        Label("Export PDF", systemImage: "doc.richtext.fill")
                            .font(AppFonts.sansSerif(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.gold)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Variance Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
        .task {
            do {
                let fetched: [DBStoreAudit] = try await SupabaseManager.shared.client
                    .from("audits")
                    .select()
                    .eq("id", value: audit.id.uuidString)
                    .execute()
                    .value
                if let first = fetched.first {
                    await MainActor.run {
                        self.dbAudit = first
                    }
                    await fetchVerifiedItems()
                }
            } catch {
                print("Failed to fetch db audit: \(error)")
            }
        }
    }
    
    private func generateCSV() -> URL? {
        var csvString = "Item Name,SKU,Expected Qty,Counted Qty,Variance\n"
        for item in filteredItems {
            let escapedName = item.productName.replacingOccurrences(of: "\"", with: "\"\"")
            csvString += "\"\(escapedName)\",\(item.sku),\(item.expectedQty),\(item.countedQty),\(item.variance)\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("VarianceReport.csv")
        try? csvString.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    @MainActor
    private func generatePDF() -> URL? {
        let printView = PDFReportView(report: report, filteredItems: filteredItems)
        let renderer = ImageRenderer(content: printView)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("VarianceReport.pdf")
        
        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let pdfContext = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdfContext.beginPDFPage(nil)
            context(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
        }
        return url
    }
}

private struct DiscrepancyRow: View {
    let name: String
    let detail: String
    let status: String
    let statusColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(AppFonts.sansSerif(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                    Text(detail)
                        .font(AppFonts.sansSerif(size: 11))
                        .foregroundStyle(AppColors.secondary)
                }
                Spacer()
                
                if !status.isEmpty {
                    Text(status.uppercased())
                        .font(AppFonts.sansSerif(size: 9, weight: .bold))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            Divider().background(AppColors.border)
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct PDFReportView: View {
    let report: VarianceReport
    let filteredItems: [VarianceReportItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("INVENTORY VARIANCE REPORT")
                .font(AppFonts.sansSerif(size: 24, weight: .bold))
                .foregroundStyle(.black)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Boutique: \(report.boutiqueName)")
                    Text("Date: \(report.date.formatted())")
                    Text("Controller: \(report.controllerName)")
                }
                .font(AppFonts.sansSerif(size: 12))
                .foregroundStyle(AppColors.secondary)
                Spacer()
            }
            
            Divider()
            
            Text("Line Items")
                .font(AppFonts.sansSerif(size: 16, weight: .bold))
                .foregroundStyle(.black)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Item").font(AppFonts.sansSerif(size: 11, weight: .bold)).frame(maxWidth: .infinity, alignment: .leading)
                    Text("SKU").font(AppFonts.sansSerif(size: 11, weight: .bold)).frame(width: 80, alignment: .leading)
                    Text("Expected").font(AppFonts.sansSerif(size: 11, weight: .bold)).frame(width: 60, alignment: .trailing)
                    Text("Counted").font(AppFonts.sansSerif(size: 11, weight: .bold)).frame(width: 60, alignment: .trailing)
                    Text("Variance").font(AppFonts.sansSerif(size: 11, weight: .bold)).frame(width: 60, alignment: .trailing)
                }
                .foregroundStyle(.black)
                
                Divider()
                
                ForEach(filteredItems) { item in
                    HStack {
                        HStack {
                            Text(item.productName)
                            if item.isArchivedProduct {
                                Text("(Archived)")
                            }
                        }
                        .font(AppFonts.sansSerif(size: 10))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(item.sku).font(AppFonts.sansSerif(size: 10)).frame(width: 80, alignment: .leading)
                        Text("\(item.expectedQty)").font(AppFonts.sansSerif(size: 10)).frame(width: 60, alignment: .trailing)
                        Text("\(item.countedQty)").font(AppFonts.sansSerif(size: 10)).frame(width: 60, alignment: .trailing)
                        Text("\(item.variance > 0 ? "+" : "")\(item.variance)").font(AppFonts.sansSerif(size: 10, weight: .bold))
                            .foregroundStyle(item.variance > 0 ? AppColors.success : (item.variance < 0 ? AppColors.error : Color.black))
                            .frame(width: 60, alignment: .trailing)
                    }
                    .foregroundStyle(.black)
                }
            }
        }
        .padding(40)
        .frame(width: 595, height: 842)
        .background(Color.white)
    }
}

private struct ReportCardView<Content: View>: View {
    let title: String
    let quantity: Int
    let skuCount: Int
    let iconName: String
    let themeColor: Color
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(themeColor.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: iconName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(themeColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(AppFonts.sansSerif(size: 10, weight: .bold))
                            .foregroundStyle(AppColors.secondary)
                            .kerning(1.0)
                        
                        HStack(spacing: 6) {
                            Text("\(quantity) \(quantity == 1 ? "unit" : "units")")
                                .font(AppFonts.sansSerif(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Text("•")
                                .foregroundStyle(AppColors.tertiary)
                            
                            Text("\(skuCount) \(skuCount == 1 ? "SKU" : "SKUs")")
                                .font(AppFonts.sansSerif(size: 12))
                                .foregroundStyle(AppColors.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AppColors.surface)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(spacing: 0) {
                    Divider().background(AppColors.border)
                    
                    VStack(spacing: 0) {
                        content()
                    }
                    .padding(16)
                    .background(AppColors.surface2.opacity(0.3))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isExpanded ? themeColor.opacity(0.3) : AppColors.gold15, lineWidth: 0.5)
        )
    }
}
