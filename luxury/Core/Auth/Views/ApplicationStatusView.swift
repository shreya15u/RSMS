//
//  ApplicationStatusView.swift
//  luxury
//
//  Created by Aditya Chauhan on 18/05/26.
//

import SwiftUI

struct ApplicationStatusView: View {
    let role: UserRole
    let status: EntityStatus
    var managerEmail: String?
    var onContactManager: () -> Void
    var onLogout: () -> Void
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: onLogout) {
                        Text("Logout")
                            .font(AppFonts.sansSerif(size: 13))
                            .foregroundStyle(AppColors.gold)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                Spacer()
                
                VStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .stroke(statusColor.opacity(0.2), lineWidth: 1)
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: statusIcon)
                            .font(AppFonts.sansSerif(size: 48))
                            .foregroundStyle(statusColor)
                    }
                    
                    VStack(spacing: 16) {
                        Text(statusTitle)
                            .font(AppFonts.serif(size: 38, weight: .regular))
                            .foregroundStyle(AppColors.text)
                            .multilineTextAlignment(.center)
                        
                        Text(statusMessage)
                            .font(AppFonts.sansSerif(size: 15, weight: .light))
                            .foregroundStyle(AppColors.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, 40)
                    }
                    
                    if status != .pending {
                        CustomButton(title: "Contact Management", action: onContactManager)
                            .padding(.top, 20)
                            .padding(.horizontal, 24)
                    }
                }
                
                Spacer()
                Spacer()
            }
        }
    }
    
    private var statusTitle: String {
        switch status {
        case .pending: return "Application\nPending."
        case .approved: return "Access\nGranted."
        case .rejected: return "Application\nRejected."
        case .paused: return "Account\nPaused."
        }
    }
    
    private var statusMessage: String {
        switch status {
        case .pending:
            if let managerEmail, role != .boutiqueManager {
                return "Thanks for applying! Your request for the \(roleName) role is being reviewed by \(managerEmail)."
            }
            return "Thanks for applying! Your request for the \(roleName) role is being reviewed by the management team."
        case .approved:
            return "Your application has been approved. You can now access the system."
        case .rejected:
            if let managerEmail, role != .boutiqueManager {
                return "Your application for the \(roleName) role has been rejected. Please contact \(managerEmail) for further details."
            }
            return "Your application for the \(roleName) role has been rejected. Please contact management for further details."
        case .paused:
            return "Your account access has been temporarily suspended. Please contact your administrator to resume service."
        }
    }
    
    private var statusIcon: String {
        switch status {
        case .pending: return "clock.fill"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .paused: return "pause.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .pending: return AppColors.gold
        case .approved: return AppColors.success
        case .rejected: return AppColors.error
        case .paused: return AppColors.warning
        }
    }
    
    private var roleName: String {
        switch role {
        case .salesAssociate: return "Sales Associate"
        case .boutiqueManager: return "Boutique Manager"
        case .inventoryController: return "Inventory Controller"
        case .corporateAdmin: return "Corporate Admin"
        }
    }
}
