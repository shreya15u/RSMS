//
//  StatusBadge.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct StatusBadge: View {
    let text: LocalizedStringKey
    let status: BadgeStatus
    
    private var color: Color {
        switch status {
        case .success: AppColors.success
        case .warning: AppColors.gold
        case .error: AppColors.error
        case .neutral: AppColors.secondary
        case .pending: AppColors.gold70
        }
    }
    
    var body: some View {
        Text(text)
            .textCase(.uppercase)
            .font(AppFonts.sansSerif(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.3), lineWidth: 0.5)
            )
            .accessibilityLabel(text)
    }
}
