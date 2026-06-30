//
//  BarcodeScannerView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(AppFonts.sansSerif(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text("Scan Barcode")
                        .font(AppFonts.sansSerif(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "bolt.fill")
                        .font(AppFonts.sansSerif(size: 20))
                        .foregroundStyle(AppColors.gold)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
                
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppColors.gold.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [10, 10]))
                        .frame(width: 250, height: 250)
                    
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(AppColors.gold)
                            .frame(height: 2)
                            .shadow(color: AppColors.gold, radius: 4, y: 0)
                            .offset(y: -125)
                    }
                    .frame(height: 250)
                }
                
                Spacer()
                
                Text("Align barcode within the frame to scan.\nIt will be added to the cart automatically.")
                    .font(AppFonts.sansSerif(size: 12))
                    .foregroundStyle(AppColors.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.bottom, 60)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
