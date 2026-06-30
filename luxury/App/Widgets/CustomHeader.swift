//
//  CustomHeader.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//  Modified by Antigravity on 01/06/26.
//

import SwiftUI

struct CustomHeader: View {
    let title: LocalizedStringKey
    var showBackButton: Bool = false
    var backAction: (() -> Void)? = nil
    var trailingIcon: String? = nil
    var trailingAccessibilityLabel: String? = nil
    var trailingAction: (() -> Void)? = nil
    var isInline: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            if showBackButton, let action = backAction {
                Button(action: action) {
                    ZStack {
                        Circle()
                            .fill(AppColors.surface2)
                            .frame(width: 44, height: 44)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
            }
            
            if isInline {
                Spacer()
                Text(title)
                    .font(AppFonts.sansSerif(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer()
                
                if showBackButton && trailingIcon == nil {
                    // Balance the back button
                    Circle()
                        .frame(width: 44, height: 44)
                        .opacity(0)
                }
            } else {
                Text(title)
                    .font(AppFonts.serif(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
            }
            
            if let icon = trailingIcon, let action = trailingAction {
                Button(action: action) {
                    Image(systemName: icon)
                        .font(AppFonts.sansSerif(size: 20, weight: .semibold))
                        .foregroundStyle(AppColors.gold)
                }
                .accessibilityLabel(trailingAccessibilityLabel ?? "Action")
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(AppColors.background)
    }
}
