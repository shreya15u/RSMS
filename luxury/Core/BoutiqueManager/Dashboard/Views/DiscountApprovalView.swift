//
//  DiscountApprovalView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct DiscountApprovalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = DiscountApprovalViewModel()

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                CustomHeader(title: "Discount Approvals")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(viewModel.requests) { request in
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(request.client)
                                            .font(AppFonts.sansSerif(size: 16, weight: .bold))
                                            .foregroundStyle(AppColors.text)
                                        Text("By \(request.advisor) · \(request.time)")
                                            .font(AppFonts.sansSerif(size: 11))
                                            .foregroundStyle(AppColors.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(request.discount)
                                            .font(AppFonts.serif(size: 20, weight: .bold))
                                            .foregroundStyle(AppColors.gold)
                                        Text(request.total)
                                            .font(AppFonts.sansSerif(size: 12))
                                            .foregroundStyle(AppColors.secondary)
                                    }
                                }

                                HStack(spacing: 12) {
                                    Button(action: { viewModel.reject(request) }) {
                                        Text("Reject")
                                            .font(AppFonts.sansSerif(size: 12, weight: .bold))
                                            .foregroundStyle(AppColors.error)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(AppColors.error.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(AppColors.error.opacity(0.3), lineWidth: 1)
                                            )
                                    }

                                    Button(action: { viewModel.approve(request) }) {
                                        Text("Approve")
                                            .font(AppFonts.sansSerif(size: 12, weight: .bold))
                                            .foregroundStyle(AppColors.background)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(AppColors.gold)
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }
                                }
                            }
                            .padding(16)
                            .background(AppColors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                        }
                    }
                    .padding(16)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
