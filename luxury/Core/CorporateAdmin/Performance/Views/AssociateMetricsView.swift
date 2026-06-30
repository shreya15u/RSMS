//
//  AssociateMetricsView.swift
//  luxury
//
//  Created by Kaushiki Rai on 26/05/26.
//

import SwiftUI

struct AssociateMetricsView: View {
    let boutique: BoutiquePerformance
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        boutiqueSnapshot
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)

                        Text("ASSOCIATE METRICS")
                            .font(AppFonts.sansSerif(size: 10, weight: .bold))
                            .foregroundStyle(AppColors.secondary)
                            .kerning(1.8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 12)

                        columnHeaders
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)

                        VStack(spacing: 1) {
                            ForEach(boutique.associates) { associate in
                                AssociateRow(associate: associate, isLast: associate.id == boutique.associates.last?.id)
                            }
                        }
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 80)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .navigationTitle(boutique.boutiqueName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if boutique.isUnderperforming {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(AppFonts.sansSerif(size: 18))
                        .foregroundStyle(AppColors.error)
                }
            }
        }
    }


    private var boutiqueSnapshot: some View {
        HStack(spacing: 0) {
            SnapshotCell(
                label: "ACHIEVEMENT",
                value: (boutique.achievementPct / 100).formatted(.percent.precision(.fractionLength(0))),
                color: boutique.isUnderperforming ? AppColors.error : AppColors.success
            )
            Divider().background(AppColors.gold15).frame(height: 40)
            SnapshotCell(
                label: "CONV. RATE",
                value: (boutique.conversionRate / 100).formatted(.percent.precision(.fractionLength(0))),
                color: AppColors.gold
            )
            Divider().background(AppColors.gold15).frame(height: 40)
            SnapshotCell(
                label: "ATV",
                value: CurrencyManager.shared.format(amount: boutique.atv),
                color: AppColors.text
            )
            Divider().background(AppColors.gold15).frame(height: 40)
            SnapshotCell(
                label: "ASSOCIATES",
                value: "\(boutique.associates.count)",
                color: AppColors.text
            )
        }
        .padding(.vertical, 14)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
    }

    private var columnHeaders: some View {
        HStack {
            Text("ASSOCIATE")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("SALES")
                .frame(width: 72, alignment: .trailing)
            Text("TXN")
                .frame(width: 36, alignment: .trailing)
            Text("CONV")
                .frame(width: 44, alignment: .trailing)
            Text("ABV")
                .frame(width: 60, alignment: .trailing)
        }
        .font(AppFonts.sansSerif(size: 9, weight: .bold))
        .foregroundStyle(AppColors.tertiary)
        .kerning(1)
    }
}

private struct SnapshotCell: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppFonts.serif(size: 16, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(AppFonts.sansSerif(size: 8, weight: .bold))
                .foregroundStyle(AppColors.secondary)
                .kerning(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AssociateRow: View {
    let associate: AssociatePerformance
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(associate.name)
                        .font(AppFonts.sansSerif(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.text)
                    Text("\(associate.walkIns) walk-ins")
                        .font(AppFonts.sansSerif(size: 10))
                        .foregroundStyle(AppColors.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(CurrencyManager.shared.format(amount: associate.totalSales))
                    .font(AppFonts.serif(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.gold)
                    .frame(width: 72, alignment: .trailing)

                Text("\(associate.transactions)")
                    .font(AppFonts.sansSerif(size: 13))
                    .foregroundStyle(AppColors.text)
                    .frame(width: 36, alignment: .trailing)

                Text((associate.conversionRate / 100).formatted(.percent.precision(.fractionLength(0))))
                    .font(AppFonts.sansSerif(size: 13))
                    .foregroundStyle(associate.conversionRate >= 40 ? AppColors.success : AppColors.secondary)
                    .frame(width: 44, alignment: .trailing)

                Text(CurrencyManager.shared.format(amount: associate.abv))
                    .font(AppFonts.serif(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.text)
                    .frame(width: 60, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)

            if !isLast {
                Divider().background(AppColors.gold08).padding(.horizontal, 14)
            }
        }
    }
}

#Preview {
    AssociateMetricsView(boutique: BoutiquePerformance(
        id: UUID(),
        boutiqueName: "Maison Mumbai",
        city: "Mumbai",
        totalSales: 4_20_000,
        salesTarget: 5_00_000,
        totalWalkIns: 120,
        convertedCustomers: 46,
        totalTransactions: 46,
        associates: [
            AssociatePerformance(id: UUID(), name: "Arjun Singh",  totalSales: 2_10_000, transactions: 23, walkIns: 60, converted: 26),
            AssociatePerformance(id: UUID(), name: "Priya Sharma", totalSales: 1_10_000, transactions: 13, walkIns: 34, converted: 12)
        ]
    ))
}
