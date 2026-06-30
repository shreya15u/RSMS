//
//  SalesTargetCard.swift
//  luxury
//
//  Created by Kaushiki Rai on 22/05/26.
//

import SwiftUI

struct SalesTargetCard: View {

    let actual:              String
    let target:              String
    let actualProgress:      Double
    let pacingProgress:      Double
    let projectedSales:      String
    let pacingStatus:        PacingStatus
    let isTargetConfigured:  Bool

    var body: some View {
        Group {
            if isTargetConfigured {
                configuredView
            } else {
                noTargetView
            }
        }
    }

    private var configuredView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("ACTUAL")
                        .font(AppFonts.sansSerif(size: 9, weight: .bold))
                        .foregroundStyle(AppColors.secondary)
                        .kerning(1.2)
                    Text(actual)
                        .font(AppFonts.serif(size: 28, weight: .semibold))
                        .foregroundStyle(AppColors.text)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("TARGET")
                        .font(AppFonts.sansSerif(size: 9, weight: .bold))
                        .foregroundStyle(AppColors.secondary)
                        .kerning(1.2)
                    Text(target)
                        .font(AppFonts.sansSerif(size: 18, weight: .medium))
                        .foregroundStyle(AppColors.tertiary)
                }
            }

            PacingProgressBar(
                actualProgress: actualProgress,
                pacingProgress: pacingProgress,
                isExceeded:     pacingStatus == .exceeded
            )

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(min(actualProgress, 1.0).formatted(.percent.precision(.fractionLength(0)))) achieved")
                        .font(AppFonts.sansSerif(size: 13, weight: .bold))
                        .foregroundStyle(pacingStatus == .exceeded ? AppColors.gold : AppColors.gold)
                    Text(pacingStatus == .exceeded ? "Daily target surpassed" : "Projected EOD: \(projectedSales)")
                        .font(AppFonts.sansSerif(size: 11))
                        .foregroundStyle(AppColors.secondary)
                }
                Spacer()
            }
        }
        .padding(20)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.gold15, lineWidth: 0.5)
        )
    }

    private var noTargetView: some View {
        HStack(spacing: 14) {
            Image(systemName: "target")
                .font(AppFonts.sansSerif(size: 22))
                .foregroundStyle(AppColors.tertiary)
            VStack(alignment: .leading, spacing: 4) {
                Text("No target set")
                    .font(AppFonts.serif(size: 18, weight: .medium))
                    .foregroundStyle(AppColors.text)
                Text("Configure today's sales target to track performance")
                    .font(AppFonts.sansSerif(size: 12))
                    .foregroundStyle(AppColors.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.gold15, lineWidth: 0.5)
        )
    }
}

private struct PacingProgressBar: View {

    let actualProgress: Double
    let pacingProgress: Double
    let isExceeded:     Bool

    var body: some View {
        GeometryReader { geo in
            let w       = geo.size.width
            let fillW   = isExceeded ? w : w * min(actualProgress, 1.0)
            let needleX = w * min(pacingProgress, 1.0)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.background)
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.gold)
                    .frame(width: fillW, height: 6)
                    .animation(.easeOut(duration: 0.8), value: actualProgress)
            }
        }
        .frame(height: 16)
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        VStack(spacing: 16) {
            SalesTargetCard(
                actual: "\(CurrencyManager.shared.symbol)12,45,000", target: "\(CurrencyManager.shared.symbol)15,00,000",
                actualProgress: 0.83, pacingProgress: 0.60,
                projectedSales: "\(CurrencyManager.shared.symbol)15,60,000", pacingStatus: .ahead,
                isTargetConfigured: true
            )
            SalesTargetCard(
                actual: "—", target: "No target set",
                actualProgress: 0, pacingProgress: 0,
                projectedSales: "—", pacingStatus: .onTrack,
                isTargetConfigured: false
            )
            SalesTargetCard(
                actual: "\(CurrencyManager.shared.symbol)16,00,000", target: "\(CurrencyManager.shared.symbol)15,00,000",
                actualProgress: 1.07, pacingProgress: 0.90,
                projectedSales: "\(CurrencyManager.shared.symbol)16,00,000", pacingStatus: .exceeded,
                isTargetConfigured: true
            )
        }
        .padding(24)
    }
}
