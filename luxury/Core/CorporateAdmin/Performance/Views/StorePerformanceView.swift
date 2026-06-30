//
//  StorePerformanceView.swift
//  luxury
//
//  Created by Kaushiki Rai on 26/05/26.
//

import SwiftUI

struct StorePerformanceView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = StorePerformanceViewModel()

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(AppColors.gold)
                    Spacer()
                } else {
                    content
                }
            }
        }
        .navigationTitle("Store Performance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { viewModel.fetchData() }
    }



    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                summaryStrip
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                Text("ALL BOUTIQUES")
                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                    .foregroundStyle(AppColors.secondary)
                    .kerning(1.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)

                VStack(spacing: 12) {
                    ForEach(viewModel.boutiques) { boutique in
                        Button(action: {
                            router.push(CARoute.storePerformanceDetail(boutique))
                        }) {
                            BoutiquePerformanceCard(boutique: boutique)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }
            .padding(.top, 4)
        }
        .refreshable { viewModel.fetchData() }
    }

    private var summaryStrip: some View {
        HStack(spacing: 10) {
            SummaryKPIBox(
                label: "BOUTIQUES",
                value: "\(viewModel.boutiques.count)",
                icon: "building.2.fill",
                color: AppColors.gold
            )
            SummaryKPIBox(
                label: "ON TARGET",
                value: "\(viewModel.boutiques.filter { !$0.isUnderperforming }.count)",
                icon: "checkmark.seal.fill",
                color: AppColors.success
            )
            SummaryKPIBox(
                label: "UNDERPERFORMING",
                value: "\(viewModel.boutiques.filter { $0.isUnderperforming }.count)",
                icon: "exclamationmark.triangle.fill",
                color: AppColors.error
            )
        }
    }
}

private struct SummaryKPIBox: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(AppFonts.sansSerif(size: 14))
                .foregroundStyle(color)
            Text(value)
                .font(AppFonts.serif(size: 26, weight: .bold))
                .foregroundStyle(AppColors.text)
            Text(label)
                .font(AppFonts.sansSerif(size: 9, weight: .bold))
                .foregroundStyle(AppColors.secondary)
                .kerning(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.25), lineWidth: 1))
    }
}

struct BoutiquePerformanceCard: View {
    let boutique: BoutiquePerformance

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(boutique.boutiqueName)
                        .font(AppFonts.serif(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.text)
                    Text(boutique.city)
                        .font(AppFonts.sansSerif(size: 12))
                        .foregroundStyle(AppColors.secondary)
                }
                Spacer()
                if boutique.isUnderperforming {
                    HStack(spacing: 5) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(AppFonts.sansSerif(size: 10))
                        Text("Underperforming")
                            .font(AppFonts.sansSerif(size: 10, weight: .bold))
                    }
                    .foregroundStyle(AppColors.error)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppColors.error.opacity(0.12))
                    .clipShape(Capsule())
                } else {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(AppFonts.sansSerif(size: 10))
                        Text("On Target")
                            .font(AppFonts.sansSerif(size: 10, weight: .bold))
                    }
                    .foregroundStyle(AppColors.success)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppColors.success.opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            Divider().background(AppColors.gold15)

            HStack(spacing: 0) {
                MetricPill(
                    label: "SALES",
                    value: CurrencyManager.shared.format(amount: boutique.totalSales)
                )
                Divider().background(AppColors.gold15).frame(height: 36)
                MetricPill(
                    label: "TARGET",
                    value: CurrencyManager.shared.format(amount: boutique.salesTarget)
                )
                Divider().background(AppColors.gold15).frame(height: 36)
                MetricPill(label: "CONV. RATE", value: (boutique.conversionRate / 100).formatted(.percent.precision(.fractionLength(0))))
                Divider().background(AppColors.gold15).frame(height: 36)
                MetricPill(label: "ATV", value: CurrencyManager.shared.format(amount: boutique.atv))
            }

            AchievementBar(pct: boutique.achievementPct, isUnderperforming: boutique.isUnderperforming)

            HStack {
                Text("\((boutique.achievementPct / 100).formatted(.percent.precision(.fractionLength(0)))) of target achieved")
                    .font(AppFonts.sansSerif(size: 11))
                    .foregroundStyle(boutique.isUnderperforming ? AppColors.error : AppColors.success)
                Spacer()
                HStack(spacing: 4) {
                    Text("View Associates")
                        .font(AppFonts.sansSerif(size: 11, weight: .medium))
                        .foregroundStyle(AppColors.gold)
                    Image(systemName: "chevron.right")
                        .font(AppFonts.sansSerif(size: 10, weight: .semibold))
                        .foregroundStyle(AppColors.gold)
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    boutique.isUnderperforming ? AppColors.error.opacity(0.5) : AppColors.gold15,
                    lineWidth: boutique.isUnderperforming ? 1.5 : 0.5
                )
        )
    }
}

private struct MetricPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppFonts.serif(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.text)
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

private struct AchievementBar: View {
    let pct: Double
    let isUnderperforming: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.surface2)
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 4)
                    .fill(isUnderperforming ? AppColors.error : AppColors.success)
                    .frame(width: min(CGFloat(pct / 100) * geo.size.width, geo.size.width), height: 6)
            }
        }
        .frame(height: 6)
    }
}

#Preview {
    NavigationStack {
        StorePerformanceView()
    }
    .environment(Router())
}
