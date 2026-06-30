import SwiftUI

struct CampaignSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    var activeCampaigns: [PricingCampaign]
    @Binding var selectedCampaign: PricingCampaign?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        Button(action: {
                            selectedCampaign = nil
                            dismiss()
                        }) {
                            HStack {
                                Text("None")
                                    .font(AppFonts.serif(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                                if selectedCampaign == nil {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(AppColors.gold)
                                }
                            }
                            .padding()
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedCampaign == nil ? AppColors.gold : AppColors.gold15, lineWidth: selectedCampaign == nil ? 1 : 0.5)
                            )
                        }
                        
                        ForEach(activeCampaigns) { campaign in
                            Button(action: {
                                selectedCampaign = campaign
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(campaign.title)
                                            .font(AppFonts.serif(size: 16, weight: .medium))
                                            .foregroundStyle(.white)
                                        Text("\(campaign.discountPercentage / 100, format: .percent.precision(.fractionLength(0))) OFF")
                                            .font(AppFonts.sansSerif(size: 13, weight: .bold))
                                            .foregroundStyle(AppColors.gold)
                                    }
                                    Spacer()
                                    if selectedCampaign == campaign {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(AppColors.gold)
                                    }
                                }
                                .padding()
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedCampaign == campaign ? AppColors.gold : AppColors.gold15, lineWidth: selectedCampaign == campaign ? 1 : 0.5)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Select Campaign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
