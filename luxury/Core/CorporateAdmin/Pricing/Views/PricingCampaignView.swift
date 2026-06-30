import SwiftUI

struct PricingCampaignView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = PricingCampaignViewModel()
    @State private var showCreateSheet = false
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Pricing & Campaigns")
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Analytics summary
                        HStack(spacing: 16) {
                            MetricCard(title: "Active Campaigns", value: "\(viewModel.campaigns.filter { $0.status == .active }.count)", subtitle: "Global", icon: "tag.fill")
                            MetricCard(title: "Scheduled", value: "\(viewModel.campaigns.filter { $0.status == .scheduled }.count)", subtitle: "Upcoming", icon: "calendar")
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        // Header
                        HStack {
                            Text("ALL CAMPAIGNS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                            Spacer()
                            Button(action: {
                                showCreateSheet = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("New Campaign")
                                        .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppColors.gold15)
                                .foregroundStyle(AppColors.gold)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        // List
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.campaigns) { campaign in
                                campaignCard(campaign)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await viewModel.fetchCampaigns()
                    await viewModel.fetchBoutiques()
                }
            }
        }
        .task {
            await viewModel.fetchCampaigns()
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateCampaignView(viewModel: viewModel)
        }
    }
    
    @ViewBuilder
    private func campaignCard(_ campaign: PricingCampaign) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(campaign.title)
                    .font(AppFonts.serif(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                StatusBadge(text: LocalizedStringKey(campaign.status.rawValue), status: viewModel.badgeStatus(for: campaign.status))
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BOUTIQUE")
                        .font(AppFonts.sansSerif(size: 10))
                        .foregroundStyle(AppColors.secondary)
                    Text(campaign.boutique)
                        .font(AppFonts.sansSerif(size: 13))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("DISCOUNT")
                        .font(AppFonts.sansSerif(size: 10))
                        .foregroundStyle(AppColors.secondary)
                    Text((campaign.discountPercentage / 100).formatted(.percent.precision(.fractionLength(0))))
                        .font(AppFonts.sansSerif(size: 13))
                        .foregroundStyle(AppColors.gold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("DURATION")
                        .font(AppFonts.sansSerif(size: 10))
                        .foregroundStyle(AppColors.secondary)
                    Text("\(formatDate(campaign.startDate)) - \(formatDate(campaign.endDate))")
                        .font(AppFonts.sansSerif(size: 12))
                        .foregroundStyle(AppColors.tertiary)
                }
            }
            
            Divider().background(AppColors.border)
            
            HStack {
                Text("Applies to: \(campaign.affectedCategories.joined(separator: ", "))")
                    .font(AppFonts.sansSerif(size: 11))
                    .foregroundStyle(AppColors.tertiary)
                Spacer()
                if campaign.status == .scheduled || campaign.status == .active {
                    Button(action: {
                        viewModel.toggleStatus(for: campaign)
                    }) {
                        Text(campaign.status == .active ? "End Campaign" : "Activate Now")
                            .font(AppFonts.sansSerif(size: 11, weight: .medium))
                            .foregroundStyle(AppColors.gold)
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
