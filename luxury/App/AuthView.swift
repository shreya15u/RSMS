//
//  AuthView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct AuthView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            AuthenticationView(
                onSignInSuccess: {
                    print("DEBUG: onSignInSuccess callback triggered in AuthView")
                    Task {
                        let session = await AuthService().getCurrentSession()
                        print("DEBUG: Explicitly updating route in AuthView onSignInSuccess")
                        await coordinator.routingService.updateRoute(for: session)
                    }
                }
            )
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
        }
    }
}
