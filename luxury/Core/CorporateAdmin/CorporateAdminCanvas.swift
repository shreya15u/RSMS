//
//  CorporateAdminCanvas.swift
//  luxury
//
//  Created by Aditya Chauhan on 18/05/26.
//

import SwiftUI

struct CorporateAdminCanvas: View {
    @Environment(CorporateAdminAppState.self) private var caAppState
    
    @State private var analyticsRouter = Router()

    @State private var usersRouter = Router()
    @State private var catalogsRouter = Router()
    @State private var logsRouter = Router()
    @State private var userManagementViewModel = UserManagementViewModel()
    @State private var catalogsViewModel = CatalogsViewModel()
    @State private var inventoryRouter = Router()
    @State private var inventoryViewModel = GlobalInventoryViewModel()
    
    @State private var performanceRouter = Router()
    @State private var performanceViewModel = StorePerformanceViewModel()
    
    @State private var profileRouter = Router()
    @State private var planogramsRouter = Router()
    
    var body: some View {
        TabView(selection: Binding(
            get: { caAppState.selectedTab },
            set: { caAppState.selectedTab = $0 }
        )) {
            NavigationStack(path: $analyticsRouter.path) {
                GlobalAnalyticsView()
                    .navigationDestination(for: CARoute.self) { route in
                        destination(for: route, router: analyticsRouter)
                    }

                    .fullScreenCover(item: $analyticsRouter.presentedFullScreen) { route in
                        destination(for: route.value as! CARoute, router: analyticsRouter)
                    }
                    .sheet(item: $analyticsRouter.presentedSheet) { route in
                        destination(for: route.value as! CARoute, router: analyticsRouter)
                    }
            }
            .environment(analyticsRouter)
            .tabItem { Label("Analytics", systemImage: "chart.pie.fill") }
            .tag(CATab.globalAnalytics)
            
            NavigationStack(path: $usersRouter.path) {
                UserManagementView(viewModel: userManagementViewModel)
                    .navigationDestination(for: CARoute.self) { route in
                        destination(for: route, router: usersRouter)
                    }
                    .sheet(item: $usersRouter.presentedSheet) { route in
                        destination(for: route.value as! CARoute, router: usersRouter)
                    }
            }
            .environment(usersRouter)
            .tabItem { Label("Requests", systemImage: "person.badge.shield.checkmark.fill") }
            .tag(CATab.userManagement)
            
            NavigationStack(path: $catalogsRouter.path) {
                CatalogsView()
                    .navigationDestination(for: CARoute.self) { route in
                        destination(for: route, router: catalogsRouter)
                    }
            }
            .environment(catalogsRouter)
            .environment(catalogsViewModel)
            .tabItem { Label("Catalogs", systemImage: "book.pages.fill") }
            .tag(CATab.catalogs)
            
            // systemLogs, inventory, and storePerformance tabs have been moved into the Profile tab to reduce tab count.
            
            NavigationStack(path: $profileRouter.path) {
                CorporateAdminProfileView()
                    .navigationDestination(for: CARoute.self) { route in
                        destination(for: route, router: profileRouter)
                    }
                    .fullScreenCover(item: $profileRouter.presentedFullScreen) { route in
                        destination(for: route.value as! CARoute, router: profileRouter)
                    }
                    .sheet(item: $profileRouter.presentedSheet) { route in
                        destination(for: route.value as! CARoute, router: profileRouter)
                    }
            }
            .environment(profileRouter)
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(CATab.profile)
        }
        .tint(AppColors.gold)
    }
    
    @ViewBuilder
    private func destination(for route: CARoute, router: Router) -> some View {
        switch route {
        case .globalInventory:
            GlobalInventoryView()
                .environment(inventoryViewModel)
        case .userManagement:
            UserManagementView(viewModel: userManagementViewModel)
        case .catalogs:
            CatalogsView()
        case .catalogForm(let editCatalog):
            CatalogFormView(editCatalog: editCatalog)
        case .catalogDetail(let catalog):
            CatalogDetailView(catalog: catalog)
        case .boutiqueConfig:
            BoutiqueConfigView()
        case .boutiqueConfigDetail(let boutique):
            BoutiqueConfigDetailView(boutique: boutique, onUpdate: { _ in })
        case .systemLogs:
            SystemLogsView()
        case .boutiqueRequestDetail(let boutique):
            RequestDetailSheet(
                title: LocalizedStringKey(boutique.name),
                subtitle: "Boutique Registration",
                details: [
                    ("Manager", boutique.managerName),
                    ("Phone", boutique.managerPhone),
                    ("Email", boutique.managerEmail),
                    ("Location", boutique.city),
                    ("Status", boutique.status.rawValue.capitalized)
                ],
                onApprove: { router.dismissModal() },
                onReject: { router.dismissModal() }
            )
        case .pendingBoutiques:
            PendingBoutiquesView(viewModel: userManagementViewModel)
        case .boutiqueDetail(let boutique):
            BoutiqueDetailView(boutique: boutique, viewModel: userManagementViewModel)
        case .inventoryDetail(let summary):
            ProductStockDetailView(summary: summary)
        case .staffList:
            CAStaffListView()
        case .staffDetail(let staff):
            EmployeeDetailView(employee: staff)
        case .storePerformance:
            StorePerformanceView()
        case .storePerformanceDetail(let boutique):
            AssociateMetricsView(boutique: boutique)
        case .editProfile:
            EditProfileView()
        case .planograms:
            PlanogramManagementView()
        case .clientInsights:
            ClientInsightsView(onDirectoryTap: {
                router.push(CARoute.clientDirectory)
            })
        case .globalRevenue:
            GlobalRevenueView()
        case .pricingCampaigns:
            PricingCampaignView()
        case .activeBoutiques:
            ActiveBoutiquesView()
        case .transactionDetail(let tx):
            SATransactionDetailView(transaction: tx)
        case .sfsTicketDetail(let ticket):
            SFSTicketDetailView(ticket: ticket)
        case .sfsTicketsList(let tickets):
            SFSTicketsListView(tickets: tickets)
        case .transactionsList(let txs):
            CATransactionsListView(transactions: txs)
        case .clientProfile(let client):
            ClientProfileView(client: client)
        case .clientDirectory:
            ClientDirectoryListView(onClientTap: { client in
                router.push(CARoute.clientProfile(client))
            })
        @unknown default:
            // Fallback to a neutral view to satisfy exhaustiveness and aid forward-compatibility
            EmptyView()
        }
    }
}
