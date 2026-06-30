//
//  ScanSessionDetailView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct ScanSessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let session: ScanSession
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Scan Session Details", showBackButton: true, backAction: { dismiss() })
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(session.zone)
                                .font(AppFonts.serif(size: 32, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(session.date)
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.secondary)
                        }
                        .padding(.horizontal, 24)
                        
                        HStack(spacing: 12) {
                            MetricCard(title: "Scanned", value: "\(session.scannedCount)", subtitle: "Total EPC Tags", icon: "barcode.viewfinder")
                            MetricCard(title: "Variance", value: "\(session.variance)", subtitle: "vs Expected", icon: "exclamationmark.arrow.circlepath")
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ITEM FEED (QR/BARCODE/RFID)")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 1) {
                                FeedRow(name: "Rolex Submariner 126610LN", type: "RFID", status: .success)
                                FeedRow(name: "Omega Seamaster 210.30.42", type: "QR CODE", status: .success)
                                FeedRow(name: "⚠ Unmatched Tag", type: "BARCODE", status: .error)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Scan Session Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct FeedRow: View {
    let name: String
    let type: String
    let status: BadgeStatus
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(AppFonts.sansSerif(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Text(type)
                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                    .foregroundStyle(AppColors.tertiary)
                    .kerning(1)
            }
            Spacer()
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.surface)
    }
}
