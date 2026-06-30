//
//  CustomButton.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct CustomButton: View {
    let title: LocalizedStringKey
    let icon: AnyView?
    let isLoading: Bool
    let action: () -> Void
    
    init(title: LocalizedStringKey, icon: AnyView? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }
    
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(AppColors.background)
                        .controlSize(.small)
                } else {
                    if let icon = icon {
                        icon
                    }
                    Text(title)
                }
            }
            .font(AppFonts.sansSerif(size: 15, weight: .medium))
            .foregroundStyle(AppColors.background)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppColors.gold)
            )
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityValue(isLoading ? "Loading" : "")
    }
}
