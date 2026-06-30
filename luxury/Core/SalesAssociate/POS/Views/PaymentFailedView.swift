//
//  PaymentFailedView.swift
//  luxury
//
//  Created by Nalinish Ranjan on 27/05/26.
//

import SwiftUI

struct PaymentFailedView: View {
    @Environment(Router.self) private var router
    let errorMessage: String
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(AppColors.error.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "xmark.circle.fill")
                        .font(AppFonts.sansSerif(size: 40))
                        .foregroundStyle(AppColors.error)
                }
                .padding(.bottom, 32)
                
                VStack(spacing: 12) {
                    Text("Payment Failed")
                        .font(AppFonts.serif(size: 32, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(errorMessage)
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(AppColors.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                Button(action: {
                    router.pop()
                }) {
                    Text("Try Again")
                        .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.gold)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                Button(action: {
                    router.popToRoot()
                }) {
                    Text("Cancel Transaction")
                        .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.secondary)
                }
                .padding(.bottom, 40)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }
}
