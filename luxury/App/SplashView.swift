//
//  SplashView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct SplashView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [AppColors.gold.opacity(0.07), .clear]),
                center: .center,
                startRadius: 0,
                endRadius: 190
            )
            .frame(width: 380, height: 380)
            .allowsHitTesting(false)
            
            ZStack {
                Circle().stroke(AppColors.gold, lineWidth: 0.6).frame(width: 184)
                Circle().stroke(AppColors.gold, lineWidth: 0.4).frame(width: 166)
                Circle().stroke(AppColors.gold, lineWidth: 0.2).frame(width: 148)
                
                Rectangle().fill(AppColors.gold).opacity(0.6).frame(width: 0.5, height: 10).offset(y: -92)
                Rectangle().fill(AppColors.gold).opacity(0.6).frame(width: 0.5, height: 10).offset(y: 92)
                Rectangle().fill(AppColors.gold).opacity(0.6).frame(width: 10, height: 0.5).offset(x: -92)
                Rectangle().fill(AppColors.gold).opacity(0.6).frame(width: 10, height: 0.5).offset(x: 92)
            }
            .opacity(0.3)
            
            VStack(spacing: 0) {
                Rectangle()
                    .fill(AppColors.gold.opacity(0.9))
                    .frame(width: 11, height: 11)
                    .rotationEffect(.degrees(45))
                    .padding(.bottom, 22)
                
                Text("D'LUSSO")
                    .font(AppFonts.serif(size: 50, weight: .semibold))
                    .foregroundStyle(AppColors.gold)
                    .kerning(20)
                    .padding(.leading, 20)
                
                GoldRule(width: 90)
                    .padding(.vertical, 18)
                
                Text("RETAIL MANAGEMENT SYSTEM")
                    .font(AppFonts.sansSerif(size: 9.5, weight: .light))
                    .foregroundStyle(AppColors.secondary)
                    .kerning(4.5)
            }
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.95)
            
            VStack {
                Spacer()
                HStack(spacing: 9) {
                    Circle()
                        .fill(AppColors.gold.opacity(0.7))
                        .frame(width: 5, height: 5)
                    
                    Text("LUXURY BOUTIQUE EDITION")
                        .font(AppFonts.sansSerif(size: 9, weight: .light))
                        .foregroundStyle(AppColors.secondary)
                        .kerning(2.5)
                }
                .padding(.vertical, 7)
                .padding(.horizontal, 20)
                .overlay(
                    Capsule()
                        .stroke(AppColors.gold15, lineWidth: 0.5)
                )
                .padding(.bottom, 78)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                isVisible = true
            }
            
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                let session = await AuthService().getCurrentSession()
                await coordinator.routingService.updateRoute(for: session)
            }
        }
    }
}

// id, product_id, name, description, brand, category(hardcoded strings or enum), avaiable_stock, ammount, bar code or qr code scanned number,
// List of <reversed {map of [uid, reservedDate, deliveryDate, payment info, status]}>,




