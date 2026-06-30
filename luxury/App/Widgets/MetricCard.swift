//
//  MetricCard.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct MetricCard: View {
    let title: LocalizedStringKey
    let value: String
    let subtitle: LocalizedStringKey?
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.gold)
                    .frame(width: 36, height: 36)
                    .background(AppColors.gold.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(value)
                    .font(AppFonts.serif(size: 28, weight: .bold))
                    .foregroundStyle(AppColors.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                
                Text(title)
                    .textCase(.uppercase)
                    .font(AppFonts.sansSerif(size: 11, weight: .bold))
                    .foregroundStyle(AppColors.secondary)
                    .kerning(1.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            
            Spacer(minLength: 0)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(AppFonts.sansSerif(size: 11))
                    .foregroundStyle(AppColors.gold70)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LinearGradient(colors: [AppColors.gold.opacity(0.5), AppColors.gold.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .accessibilityElement(children: .combine)
    }
}
