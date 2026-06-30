//
//  BoutiqueDetailView.swift
//  luxury
//
//  Created by Aditya Chauhan on 20/05/26.
//

import SwiftUI
import Supabase
import PostgREST

struct BoutiqueDetailView: View {
    @State private var currentBoutique: CorporateBoutique
    let originalBoutiqueId: UUID
    @Bindable var viewModel: UserManagementViewModel
    @Environment(Router.self) private var router
    @State private var showEditBoutique = false
    @State private var showDisableAlert = false
    @State private var showEnableAlert = false
    @State private var showRemoveAlert = false
    @State private var showSetTargetAlert = false
    @State private var targetInput = ""
    @State private var isSettingTarget = false

    init(boutique: CorporateBoutique, viewModel: UserManagementViewModel) {
        _currentBoutique = State(initialValue: boutique)
        self.originalBoutiqueId = boutique.id
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(currentBoutique.name)
                                .font(AppFonts.serif(size: 32, weight: .bold))
                                .foregroundStyle(AppColors.gold)
                            Text("\(currentBoutique.city) · \(currentBoutique.status.rawValue.capitalized)")
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(statusColor(currentBoutique.status))
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("MANAGER DETAILS")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                InfoDetailRow(label: "Manager Name", value: currentBoutique.managerName)
                                InfoDetailRow(label: "Manager Email", value: currentBoutique.managerEmail)
                                InfoDetailRow(label: "Manager Phone", value: currentBoutique.managerPhone)
                            }
                            .padding(20)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                            .padding(.horizontal, 24)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("LOCATION DETAILS")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                InfoDetailRow(label: "City", value: currentBoutique.city)
                                InfoDetailRow(label: "Address", value: currentBoutique.address)
                                InfoDetailRow(label: "Pin Code", value: currentBoutique.pinCode)
                                if let target = currentBoutique.dailySalesTarget {
                                    InfoDetailRow(label: "Daily Target", value: CurrencyManager.shared.format(amount: target))
                                }
                            }
                            .padding(20)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                            .padding(.horizontal, 24)
                        }
                        
                        if let error = viewModel.actionErrorMessage, viewModel.actionBoutiqueId == currentBoutique.id {
                            Text(error)
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.error)
                                .padding(.horizontal, 24)
                        }
                        
                        if currentBoutique.status == .pending {
                            VStack(spacing: 16) {
                                Button(action: {
                                    viewModel.approveBoutique(currentBoutique) {
                                        router.pop()
                                    }
                                }) {
                                    HStack {
                                        Spacer()
                                        if viewModel.actionBoutiqueId == currentBoutique.id {
                                            ProgressView().tint(.black)
                                        } else {
                                            Text("Approve Request")
                                                .font(AppFonts.sansSerif(size: 16, weight: .semibold))
                                                .foregroundStyle(.black)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 16)
                                    .background(AppColors.gold)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .disabled(viewModel.actionBoutiqueId != nil)
                                
                                Button(action: {
                                    viewModel.rejectBoutique(currentBoutique) {
                                        router.pop()
                                    }
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("Reject Request")
                                            .font(AppFonts.sansSerif(size: 16, weight: .semibold))
                                            .foregroundStyle(AppColors.error)
                                        Spacer()
                                    }
                                    .padding(.vertical, 16)
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.error, lineWidth: 1)
                                    )
                                }
                                .disabled(viewModel.actionBoutiqueId != nil)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                        } else if currentBoutique.status == .approved || currentBoutique.status == .paused {
                            VStack(spacing: 16) {
                                if currentBoutique.status == .approved {
                                    Button(action: {
                                        showDisableAlert = true
                                    }) {
                                        HStack {
                                            Spacer()
                                            if viewModel.actionBoutiqueId == currentBoutique.id {
                                                ProgressView().tint(.white)
                                            } else {
                                                Text("Disable Boutique")
                                                    .font(AppFonts.sansSerif(size: 16, weight: .semibold))
                                                    .foregroundStyle(.white)
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 16)
                                        .background(AppColors.gold.opacity(0.8))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .disabled(viewModel.actionBoutiqueId != nil)
                                } else {
                                    Button(action: {
                                        showEnableAlert = true
                                    }) {
                                        HStack {
                                            Spacer()
                                            if viewModel.actionBoutiqueId == currentBoutique.id {
                                                ProgressView().tint(.white)
                                            } else {
                                                Text("Enable Boutique")
                                                    .font(AppFonts.sansSerif(size: 16, weight: .semibold))
                                                    .foregroundStyle(.white)
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 16)
                                        .background(AppColors.success)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .disabled(viewModel.actionBoutiqueId != nil)
                                }
                                
                                Button(action: {
                                    showRemoveAlert = true
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("Remove Boutique")
                                            .font(AppFonts.sansSerif(size: 16, weight: .semibold))
                                            .foregroundStyle(AppColors.error)
                                        Spacer()
                                    }
                                    .padding(.vertical, 16)
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.error, lineWidth: 1)
                                    )
                                }
                                .disabled(viewModel.actionBoutiqueId != nil)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                        }
                    }
                    .padding(.vertical, 24)
                }
            }
        }
        .navigationTitle("Boutique Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: {
                    targetInput = currentBoutique.dailySalesTarget.map { String($0) } ?? ""
                    showSetTargetAlert = true
                }) {
                    Text("Set Target")
                        .font(AppFonts.sansSerif(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.gold)
                }
                
                Button(action: { showEditBoutique = true }) {
                    Text("Edit")
                        .font(AppFonts.sansSerif(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.gold)
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showEditBoutique, onDismiss: {
            Task {
                if let updated = try? await ProfileService().fetchBoutique(id: originalBoutiqueId) {
                    await MainActor.run {
                        self.currentBoutique = updated
                    }
                }
            }
        }) {
            EditBoutiqueView(viewModel: EditBoutiqueViewModel(boutique: currentBoutique))
        }
        .alert("Disable Boutique", isPresented: $showDisableAlert) {
            Button("Disable", role: .destructive) {
                viewModel.disableBoutique(currentBoutique) {
                    router.pop()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to disable this boutique?")
        }
        .alert("Enable Boutique", isPresented: $showEnableAlert) {
            Button("Enable") {
                viewModel.enableBoutique(currentBoutique) {
                    router.pop()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to enable this boutique?")
        }
        .alert("Remove Boutique", isPresented: $showRemoveAlert) {
            Button("Remove", role: .destructive) {
                viewModel.removeBoutique(currentBoutique) {
                    router.pop()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to completely remove this boutique?")
        }
        .alert("Set Daily Sales Target", isPresented: $showSetTargetAlert) {
            TextField("Amount (e.g. 5000)", text: $targetInput)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                saveTarget()
            }
        } message: {
            Text("Enter the daily sales target for this boutique.")
        }
    }
    
    private func saveTarget() {
        guard let value = Double(targetInput) else { return }
        isSettingTarget = true
        Task {
            do {
                struct UpdateTarget: Encodable {
                    let daily_sales_target: Double
                }
                let data = UpdateTarget(daily_sales_target: value)
                
                try await SupabaseManager.shared.client.from("boutiques")
                    .update(data)
                    .eq("id", value: currentBoutique.id)
                    .execute()
                
                if let updated: [CorporateBoutique] = try? await SupabaseManager.shared.client.from("boutiques")
                    .select()
                    .eq("id", value: currentBoutique.id)
                    .execute().value, let first = updated.first {
                    await MainActor.run {
                        self.currentBoutique = first
                    }
                }
            } catch {
                print("Failed to set target: \(error)")
            }
            await MainActor.run {
                self.isSettingTarget = false
            }
        }
    }
    private func statusColor(_ status: EntityStatus) -> Color {
        switch status {
        case .pending:
            return AppColors.gold
        case .approved:
            return .green
        case .rejected:
            return AppColors.error
        case .paused:
            return .orange
        }
    }
}

private struct InfoDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(AppFonts.sansSerif(size: 14))
                .foregroundStyle(AppColors.secondary)
            Spacer()
            Text(value)
                .font(AppFonts.sansSerif(size: 14, weight: .medium))
                .foregroundStyle(AppColors.text)
                .multilineTextAlignment(.trailing)
        }
    }
}
