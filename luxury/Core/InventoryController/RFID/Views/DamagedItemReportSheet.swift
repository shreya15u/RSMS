//
//  DamagedItemReportSheet.swift
//  luxury
//
//  Created by Codex on 26/05/26.
//

import PhotosUI
import SwiftUI
import UIKit

struct DamagedItemReportSheet: View {
    @Environment(\.dismiss) private var dismiss

    let serial: String
    let productName: String
    let existingReport: DamagedDeliveryItemDraft?
    let onSave: (DamagedDeliveryItemDraft) -> Void

    @State private var descriptionText = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoAsset: PickedImageAsset?
    @State private var isLoadingPhoto = false
    @State private var errorMessage: String?
    @State private var showingCamera = false
    @State private var showingCameraUnavailable = false

    private let imagePickerService = ImagePickerService()

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(productName.isEmpty ? "Delivery Item" : productName)
                                .font(AppFonts.serif(size: 28, weight: .semibold))
                                .foregroundStyle(AppColors.text)
                            Text(serial)
                                .font(AppFonts.sansSerif(size: 12, weight: .bold))
                                .foregroundStyle(AppColors.gold)
                                .kerning(1.2)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("FAULT DESCRIPTION")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)

                            TextEditor(text: $descriptionText)
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.text)
                                .frame(minHeight: 140)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(AppColors.gold15, lineWidth: 1)
                                )
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("PHOTO EVIDENCE")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)

                            if let selectedPhotoAsset,
                               let image = UIImage(data: selectedPhotoAsset.data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 220)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            } else {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(AppColors.surface)
                                    .frame(height: 220)
                                    .overlay {
                                        VStack(spacing: 10) {
                                            Image(systemName: "camera.macro")
                                                .font(AppFonts.sansSerif(size: 30))
                                                .foregroundStyle(AppColors.gold)
                                            Text("Attach a clear damage photo")
                                                .font(AppFonts.sansSerif(size: 13))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(AppColors.gold15, lineWidth: 1)
                                    )
                            }

                            HStack(spacing: 12) {
                                Button(action: {
                                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                        showingCamera = true
                                    } else {
                                        showingCameraUnavailable = true
                                    }
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "camera.fill")
                                        Text(selectedPhotoAsset == nil ? "Capture Photo" : "Retake Photo")
                                    }
                                    .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                    .foregroundStyle(AppColors.background)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(AppColors.gold)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                                .disabled(isLoadingPhoto)

                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "photo.on.rectangle")
                                        Text("Gallery")
                                    }
                                    .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                    .foregroundStyle(AppColors.gold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(AppColors.gold50, lineWidth: 0.5)
                                    )
                                }
                                .disabled(isLoadingPhoto)
                            }
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(AppFonts.sansSerif(size: 12))
                                .foregroundStyle(AppColors.error)
                        }

                        CustomButton(
                            title: existingReport == nil ? "Save Damage Report" : "Update Damage Report",
                            icon: AnyView(Image(systemName: "exclamationmark.triangle.fill"))
                        ) {
                            onSave(
                                DamagedDeliveryItemDraft(
                                    serial: serial,
                                    description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
                                    photo: selectedPhotoAsset!
                                )
                            )
                            dismiss()
                        }
                        .disabled(!canSave)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Damage Intake")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.gold)
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraCaptureSheet(
                    onCapture: { image in
                        do {
                            selectedPhotoAsset = try imagePickerService.loadImage(from: image)
                            errorMessage = nil
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                        showingCamera = false
                    },
                    onCancel: {
                        showingCamera = false
                    }
                )
                .ignoresSafeArea()
            }
            .alert("Camera Unavailable", isPresented: $showingCameraUnavailable) {
                Button("OK", role: .cancel) {
                }
            } message: {
                Text("This device does not have camera capture available.")
            }
            .onAppear {
                if let existingReport {
                    descriptionText = existingReport.description
                    selectedPhotoAsset = existingReport.photo
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard newItem != nil else { return }
                isLoadingPhoto = true
                errorMessage = nil

                Task {
                    do {
                        let asset = try await imagePickerService.loadImage(from: newItem)
                        await MainActor.run {
                            selectedPhotoAsset = asset
                            isLoadingPhoto = false
                        }
                    } catch {
                        await MainActor.run {
                            errorMessage = error.localizedDescription
                            isLoadingPhoto = false
                        }
                    }
                }
            }
        }
    }

    private var canSave: Bool {
        !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedPhotoAsset != nil && !isLoadingPhoto
    }
}
