import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = EditProfileViewModel()
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Avatar Picker
                    VStack(spacing: 12) {
                        if let asset = viewModel.selectedPhotoAsset {
                            Image(uiImage: UIImage(data: asset.data) ?? UIImage())
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(AppColors.gold, lineWidth: 1))
                        } else if let urlStr = viewModel.avatarUrl, let url = URL(string: urlStr) {
                            CachedAsyncImage(url: url) { image in
                                image.resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppColors.gold, lineWidth: 1))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundStyle(AppColors.secondary)
                        }
                        
                        PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                            Text("Change Photo")
                                .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.gold)
                        }
                    }
                    .padding(.top, 24)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        CustomTextField(title: "NAME", placeholder: "Name", text: $viewModel.name)
                        
                        // Email is disabled because changing email might require auth changes
                        CustomTextField(title: "EMAIL", placeholder: "Email", text: $viewModel.email)
                            .disabled(true)
                            .opacity(0.6)
                        
                        CustomTextField(title: "PHONE", placeholder: "Phone", text: $viewModel.phone)
                    }
                    .padding(.horizontal, 24)
                    
                    if viewModel.isBoutiqueManager {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("BOUTIQUE DETAILS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                            
                            VStack(spacing: 16) {
                                LabeledTextField(label: "Boutique Name", text: $viewModel.boutiqueName)
                                LabeledTextField(label: "Address", text: $viewModel.boutiqueAddress)
                                LabeledTextField(label: "City", text: $viewModel.boutiqueCity)
                                LabeledTextField(label: "Pin Code", text: $viewModel.boutiquePinCode)
                                    .keyboardType(.numberPad)
                            }
                            .padding(16)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(AppColors.error)
                            .padding(.horizontal, 24)
                    }
                    
                    Spacer(minLength: 40)
                    
                    CustomButton(title: "Save Changes", isLoading: viewModel.isLoading) {
                        Task {
                            await viewModel.saveProfile {
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.fetchProfile()
        }
    }
}

private struct LabeledTextField: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppFonts.sansSerif(size: 12, weight: .medium))
                .foregroundStyle(AppColors.secondary)
            
            TextField("", text: $text)
                .font(AppFonts.sansSerif(size: 15))
                .foregroundStyle(AppColors.text)
                .padding()
                .background(AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.border, lineWidth: 1))
        }
    }
}
