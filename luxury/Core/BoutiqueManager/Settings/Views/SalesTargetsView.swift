import SwiftUI

struct SalesTargetsView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = SalesTargetsViewModel()
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Sales Targets", showBackButton: true, backAction: { router.pop() }, isInline: true)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(AppColors.gold)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            
                            // MARK: - Store Target
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("STORE DAILY TARGET")
                                        .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                        .foregroundStyle(AppColors.secondary)
                                        .kerning(1.5)
                                    Text("This applies to the entire boutique collectively")
                                        .font(AppFonts.sansSerif(size: 11))
                                        .foregroundStyle(AppColors.tertiary)
                                }
                                .padding(.horizontal, 24)
                                
                                HStack(spacing: 12) {
                                    HStack(spacing: 6) {
                                        Text(CurrencyManager.shared.symbol)
                                            .font(AppFonts.sansSerif(size: 16, weight: .bold))
                                            .foregroundStyle(AppColors.gold)
                                        
                                        TextField("e.g. 1500000", text: $viewModel.editedBoutiqueTarget)
                                            .font(AppFonts.sansSerif(size: 15))
                                            .foregroundStyle(AppColors.text)
                                            .keyboardType(.numberPad)
                                    }
                                    .padding(12)
                                    .background(AppColors.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(AppColors.border, lineWidth: 1)
                                    )
                                }
                                .padding(16)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                .padding(.horizontal, 24)
                            }
                            
                            // MARK: - Individual Associate Targets
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("INDIVIDUAL ASSOCIATE TARGETS")
                                        .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                        .foregroundStyle(AppColors.secondary)
                                        .kerning(1.5)
                                    Text("Set specific daily targets for each associate")
                                        .font(AppFonts.sansSerif(size: 11))
                                        .foregroundStyle(AppColors.tertiary)
                                }
                                .padding(.horizontal, 24)
                                
                                VStack(spacing: 16) {
                                    if viewModel.staffMembers.isEmpty {
                                        Text("No staff members found.")
                                            .font(AppFonts.sansSerif(size: 14))
                                            .foregroundStyle(AppColors.secondary)
                                            .padding()
                                    } else {
                                        ForEach(viewModel.staffMembers) { staff in
                                            VStack(alignment: .leading, spacing: 10) {
                                                HStack {
                                                    if let url = URL(string: staff.avatarUrl) {
                                                        CachedAsyncImage(url: url) { image in
                                                            image.resizable().scaledToFill()
                                                        } placeholder: {
                                                            Image(systemName: "person.circle.fill").foregroundStyle(AppColors.gold)
                                                        }
                                                        .frame(width: 30, height: 30)
                                                        .clipShape(Circle())
                                                    } else {
                                                        Image(systemName: "person.circle.fill")
                                                            .resizable()
                                                            .frame(width: 30, height: 30)
                                                            .foregroundStyle(AppColors.gold)
                                                    }
                                                    
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(staff.name)
                                                            .font(AppFonts.serif(size: 16, weight: .medium))
                                                            .foregroundStyle(AppColors.text)
                                                        Text(staff.role.displayName)
                                                            .font(AppFonts.sansSerif(size: 10))
                                                            .foregroundStyle(AppColors.secondary)
                                                    }
                                                    Spacer()
                                                }
                                                
                                                HStack(spacing: 6) {
                                                    Text(CurrencyManager.shared.symbol)
                                                        .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                                        .foregroundStyle(AppColors.gold)
                                                    
                                                    TextField("Target amount", text: Binding(
                                                        get: { viewModel.editedStaffTargets[staff.id] ?? "" },
                                                        set: { viewModel.editedStaffTargets[staff.id] = $0 }
                                                    ))
                                                    .font(AppFonts.sansSerif(size: 14))
                                                    .foregroundStyle(AppColors.text)
                                                    .keyboardType(.numberPad)
                                                }
                                                .padding(10)
                                                .background(AppColors.background)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border, lineWidth: 1))
                                            }
                                            .padding(16)
                                            .background(AppColors.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            
                            // MARK: - Save Button
                            VStack(spacing: 12) {
                                if let message = viewModel.saveSuccessMessage {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppColors.success)
                                        Text(message)
                                            .font(AppFonts.sansSerif(size: 12))
                                            .foregroundStyle(AppColors.success)
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                                
                                Button(action: {
                                    Task {
                                        await viewModel.saveTargets()
                                    }
                                }) {
                                    HStack {
                                        if viewModel.isSaving {
                                            ProgressView().tint(AppColors.background)
                                        } else {
                                            Text("Save All Targets")
                                                .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                                .foregroundStyle(AppColors.background)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(AppColors.gold)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .disabled(viewModel.isSaving)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                        }
                        .padding(.top, 24)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.fetchData()
        }
    }
}
