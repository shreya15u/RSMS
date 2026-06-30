//
//  ReceiptView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI
import MessageUI

struct ReceiptView: View {
    @Environment(Router.self) private var router
    @Environment(SalesAssociateAppState.self) private var saAppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    @State private var generatedPDFURL: URL?
    @State private var showMailSheet = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @State private var showMailErrorAlert = false
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(AppFonts.sansSerif(size: 20, weight: .semibold))
                            .foregroundStyle(AppColors.gold)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(AppColors.success.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "checkmark")
                            .font(AppFonts.sansSerif(size: 32, weight: .bold))
                            .foregroundStyle(AppColors.success)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Payment Successful")
                            .font(AppFonts.serif(size: 32, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Text("Transaction ID: \(POSViewModel.shared.lastTransactionId ?? "#TX-PENDING")")
                            .font(AppFonts.sansSerif(size: 13))
                            .foregroundStyle(AppColors.secondary)
                    }
                    
                    VStack(spacing: 12) {
                        Text(POSViewModel.shared.formatCurrency(POSViewModel.shared.lastTotalPaid ?? 0))
                            .font(AppFonts.serif(size: 40, weight: .bold))
                            .foregroundStyle(AppColors.gold)
                        
                        Text("Paid securely via Razorpay")
                            .font(AppFonts.sansSerif(size: 12))
                            .foregroundStyle(AppColors.tertiary)
                            
                        if let boutique = POSViewModel.shared.lastBoutique {
                            VStack(spacing: 4) {
                                Text(boutique.name)
                                    .font(AppFonts.sansSerif(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text("\(boutique.address), \(boutique.city) - \(boutique.pinCode)")
                                    .font(AppFonts.sansSerif(size: 11))
                                    .foregroundStyle(AppColors.tertiary)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    
                    if !POSViewModel.shared.lastPurchasedItems.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(POSViewModel.shared.lastPurchasedItems, id: \.product.id) { item in
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
                                        
                                        Text(POSViewModel.shared.formatCurrency(Int(item.product.amount) * item.qty))
                                            .font(AppFonts.sansSerif(size: 13, weight: .semibold))
                                            .foregroundStyle(.white)
                                    }
                                    
                                    Divider()
                                        .background(AppColors.border)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .frame(maxHeight: 150)
                        .padding(.bottom, 16)
                    }
                    
                    VStack(spacing: 12) {
                        CustomButton(title: "Share / Save as PDF", icon: AnyView(Image(systemName: "square.and.arrow.up")), action: {
                            if let url = generatedPDFURL {
                                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let rootVC = windowScene.windows.first?.rootViewController {
                                    rootVC.present(activityVC, animated: true, completion: nil)
                                }
                            }
                        })
                        HStack(spacing: 12) {
                            CustomOutlineButton(title: "Email", icon: AnyView(Image(systemName: "envelope")), action: {
                                if MFMailComposeViewController.canSendMail() {
                                    showMailSheet = true
                                } else {
                                    showMailErrorAlert = true
                                }
                            })
                            CustomOutlineButton(title: "Print", icon: AnyView(Image(systemName: "printer")), action: {
                                printReceipt()
                            })
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await MainActor.run {
                            saAppState.selectedTab = .clients
                        }
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        await MainActor.run {
                            router.popToRoot()
                        }
                    }
                }) {
                    Text("Return to Dashboard")
                        .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.gold)
                }
                .padding(.bottom, 40)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            self.generatedPDFURL = generatePDFURL()
        }
        .sheet(isPresented: $showMailSheet) {
            if let url = generatedPDFURL, let data = try? Data(contentsOf: url) {
                MailView(
                    result: $mailResult,
                    subject: "Your Invoice from \(POSViewModel.shared.lastBoutique?.name ?? "Eezee Rentals")",
                    toRecipients: [POSViewModel.shared.lastClient?.email ?? ""].filter { !$0.isEmpty },
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
    
    private func generatePDFURL() -> URL? {
        let total = Double(POSViewModel.shared.lastTotalPaid ?? 0)
        let subtotal = total / 1.18
        let cgst = subtotal * 0.09
        let sgst = subtotal * 0.09
        
        let boutique = POSViewModel.shared.lastBoutique
        let storeName = boutique?.name ?? "Eezee Rentals"
        let storeAddress = "\(boutique?.address ?? "331/C KIADB Industrial Area")\n\(boutique?.city ?? "Mysore") - \(boutique?.pinCode ?? "18")"
        
        // I will just use dummy GSTIN and phone since they aren't in BoutiqueEntity
        let storePhone = boutique?.managerPhone ?? "+91-9663597666"
        let gstin = "[29AAFFE1207N2ZC]"
        
        let clientName = POSViewModel.shared.lastClient?.name ?? "Guest Checkout"
        let clientDetails = POSViewModel.shared.lastClient?.email ?? "No Email"
        let customerId = POSViewModel.shared.lastClient?.id.uuidString.prefix(5).uppercased() ?? "N/A"
        
        let items = POSViewModel.shared.lastPurchasedItems.map { item in
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
            date: Date(),
            invoiceNumber: POSViewModel.shared.lastTransactionId ?? "Pending",
            customerId: String(customerId),
            clientName: clientName,
            clientDetails: clientDetails,
            items: items,
            subtotal: subtotal,
            cgst: cgst,
            sgst: sgst,
            total: total,
            isGiftInvoice: POSViewModel.shared.isGiftInvoice
        )
        
        return InvoicePDFGenerator.generateInvoice(data: data)
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
