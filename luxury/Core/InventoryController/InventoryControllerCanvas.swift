//
//  InventoryControllerCanvas.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct InventoryControllerCanvas: View {
    @Environment(InventoryControllerAppState.self) private var icAppState
    
    @State private var stockRouter = Router()
    @State private var rfidRouter = Router()
    @State private var transfersRouter = Router()
    @State private var auditRouter = Router()
    @State private var profileRouter = Router()
    @State private var sfsViewModel = FulfillmentViewModel()
    @State private var stockViewModel = StockViewModel()
    @State private var notificationService = SFSNotificationService()
    
    var body: some View {
        TabView(selection: Binding(
            get: { icAppState.selectedTab },
            set: { icAppState.selectedTab = $0 }
        )) {
            NavigationStack(path: $stockRouter.path) {
                StockView()
                    .navigationDestination(for: ICRoute.self) { route in
                        destination(for: route)
                    }
                    .fullScreenCover(item: $stockRouter.presentedFullScreen) { route in
                        destination(for: route.value as! ICRoute)
                    }
                    .sheet(item: $stockRouter.presentedSheet) { route in
                        destination(for: route.value as! ICRoute)
                    }
            }
            .environment(stockRouter)
            .environment(sfsViewModel)
            .tabItem { Label("Stock", systemImage: "box.truck") }
            .tag(ICTab.stock)
            
            NavigationStack(path: $rfidRouter.path) {
                RFIDView()
                    .navigationDestination(for: ICRoute.self) { route in
                        destination(for: route)
                    }
                    .fullScreenCover(item: $rfidRouter.presentedFullScreen) { route in
                        destination(for: route.value as! ICRoute)
                    }
                    .sheet(item: $rfidRouter.presentedSheet) { route in
                        destination(for: route.value as! ICRoute)
                    }
            }
            .environment(rfidRouter)
            .tabItem { Label("Scan", systemImage: "barcode.viewfinder") }
            .tag(ICTab.rfid)
            
            NavigationStack(path: $transfersRouter.path) {
                TransfersView()
                    .navigationDestination(for: ICRoute.self) { route in
                        destination(for: route)
                    }
                    .fullScreenCover(item: $transfersRouter.presentedFullScreen) { route in
                        destination(for: route.value as! ICRoute)
                    }
                    .sheet(item: $transfersRouter.presentedSheet) { route in
                        destination(for: route.value as! ICRoute)
                    }
            }
            .environment(transfersRouter)
            .tabItem { Label("Transfers", systemImage: "arrow.left.arrow.right") }
            .tag(ICTab.transfers)
            
            NavigationStack(path: $auditRouter.path) {
                AuditView()
                    .navigationDestination(for: ICRoute.self) { route in
                        destination(for: route)
                    }
                    .fullScreenCover(item: $auditRouter.presentedFullScreen) { route in
                        destination(for: route.value as! ICRoute)
                    }
                    .sheet(item: $auditRouter.presentedSheet) { route in
                        destination(for: route.value as! ICRoute)
                    }
            }
            .environment(auditRouter)
            .tabItem { Label("Audit", systemImage: "checkmark.shield") }
            .tag(ICTab.audit)
            
            NavigationStack(path: $profileRouter.path) {
                ICProfileView()
                    .navigationDestination(for: ICRoute.self) { route in
                        destination(for: route)
                    }
                    .fullScreenCover(item: $profileRouter.presentedFullScreen) { route in
                        destination(for: route.value as! ICRoute)
                    }
                    .sheet(item: $profileRouter.presentedSheet) { route in
                        destination(for: route.value as! ICRoute)
                    }
            }
            .environment(profileRouter)
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(ICTab.profile)
        }
        .tint(AppColors.gold)
        .environment(stockViewModel)
        .overlay(
            VStack {
                if notificationService.hasNewOrder {
                    Button(action: {
                        notificationService.hasNewOrder = false
                        icAppState.selectedTab = .stock
                        stockRouter.push(ICRoute.sfsOrders)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "shippingbox.fill")
                                .font(AppFonts.sansSerif(size: 20))
                                .foregroundStyle(AppColors.gold)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Fulfillment Alert")
                                    .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                Text(notificationService.lastOrderMessage)
                                    .font(AppFonts.sansSerif(size: 12))
                                    .foregroundStyle(AppColors.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                .foregroundStyle(AppColors.tertiary)
                        }
                        .padding(16)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.5), radius: 10, y: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.gold15, lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: notificationService.hasNewOrder)
                }
                Spacer()
            }
            .padding(.top, 40)
            .ignoresSafeArea()
        )
        .onAppear {
            notificationService.startListening()
        }
        .onDisappear {
            notificationService.stopListening()
        }
    }
    
    @ViewBuilder
    private func destination(for route: ICRoute) -> some View {
        switch route {
        case .stockDetail(let alert):
            StockDetailView(alert: alert)
        case .stockSearch:
            StockSearchView()
        case .scanSessionDetail(let session):
            ScanSessionDetailView(session: session)
        case .barcodeScan:
            BarcodeLookupView()
        case .transferDetail(let transfer):
            TransferDetailView(transfer: transfer)
        case .newTransfer:
            NewTransferView()
        case .auditDetail(let audit):
            AuditDetailView(audit: audit)
        case .activeAudit(let audit):
            ActiveAuditView(audit: audit)
        case .varianceReport(let audit):
            VarianceReportView(audit: audit)

        case .sfsOrders:
            FulfillmentView()
        case .sfsVerification(let order):
            SFSVerificationView(order: order)
        case .endlessAisleSelection:
            EndlessAisleWorkflowView()
        case .alerts:
            AlertsView()
        case .purchaseOrders:
            PurchaseOrdersView()
        case .poDetail(let po):
            PODetailView(po: po)
        case .repairQueue:
            ASTRepairQueueView()
        case .astDetail(let ast):
            ICASTDetailView(ast: ast)
        case .editProfile:
            EditProfileView()
        }
    }
}
