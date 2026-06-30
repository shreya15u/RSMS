//
//  CustomOutlineButton.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct CustomOutlineButton: View {
    let title: LocalizedStringKey
    let icon: AnyView?
    let action: () -> Void
    
    init(title: LocalizedStringKey, icon: AnyView? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon = icon {
                    icon
                }
                Text(title)
            }
            .font(AppFonts.sansSerif(size: 15, weight: .medium))
            .foregroundStyle(AppColors.gold)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppColors.gold50, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
    }
}
