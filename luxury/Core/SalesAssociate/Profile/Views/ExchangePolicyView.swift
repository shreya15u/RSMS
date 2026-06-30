//
//  ExchangePolicyView.swift
//  luxury
//
//  Created by Nalinish Ranjan on 27/05/26.
//

import SwiftUI

struct ExchangePolicyView: View {
    @Environment(Router.self) private var router
    var title: String = "Exchange Policy"
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: LocalizedStringKey(title), showBackButton: true, backAction: { router.pop() }, isInline: true)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        PolicySection(title: "General Policy", content: "Items may be exchanged within 30 days of original purchase. Original receipt or proof of purchase is required for all exchanges. Items must be unworn, unused, and in their original condition with all tags and packaging intact.")
                        
                        PolicySection(title: "Fine Jewelry & Watches", content: "Watches and fine jewelry can only be exchanged within 14 days of purchase. They are subject to a rigorous quality control inspection before the exchange is approved. Any personalized or engraved items are strictly non-exchangeable and non-refundable.")
                        
                        PolicySection(title: "Leather Goods & Couture", content: "Leather goods and couture pieces must not show any signs of wear, including scratches, creases, or marks on soles. Exchanges are limited to one per original transaction.")
                        
                        PolicySection(title: "International Exchanges", content: "Exchanges can be processed at any global boutique location, subject to the local currency conversion rates on the day of the exchange. Tax refunds processed originally will be voided and recalculated based on the new transaction.")
                    }
                    .padding(24)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct PolicySection: View {
    let title: String
    let content: String
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppFonts.sansSerif(size: 16, weight: .bold))
                .foregroundStyle(AppColors.gold)
                
            Text(content)
                .font(AppFonts.sansSerif(size: 14))
                .foregroundStyle(AppColors.text)
                .lineSpacing(4)
                .lineLimit(isExpanded ? nil : 3)
                .frame(minHeight: 60, alignment: .topLeading)
            
            if !isExpanded {
                Button(action: {
                    withAnimation {
                        isExpanded = true
                    }
                }) {
                    Text("Read More")
                        .font(AppFonts.sansSerif(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.gold)
                        .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(20)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
    }
}
