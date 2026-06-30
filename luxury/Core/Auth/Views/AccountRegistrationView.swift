//
//  AccountRegistrationView.swift
//  luxury
//
//  Created by Aditya Chauhan on 18/05/26.
//

import SwiftUI
import PhotosUI

struct AccountRegistrationView: View {
    let role: UserRole
    var onBack: () -> Void
    var onSubmit: () -> Void
    
    @State private var viewModel = RegistrationViewModel()
    @State private var selectedBoutiqueName = "Select Boutique"
    @State private var avatarPickerItem: PhotosPickerItem?
    @State private var resumePickerItem: PhotosPickerItem?
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    headerSection
                    
                    VStack(spacing: 24) {
                        if role == .boutiqueManager {
                            bmFormSection
                        } else {
                            staffFormSection
                        }
                    }
                    
                    termsSection
                    
                    actionSection
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 28)
            }
        }
        .onAppear {
            viewModel.loadUserData()
            if role != .boutiqueManager {
                viewModel.fetchBoutiques()
            }
        }
        .onChange(of: resumePickerItem) { _, newItem in
            viewModel.pickResume(from: newItem)
        }
        .onChange(of: avatarPickerItem) { _, newItem in
            viewModel.pickAvatar(from: newItem)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(AppFonts.sansSerif(size: 20, weight: .semibold))
                    .foregroundStyle(AppColors.gold)
                    .padding(.vertical, 20)
            }
            
            Text(role == .boutiqueManager ? "Boutique\nRegistration." : "Staff\nApplication.")
                .font(AppFonts.serif(size: 46, weight: .light))
                .italic()
                .foregroundStyle(AppColors.text)
                .lineSpacing(-5)
                .padding(.bottom, 16)
            
            Text("Complete your profile to request access.")
                .font(AppFonts.sansSerif(size: 13, weight: .light))
                .foregroundStyle(AppColors.secondary)
        }
    }
    
    private var bmFormSection: some View {
        VStack(spacing: 24) {
            RegistrationField(title: "BOUTIQUE NAME", placeholder: "e.g. Maison Mumbai", text: $viewModel.boutiqueName)
            
            RegistrationField(
                title: "MANAGER NAME",
                placeholder: "Full Name",
                text: $viewModel.name
            )
            
            RegistrationField(
                title: "WORK EMAIL",
                placeholder: "name@luxury.com",
                text: $viewModel.email,
                isReadOnly: true
            )
            
            RegistrationField(title: "PHONE NUMBER", placeholder: "+91", text: $viewModel.phone, keyboardType: .numberPad)
            RegistrationField(title: "ADDRESS", placeholder: "Street, Building", text: $viewModel.address)
            
            HStack(spacing: 16) {
                RegistrationField(title: "CITY", placeholder: "City", text: $viewModel.city)
                RegistrationField(title: "PIN CODE", placeholder: "000000", text: $viewModel.pinCode, keyboardType: .numberPad)
            }
        }
    }
    
    private var staffFormSection: some View {
        VStack(spacing: 24) {
            RegistrationField(
                title: "FULL NAME",
                placeholder: "Full Name",
                text: $viewModel.name
            )
            
            RegistrationField(
                title: "EMAIL ADDRESS",
                placeholder: "name@luxury.com",
                text: $viewModel.email,
                isReadOnly: true
            )
            
            RegistrationField(title: "PHONE NUMBER", placeholder: "+91", text: $viewModel.phone, keyboardType: .numberPad)
            RegistrationField(title: "RESIDENTIAL ADDRESS", placeholder: "Street, Building, City", text: $viewModel.address)
            RegistrationField(title: "PIN CODE", placeholder: "000000", text: $viewModel.pinCode, keyboardType: .numberPad)
            
            RegistrationField(
                title: "ASSIGNED BOUTIQUE",
                placeholder: "Loading...",
                text: $viewModel.city,
                isReadOnly: true
            )
            
            VStack(spacing: 16) {
                PhotosPicker(selection: $resumePickerItem, matching: .images) {
                    UploadButtonLabel(title: "CURRICULUM VITAE", isUploaded: viewModel.resumeImage != nil, icon: "doc.text")
                }
                .buttonStyle(.plain)
                
                PhotosPicker(selection: $avatarPickerItem, matching: .images) {
                    UploadButtonLabel(title: "PROFILE PHOTOGRAPH", isUploaded: viewModel.avatarImage != nil, icon: "person.crop.square")
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
        }
    }
    
    private var termsSection: some View {
        Button(action: { viewModel.acceptedTerms.toggle() }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: viewModel.acceptedTerms ? "checkmark.square.fill" : "square")
                    .font(AppFonts.sansSerif(size: 20))
                    .foregroundStyle(AppColors.gold)
                
                Text("I agree to the internal policies, data privacy agreement, and terms of service required for system access.")
                    .font(AppFonts.sansSerif(size: 11, weight: .light))
                    .foregroundStyle(AppColors.secondary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(AppFonts.sansSerif(size: 12))
                    .foregroundStyle(AppColors.error)
            }
            
            CustomButton(
                title: "Submit Application",
                isLoading: viewModel.isLoading,
                action: {
                    viewModel.submitApplication(role: role, completion: onSubmit)
                }
            )
            .disabled(!viewModel.acceptedTerms)
            .opacity(viewModel.acceptedTerms ? 1.0 : 0.5)
        }
    }
}

private struct RegistrationField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var isReadOnly = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                .foregroundStyle(AppColors.secondary)
                .kerning(1.5)
            
            Group {
                if isSecure {
                    SecureField("", text: $text, prompt: Text(placeholder).foregroundStyle(AppColors.tertiary))
                } else {
                    TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(AppColors.tertiary))
                }
            }
            .font(AppFonts.sansSerif(size: 16, weight: .light))
            .foregroundStyle(isReadOnly ? AppColors.tertiary : AppColors.text)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .keyboardType(keyboardType)
            .disabled(isReadOnly)
            .opacity(isReadOnly ? 0.6 : 1.0)
            
            Rectangle()
                .fill(AppColors.gold15)
                .frame(height: 1)
        }
    }
}

private struct UploadButtonLabel: View {
    let title: String
    let isUploaded: Bool
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.sansSerif(size: 9, weight: .bold))
                .foregroundStyle(AppColors.secondary)
                .kerning(1.5)
            
            HStack(spacing: 12) {
                Image(systemName: isUploaded ? "checkmark" : icon)
                    .font(AppFonts.sansSerif(size: 14))
                    .foregroundStyle(isUploaded ? AppColors.success : AppColors.gold)
                
                Text(isUploaded ? "Image attached successfully" : "Upload image")
                    .font(AppFonts.sansSerif(size: 14, weight: .light))
                    .foregroundStyle(isUploaded ? AppColors.text : AppColors.tertiary)
                
                Spacer()
                
                Image(systemName: "arrow.up.circle")
                    .font(AppFonts.sansSerif(size: 16))
                    .foregroundStyle(isUploaded ? AppColors.success : AppColors.gold.opacity(0.4))
            }
            .padding(.vertical, 12)
            
            Rectangle()
                .fill(isUploaded ? AppColors.success.opacity(0.3) : AppColors.gold15)
                .frame(height: 1)
        }
        .contentShape(Rectangle())
    }
}
