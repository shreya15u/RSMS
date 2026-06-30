import SwiftUI

struct CreateCampaignView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: PricingCampaignViewModel
    
    @State private var title = ""
    @State private var boutique = "All Boutiques"
    @State private var discountPercentage: Double = 10.0
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 7)
    
    @State private var selectedCategories: Set<String> = []
    
    var categories: [String] {
        return ["All"] + CatalogCategory.allCases.map { $0.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Details
                        VStack(alignment: .leading, spacing: 16) {
                            Text("CAMPAIGN DETAILS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                            
                            VStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Campaign Title")
                                        .font(AppFonts.sansSerif(size: 13))
                                        .foregroundStyle(AppColors.secondary)
                                    TextField("Enter title...", text: $title)
                                        .font(AppFonts.sansSerif(size: 15))
                                        .foregroundStyle(.white)
                                }
                                .padding()
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1))
                                
                                HStack {
                                    Text("Boutique")
                                        .font(AppFonts.sansSerif(size: 13))
                                        .foregroundStyle(AppColors.secondary)
                                    Spacer()
                                    Picker("Boutique", selection: $boutique) {
                                        ForEach(viewModel.boutiques.isEmpty ? ["All Boutiques"] : viewModel.boutiques, id: \.self) {
                                            Text($0).tag($0)
                                        }
                                    }
                                    .tint(.white)
                                }
                                .padding()
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Discount Percentage")
                                            .font(AppFonts.sansSerif(size: 13))
                                            .foregroundStyle(AppColors.secondary)
                                        Spacer()
                                        Text((discountPercentage / 100).formatted(.percent.precision(.fractionLength(0))))
                                            .font(AppFonts.sansSerif(size: 13, weight: .semibold))
                                            .foregroundStyle(AppColors.gold)
                                    }
                                    Slider(value: $discountPercentage, in: 0...50, step: 1)
                                        .tint(AppColors.gold)
                                }
                                .padding()
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1))
                            }
                        }
                        
                        // Dates
                        VStack(alignment: .leading, spacing: 16) {
                            Text("SCHEDULE")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                            
                            VStack(spacing: 0) {
                                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                    .font(AppFonts.sansSerif(size: 14))
                                    .foregroundStyle(.white)
                                    .padding()
                                
                                Divider().background(AppColors.border)
                                
                                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                                    .font(AppFonts.sansSerif(size: 14))
                                    .foregroundStyle(.white)
                                    .padding()
                            }
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1))
                        }
                        
                        // Categories
                        VStack(alignment: .leading, spacing: 16) {
                            Text("AFFECTED CATEGORIES")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                            
                            let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(categories, id: \.self) { category in
                                    Button(action: {
                                        if selectedCategories.contains(category) {
                                            selectedCategories.remove(category)
                                        } else {
                                            selectedCategories.insert(category)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: selectedCategories.contains(category) ? "checkmark.square.fill" : "square")
                                                .foregroundStyle(selectedCategories.contains(category) ? AppColors.gold : AppColors.tertiary)
                                            Text(category)
                                                .font(AppFonts.sansSerif(size: 13))
                                                .foregroundStyle(.white)
                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(AppColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(selectedCategories.contains(category) ? AppColors.gold : AppColors.border, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("New Campaign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.tertiary)
                    .font(AppFonts.sansSerif(size: 15))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addCampaign(
                            title: title.isEmpty ? "New Campaign" : title,
                            boutique: boutique,
                            discountPercentage: discountPercentage,
                            startDate: startDate,
                            endDate: endDate,
                            categories: Array(selectedCategories).isEmpty ? ["All"] : Array(selectedCategories)
                        )
                        dismiss()
                    }
                    .foregroundStyle(AppColors.gold)
                    .font(AppFonts.sansSerif(size: 15, weight: .bold))
                }
            }
        }
    }
}
