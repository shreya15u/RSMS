//
//  SalesAssociateCanvas.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct SalesAssociateCanvas: View {
    @Environment(SalesAssociateAppState.self) private var saAppState
    
    @State private var clientsRouter = Router()
    @State private var sellingRouter = Router()
    @State private var posRouter = Router()
    @State private var profileRouter = Router()
    
    var body: some View {
        TabView(selection: Binding(
            get: { saAppState.selectedTab },
            set: { saAppState.selectedTab = $0 }
        )) {
            NavigationStack(path: $clientsRouter.path) {
                ClientelingView()
                    .navigationDestination(for: SARoute.self) { route in
                        destination(for: route)
                    }
                    .fullScreenCover(item: $clientsRouter.presentedFullScreen) { route in
                        destination(for: route.value as! SARoute)
                    }
                    .sheet(item: $clientsRouter.presentedSheet) { route in
                        destination(for: route.value as! SARoute)
                    }
            }
            .environment(clientsRouter)
            .tabItem { Label("Clients", systemImage: "person.2") }
            .tag(SATab.clients)
            
            NavigationStack(path: $sellingRouter.path) {
                SellingView()
                    .navigationDestination(for: SARoute.self) { route in
                        destination(for: route)
                    }
                    .fullScreenCover(item: $sellingRouter.presentedFullScreen) { route in
                        destination(for: route.value as! SARoute)
                    }
                    .sheet(item: $sellingRouter.presentedSheet) { route in
                        destination(for: route.value as! SARoute)
                    }
            }
            .environment(sellingRouter)
            .tabItem { Label("Selling", systemImage: "cart") }
            .tag(SATab.selling)
            
            NavigationStack(path: $posRouter.path) {
                POSView()
                    .navigationDestination(for: SARoute.self) { route in
                        destination(for: route)
                    }
                    .fullScreenCover(item: $posRouter.presentedFullScreen) { route in
                        destination(for: route.value as! SARoute)
                    }
                    .sheet(item: $posRouter.presentedSheet) { route in
                        destination(for: route.value as! SARoute)
                    }
            }
            .environment(posRouter)
            .tabItem { Label("POS", systemImage: "creditcard") }
            .tag(SATab.pos)
            
            NavigationStack(path: $profileRouter.path) {
                ProfileView()
                    .navigationDestination(for: SARoute.self) { route in
                        destination(for: route)
                    }
                    .fullScreenCover(item: $profileRouter.presentedFullScreen) { route in
                        destination(for: route.value as! SARoute)
                    }
                    .sheet(item: $profileRouter.presentedSheet) { route in
                        destination(for: route.value as! SARoute)
                    }
            }
            .environment(profileRouter)
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(SATab.profile)
        }
        .tint(AppColors.gold)
    }
    
    @ViewBuilder
    private func destination(for route: SARoute) -> some View {
        switch route {
        case .clientProfile(let client):
            ClientProfileView(client: client)
        case .newClient:
            NewClientView()
        case .editClient(let client):
            EditClientView(client: client)
        case .catalogDetail(let catalog):
            SalesProductDetailView(catalog: catalog)
        case .barcodeScanner:
            BarcodeScannerView()
        case .payment:
            PaymentView()
        case .receipt:
            ReceiptView()
        case .paymentFailed(let errorMessage):
            PaymentFailedView(errorMessage: errorMessage)
        case .appointmentList:
            AppointmentListView()
        case .transactionDetail(let tx):
            SATransactionDetailView(transaction: tx)
        case .createAppointment(let client):
            CreateAppointmentView(client: client)
        case .returns:
            ReturnsView()
        case .afterSalesIntake(let client, let serialNumber, let isWarrantyActive, let purchaseId):
            AfterSalesIntakeView(client: client, serialNumber: serialNumber, isWarrantyActive: isWarrantyActive, purchaseId: purchaseId)
        case .afterSalesTracking(let ast):
            AfterSalesTrackingView(ast: ast)
        case .remoteSelling:
            RemoteSellingView()
        case .purchaseDetails(let client, let purchase):
            PurchaseDetailsView(client: client, purchase: purchase)
        case .exchangePolicy:
            ExchangePolicyView()
        case .transactionList(let txs):
            SATransactionListView(transactions: txs)
        case .editProfile:
            EditProfileView()
        case .planogramGallery(let boutiqueId):
            PlanogramGalleryView(boutiqueId: boutiqueId)
        case .sfsHandover:
            SAHandoverView()
        case .remoteConsultation:
            RemoteConsultationView()
        }
    }
}
