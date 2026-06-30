import SwiftUI

struct BoutiqueManagerCanvas: View {
    @Environment(BoutiqueManagerAppState.self) private var bmAppState
    
    @State private var dashRouter = Router()
    @State private var teamRouter = Router()
    @State private var storeRouter = Router()

    @State private var profileRouter = Router()
    
    var body: some View {
        TabView(selection: Binding(
            get: { bmAppState.selectedTab },
            set: { bmAppState.selectedTab = $0 }
        )) {
            NavigationStack(path: $dashRouter.path) {
                DashboardView()
                    .navigationDestination(for: BMRoute.self) { route in
                        destination(for: route, router: dashRouter)
                    }
                    .navigationDestination(for: SARoute.self) { route in
                        if case .afterSalesTracking(let ast) = route {
                            AfterSalesTrackingView(ast: ast)
                        }
                    }
                    .fullScreenCover(item: $dashRouter.presentedFullScreen) { route in
                        destination(for: route.value as! BMRoute, router: dashRouter)
                    }
                    .sheet(item: $dashRouter.presentedSheet) { route in
                        destination(for: route.value as! BMRoute, router: dashRouter)
                    }
            }
            .environment(dashRouter)
            .tabItem { Label("Dashboard", systemImage: "chart.bar") }
            .tag(BMTab.dashboard)
            
            NavigationStack(path: $teamRouter.path) {
                TeamView()
                    .navigationDestination(for: BMRoute.self) { route in
                        destination(for: route, router: teamRouter)
                    }
                    .fullScreenCover(item: $teamRouter.presentedFullScreen) { route in
                        destination(for: route.value as! BMRoute, router: teamRouter)
                    }
                    .sheet(item: $teamRouter.presentedSheet) { route in
                        destination(for: route.value as! BMRoute, router: teamRouter)
                    }
            }
            .environment(teamRouter)
            .tabItem { Label("Team", systemImage: "person.3") }
            .tag(BMTab.team)
            
            NavigationStack(path: $storeRouter.path) {
                StoreView()
                    .navigationDestination(for: BMRoute.self) { route in
                        destination(for: route, router: storeRouter)
                    }
                    .fullScreenCover(item: $storeRouter.presentedFullScreen) { route in
                        destination(for: route.value as! BMRoute, router: storeRouter)
                    }
                    .sheet(item: $storeRouter.presentedSheet) { route in
                        destination(for: route.value as! BMRoute, router: storeRouter)
                    }
            }
            .environment(storeRouter)
            .tabItem { Label("Store", systemImage: "building.2") }
            .tag(BMTab.store)
            

            NavigationStack(path: $profileRouter.path) {
                BoutiqueManagerProfileView()
                    .navigationDestination(for: BMRoute.self) { route in
                        destination(for: route, router: profileRouter)
                    }
                    .fullScreenCover(item: $profileRouter.presentedFullScreen) { route in
                        destination(for: route.value as! BMRoute, router: profileRouter)
                    }
                    .sheet(item: $profileRouter.presentedSheet) { route in
                        destination(for: route.value as! BMRoute, router: profileRouter)
                    }
            }
            .environment(profileRouter)
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(BMTab.profile)
        }
        .tint(AppColors.gold)
    }
    
    @ViewBuilder
    private func destination(for route: BMRoute, router: Router) -> some View {
        switch route {
        case .allAppointments:
            BMAllAppointmentsView()
        case .appointmentDetail(let appt):
            BMAppointmentDetailView(appointment: appt)
        case .staffPerformanceDetail(let member):
            StaffPerformanceDetailView(member: member)
        case .createEvent:
            CreateEventView()
        case .salesAnalytics:
            SalesAnalyticsView()
        case .staffPerformanceReport:
            StaffPerformanceReportView()
        case .shrinkReport:
            ShrinkReportView()
        case .clientInsights:
            ClientInsightsView(onDirectoryTap: {
                router.push(BMRoute.clientDirectory)
            })
        case .reportsAnalytics:
            ReportsView()
        case .transferApproval:
            TransferApprovalView()
        case .newTransfer:
            NewTransferView()
        case .cycleCountSignoff:
            CycleCountDetailView()
        case .stockReconciliation:
            StockReconciliationView()
        case .astQueue:
            ASTQueueView()
        case .astApproval(let ast):
            ASTApprovalView(ast: ast)
        case .afterSalesTracking(let ast):
            AfterSalesTrackingView(ast: ast)
        case .clientProfile(let client):
            ClientProfileView(client: client)
        case .clientDirectory:
            ClientDirectoryListView(onClientTap: { client in
                router.push(BMRoute.clientProfile(client))
            })
        case .writeOffApproval:
            WriteOffApprovalView()
        case .endlessAisleRequests:
            BMEndlessAisleRequestsView()
        case .staffRequestDetail(let staff):
            RequestDetailSheet(
                title: LocalizedStringKey(staff.name),
                subtitle: LocalizedStringKey(staff.role.displayName),
                details: [
                    ("Email", staff.email),
                    ("Address", staff.address),
                    ("Status", staff.status.rawValue.capitalized)
                ],
                avatarUrl: staff.avatarUrl,
                resumeUrl: staff.resumeUrl,
                onApprove: { router.dismissModal() },
                onReject: { router.dismissModal() }
            )
        case .pendingStaff:
            StaffRequestsView()
        case .staffDetail(let employee):
            EmployeeDetailView(employee: employee)
        case .vipPreviewDetail(let event):
            VIPPreviewDetailView(event: event)
        case .trunkShowDetail(let event):
            TrunkShowDetailView(event: event)
        case .productLaunchDetail(let event):
            ProductLaunchDetailView(event: event)
        case .editProfile:
            EditProfileView()
        case .salesTargets:
            SalesTargetsView()
        case .planogramGallery(let boutiqueId):
            PlanogramGalleryView(boutiqueId: boutiqueId)
        case .pendingAppointmentsList(let appointments):
            BMPendingAppointmentsListView(appointments: appointments)
        case .sfsTicketDetail(let ticket):
            SFSTicketDetailView(ticket: ticket)
        case .sfsTicketsList(let tickets):
            SFSTicketsListView(tickets: tickets, onSelectTicket: { ticket in
                router.push(BMRoute.sfsTicketDetail(ticket))
            })
        case .auditReportHub:
            AuditReportHubView()
        case .auditReportDetail(let title):
            AuditReportDetailView(auditTitle: title)
        case .activeAuditReportDetail(let title):
            ActiveAuditReportDetailView(auditTitle: title)
        case .storePolicies:
            ExchangePolicyView(title: "Store Policies")
        }
    }
}
