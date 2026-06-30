//
//  ICASTDetailView.swift
//  luxury
//
//  Created by AI on 2026-06-03.
//

import SwiftUI
import Supabase

struct ICASTDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let ast: ASTDetails
    
    @State private var currentStatus: String
    @State private var isUpdating = false
    @State private var errorMessage: String?
    
    init(ast: ASTDetails) {
        self.ast = ast
        self._currentStatus = State(initialValue: ast.status)
    }
    
    var nextStatusText: String? {
        switch currentStatus.lowercased() {
        case "approved": return "Mark as In Progress"
        case "in_progress": return "Mark as Dispatched"
        case "dispatched": return "Mark as Ready for Pickup"
        default: return nil
        }
    }
    
    var nextStatusValue: String? {
        switch currentStatus.lowercased() {
        case "approved": return "in_progress"
        case "in_progress": return "dispatched"
        case "dispatched": return "ready"
        default: return nil
        }
    }
    
    var displayStatus: String {
        switch currentStatus.lowercased() {
        case "approved": return "Approved"
        case "in_progress": return "In Progress"
        case "dispatched": return "Dispatched"
        case "ready": return "Ready for Pickup"
        default: return currentStatus.capitalized
        }
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(ast.catalogs?.name ?? "Service Ticket")
                                .font(AppFonts.serif(size: 24, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            Text("ID: \(ast.catalogs?.catalogId ?? "Unknown")")
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.secondary)
                        }
                        .padding(.top, 16)
                        
                        // Status Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CURRENT STATUS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                            
                            HStack {
                                Circle()
                                    .fill(AppColors.gold)
                                    .frame(width: 10, height: 10)
                                Text(displayStatus)
                                    .font(AppFonts.sansSerif(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 1))
                        }
                        
                        // Details Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("TICKET DETAILS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                DetailRow(title: "Client", value: ast.client?.name ?? "Unknown")
                                Divider().background(AppColors.border)
                                DetailRow(title: "Issue Description", value: ast.description ?? "N/A", valueColor: AppColors.gold)
                                Divider().background(AppColors.border)
                                DetailRow(title: "Remarks", value: ast.remark ?? "No remarks")
                            }
                            .padding(16)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 1))
                        }
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(AppFonts.sansSerif(size: 13))
                                .foregroundStyle(AppColors.error)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                }
            }
            
            // Action Button
            if let nextText = nextStatusText {
                VStack {
                    Spacer()
                    VStack {
                        Button(action: updateStatus) {
                            HStack {
                                if isUpdating {
                                    ProgressView().tint(AppColors.background)
                                } else {
                                    Text(nextText)
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .font(AppFonts.sansSerif(size: 16, weight: .bold))
                            .foregroundStyle(AppColors.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppColors.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(isUpdating)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(colors: [AppColors.background, AppColors.background.opacity(0)], startPoint: .bottom, endPoint: .top)
                    )
                }
            }
        }
        .navigationTitle("Ticket Actions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    private func updateStatus() {
        guard let nextVal = nextStatusValue else { return }
        
        isUpdating = true
        errorMessage = nil
        
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("ast")
                    .update(["status": nextVal])
                    .eq("id", value: ast.id.uuidString)
                    .execute()
                
                await MainActor.run {
                    self.currentStatus = nextVal
                    self.isUpdating = false
                    
                    if nextVal == "ready" {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update status: \(error.localizedDescription)"
                    self.isUpdating = false
                }
            }
        }
    }
}

private struct DetailRow: View {
    let title: String
    let value: String
    var valueColor: Color = .white
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppFonts.sansSerif(size: 12))
                .foregroundStyle(AppColors.secondary)
            Text(value)
                .font(AppFonts.sansSerif(size: 15, weight: .medium))
                .foregroundStyle(valueColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
