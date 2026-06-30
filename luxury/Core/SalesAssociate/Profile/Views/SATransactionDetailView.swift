//
//  SATransactionDetailView.swift
//  luxury
//
//  Created by Nalinish Ranjan on 27/05/26.
//

import SwiftUI
import Supabase
import MessageUI

struct SATransactionDetailView: View {
    let transaction: SATransactionEntity
    @Environment(Router.self) private var router
    @Environment(\.openURL) private var openURL
    @State private var showMailSheet = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @State private var showMailErrorAlert = false
    @State private var purchasedProducts: [(qty: Int, product: CatalogEntity)] = []
    @State private var isLoadingProducts = true
    @State private var generatedPDFURL: URL? = nil
    @State private var boutique: CorporateBoutique? = nil
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(
                    title: "Transaction Details",
                    showBackButton: true,
                    backAction: { router.pop() }
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                    // Main Receipt Card
                    VStack(spacing: 0) {
                        // Top Section
                        VStack(spacing: 12) {
                            Text("Total Paid")
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.secondary)
                            
                            Text(CurrencyManager.shared.format(amount: transaction.transactionAmount))
                                .font(AppFonts.serif(size: 40, weight: .bold))
                                .foregroundStyle(AppColors.gold)
                            
                            if let date = transaction.dateOfTransaction {
                                Text(formatDate(date))
                                    .font(AppFonts.sansSerif(size: 13))
                                    .foregroundStyle(AppColors.secondary)
                            }
                        }
                        .padding(.vertical, 32)
                        
                        Divider().background(AppColors.gold15)
                        
                        // Details Section
                        VStack(spacing: 16) {
                            DetailRow(label: "Transaction ID", value: transaction.paymentGatewayId ?? transaction.id.uuidString.prefix(8).uppercased())
                            
                            if let client = transaction.client {
                                DetailRow(label: "Client", value: client.name)
                                DetailRow(label: "Client Email", value: client.email)
                            } else {
                                DetailRow(label: "Client", value: "Guest Checkout")
                            }
                            
                            DetailRow(label: "Purpose", value: transaction.purpose)
                            
                            if isLoadingProducts {
                                ProgressView()
                                    .padding(.top, 8)
                            } else if !purchasedProducts.isEmpty {
                                Divider().background(AppColors.gold15)
                                    .padding(.vertical, 8)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Products")
                                        .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                        .foregroundStyle(AppColors.secondary)
                                    
                                    ForEach(purchasedProducts, id: \.product.id) { item in
                                        HStack(alignment: .top) {
                                            Text("\(item.qty)x")
                                                .font(AppFonts.sansSerif(size: 13, weight: .bold))
                                                .foregroundStyle(AppColors.secondary)
                                                
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.product.name)
                                                    .font(AppFonts.sansSerif(size: 13, weight: .semibold))
                                                    .foregroundStyle(.white)
                                                Text("S/N: \(item.product.barCode)")
                                                    .font(AppFonts.sansSerif(size: 11))
                                                    .foregroundStyle(AppColors.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(CurrencyManager.shared.format(amount: item.product.amount * Double(item.qty)))
                                                .font(AppFonts.sansSerif(size: 13, weight: .semibold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(24)
                    }
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 1))
                    .padding(.horizontal, 24)
                    
                    // Actions
                    VStack(spacing: 16) {
                        Button(action: sharePDF) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share / Save as PDF")
                            }
                            .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.gold)
                            .clipShape(Capsule())
                        }
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                if MFMailComposeViewController.canSendMail() {
                                    showMailSheet = true
                                } else {
                                    showMailErrorAlert = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "envelope")
                                    Text("Email")
                                }
                                .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppColors.surface)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(AppColors.gold, lineWidth: 1))
                            }
                            
                            Button(action: printReceipt) {
                                HStack {
                                    Image(systemName: "printer")
                                    Text("Print")
                                }
                                .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppColors.surface)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(AppColors.gold, lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await fetchProducts()
        }
        .sheet(isPresented: $showMailSheet) {
            if let url = generatePDFURL(), let data = try? Data(contentsOf: url) {
                MailView(
                    result: $mailResult,
                    subject: "Your Invoice from \(boutique?.name ?? "Eezee Rentals")",
                    toRecipients: [transaction.client?.email ?? ""].filter { !$0.isEmpty },
                    messageBody: "Thank you for your purchase! Please find your invoice attached.",
                    attachmentData: data,
                    attachmentMimeType: "application/pdf",
                    attachmentFileName: "Invoice.pdf"
                )
            } else {
                Text("Error generating PDF for email.")
            }
        }
        .alert("Cannot Send Email", isPresented: $showMailErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your device is not configured to send emails. Please set up the Apple Mail app.")
        }
    }
    
    private func fetchProducts() async {
        do {
            let dbItems: [PurchasedItem] = try await SupabaseManager.shared.client
                .from("purchased_items")
                .select()
                .eq("transaction_id", value: transaction.id.uuidString)
                .execute()
                .value
            
            var fetchedBoutique: CorporateBoutique? = nil
            if let bId = transaction.boutiqueId {
                fetchedBoutique = try? await SupabaseManager.shared.client
                    .from("boutiques")
                    .select()
                    .eq("id", value: bId.uuidString)
                    .single()
                    .execute()
                    .value
            }
            
            if !dbItems.isEmpty {
                let productIds = dbItems.map { $0.productId }
                let dbCatalogs: [CatalogEntity] = try await SupabaseManager.shared.client
                    .from("catalogs")
                    .select()
                    .in("id", values: productIds.map { $0.uuidString })
                    .execute()
                    .value
                
                // Group by product
                var grouped: [UUID: Int] = [:]
                for item in dbItems {
                    grouped[item.productId, default: 0] += 1
                }
                
                let finalProducts = grouped.compactMap { dict in
                    if let catalog = dbCatalogs.first(where: { $0.id == dict.key }) {
                        return (qty: dict.value, product: catalog)
                    }
                    return nil
                }
                
                
                await MainActor.run {
                    self.purchasedProducts = finalProducts
                    self.boutique = fetchedBoutique
                    self.isLoadingProducts = false
                    self.generatedPDFURL = generatePDFURL()
                }
            } else {
                await MainActor.run {
                    self.boutique = fetchedBoutique
                    self.isLoadingProducts = false
                    self.generatedPDFURL = generatePDFURL()
                }
            }
        } catch {
            print("Error fetching products for transaction: \(error)")
            await MainActor.run {
                self.isLoadingProducts = false
            }
        }
    }
    
    private func generatePDFURL() -> URL? {
        let total = transaction.transactionAmount
        let subtotal = total / 1.18
        let cgst = subtotal * 0.09
        let sgst = subtotal * 0.09
        
        let storeName = boutique?.name ?? "Eezee Rentals"
        let storeAddress = "\(boutique?.address ?? "331/C KIADB Industrial Area")\n\(boutique?.city ?? "Mysore") - \(boutique?.pinCode ?? "18")"
        let storePhone = boutique?.managerPhone ?? "+91-9663597666"
        let gstin = "[29AAFFE1207N2ZC]"
        
        let clientName = transaction.client?.name ?? "Guest Checkout"
        let clientDetails = transaction.client?.email ?? "No Email"
        let customerId = transaction.client?.id.uuidString.prefix(5).uppercased() ?? "N/A"
        
        let items = purchasedProducts.map { item in
            InvoicePDFGenerator.InvoiceData.Item(
                description: item.product.name,
                qty: item.qty,
                rate: item.product.amount,
                amount: item.product.amount * Double(item.qty)
            )
        }
        
        let data = InvoicePDFGenerator.InvoiceData(
            storeName: storeName,
            storeAddress: storeAddress,
            storePhone: storePhone,
            gstin: gstin,
            date: transaction.dateOfTransaction ?? Date(),
            invoiceNumber: transaction.paymentGatewayId ?? transaction.id.uuidString.prefix(8).uppercased(),
            customerId: String(customerId),
            clientName: clientName,
            clientDetails: clientDetails,
            items: items,
            subtotal: subtotal,
            cgst: cgst,
            sgst: sgst,
            total: transaction.transactionAmount,
            isGiftInvoice: false
        )
        
        return InvoicePDFGenerator.generateInvoice(data: data)
    }
    
    @MainActor
    private func sharePDF() {
        if let url = generatedPDFURL {
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true, completion: nil)
            }
        }
    }
    
    @MainActor
    private func printReceipt() {
        guard let url = generatedPDFURL else { return }
        if UIPrintInteractionController.canPrint(url) {
            let printInfo = UIPrintInfo(dictionary: nil)
            printInfo.jobName = "Invoice"
            printInfo.outputType = .general
            
            let printController = UIPrintInteractionController.shared
            printController.printInfo = printInfo
            printController.printingItem = url
            printController.present(animated: true, completionHandler: nil)
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppFonts.sansSerif(size: 14))
                .foregroundStyle(AppColors.secondary)
            Spacer()
            Text(value)
                .font(AppFonts.sansSerif(size: 14, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}
