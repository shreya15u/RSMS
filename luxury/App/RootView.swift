//
//  RootView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI
import UIKit

struct RootView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        switch coordinator.rootDestination {
        case .splash:
            SplashView()
        case .auth:
            AuthView()
        case .mfaSetup:
            MFASetupView()
        case .mfaChallenge:
            MFAChallengeView()
        case .registration(let role):
            AccountRegistrationView(
                role: role,
                onBack: {
                    coordinator.logout()
                },
                onSubmit: {
                    Task {
                        let session = await AuthService().getCurrentSession()
                        await coordinator.routingService.updateRoute(for: session)
                    }
                }
            )
        case .status(let role, let status, let managerEmail):
            ApplicationStatusView(
                role: role,
                status: status,
                managerEmail: managerEmail,
                onContactManager: {
                    let email = managerEmail ?? "admin@gmail.com"
                    if let url = URL(string: "mailto:\(email)") {
                        UIApplication.shared.open(url)
                    }
                },
                onLogout: {
                    coordinator.logout()
                }
            )
        case .dashboard(let role):
            dashboardView(for: role)
        }
    }
    
    @ViewBuilder
    private func dashboardView(for role: UserRole) -> some View {
        switch role {
        case .salesAssociate:
            SalesAssociateCanvas()
        case .boutiqueManager:
            BoutiqueManagerCanvas()
        case .inventoryController:
            InventoryControllerCanvas()
        case .corporateAdmin:
            CorporateAdminCanvas()
        }
    }
}
