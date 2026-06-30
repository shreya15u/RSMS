//
//  EditBoutiqueView.swift
//  luxury
//

import SwiftUI

struct EditBoutiqueView: View {
    @State var viewModel: EditBoutiqueViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("BOUTIQUE DETAILS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 16) {
                                LabeledTextField(label: "Boutique Name", text: $viewModel.name)
                                LabeledTextField(label: "Address", text: $viewModel.address)
                                LabeledTextField(label: "City", text: $viewModel.city)
                                LabeledTextField(label: "Pin Code", text: $viewModel.pinCode)
                                    .keyboardType(.numberPad)
                                

                                CustomButton(title: "Save Changes", isLoading: viewModel.isLoading) {
                                    viewModel.saveChanges {
                                        dismiss()
                                    }
                                }
                                .padding(.top, 8)
                            }
                            .padding(16)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                            .padding(.horizontal, 24)
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.error)
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.vertical, 24)
                }
            }
        }
        .navigationTitle("Edit Boutique")
        .navigationBarTitleDisplayMode(.inline)
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
