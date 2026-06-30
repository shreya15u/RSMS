//
//  TeamView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct TeamView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = TeamViewModel()
    
    @State private var showInviteSheet = false
    @State private var inviteEmail = ""
    @State private var invitePassword = ""
    @State private var inviteRole: StaffRole = .salesAssociate
    @State private var isInviting = false
    @State private var inviteError: String?

    var body: some View {
        @Bindable var vm = viewModel
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Text("Team Management")
                        .font(AppFonts.serif(size: 28, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    Button(action: {
                        inviteEmail = ""
                        invitePassword = ""
                        inviteRole = .salesAssociate
                        inviteError = nil
                        showInviteSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(AppFonts.sansSerif(size: 24))
                            .foregroundStyle(AppColors.gold)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .background(AppColors.background)
                
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.tertiary)
                        
                        TextField("Search employees…", text: $vm.searchText)
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(AppColors.text)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.gold15, lineWidth: 0.5)
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView().tint(AppColors.gold)
                        Spacer()
                    } else if let error = viewModel.errorMessage {
                        Spacer()
                        Text(error).font(AppFonts.sansSerif(size: 14)).foregroundStyle(AppColors.error).padding(40)
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            ActiveEmployeesListView(viewModel: viewModel)
                        }
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.fetchData()
        }
        .sheet(isPresented: $showInviteSheet) {
            NavigationStack {
                ZStack {
                    AppColors.background.ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Staff Email")
                                .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                .foregroundStyle(AppColors.secondary)
                            
                            TextField("Enter email address", text: $inviteEmail)
                                .font(AppFonts.sansSerif(size: 16))
                                .foregroundStyle(AppColors.text)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .padding()
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.gold15, lineWidth: 0.5)
                                )
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Initial Password")
                                .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                .foregroundStyle(AppColors.secondary)
                            
                            SecureField("Enter password", text: $invitePassword)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .padding()
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.gold15, lineWidth: 0.5)
                                )
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Staff Role")
                                .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                .foregroundStyle(AppColors.secondary)
                            
                            Menu {
                                Picker("Role", selection: $inviteRole) {
                                    Text("Sales Associate").tag(StaffRole.salesAssociate)
                                    Text("Inventory Controller").tag(StaffRole.inventoryController)
                                }
                            } label: {
                                HStack {
                                    Text(inviteRole.displayName)
                                        .font(AppFonts.sansSerif(size: 16))
                                        .foregroundStyle(AppColors.text)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                                        .foregroundStyle(AppColors.secondary)
                                }
                                .padding()
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.gold15, lineWidth: 0.5)
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        if let inviteError {
                            Text(inviteError)
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.error)
                                .padding(.horizontal, 24)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 24)
                }
                .navigationTitle("Invite Staff")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showInviteSheet = false
                        }
                        .foregroundStyle(AppColors.gold)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if isInviting {
                            ProgressView().tint(AppColors.gold)
                        } else {
                            Button("Send") {
                                sendInvitation()
                            }
                            .disabled(inviteEmail.isEmpty || invitePassword.count < 6)
                            .foregroundStyle((inviteEmail.isEmpty || invitePassword.count < 6) ? AppColors.tertiary : AppColors.gold)
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    private func sendInvitation() {
        guard !inviteEmail.isEmpty && invitePassword.count >= 6 else { return }
        isInviting = true
        inviteError = nil
        
        Task {
            do {
                try await viewModel.inviteStaff(email: inviteEmail, password: invitePassword, role: inviteRole)
                await MainActor.run {
                    isInviting = false
                    showInviteSheet = false
                }
            } catch {
                await MainActor.run {
                    isInviting = false
                    let errorMsg = error.localizedDescription.lowercased()
                    if errorMsg.contains("already registered") || errorMsg.contains("already exists") {
                        inviteError = "This email address is already registered in the system."
                    } else if errorMsg.contains("404") {
                        inviteError = "Invitation service is currently unavailable. Please contact support."
                    } else {
                        inviteError = "Failed to send invitation. Please check the email and try again."
                    }
                }
            }
        }
    }
}

private struct ActiveEmployeesListView: View {
    let viewModel: TeamViewModel
    @Environment(Router.self) private var router
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if viewModel.approvedStaff.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.3.fill")
                        .font(AppFonts.sansSerif(size: 40))
                        .foregroundStyle(AppColors.tertiary)
                    Text("No active employees yet")
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(AppColors.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else if viewModel.filteredStaff.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(AppFonts.sansSerif(size: 40))
                        .foregroundStyle(AppColors.tertiary)
                    Text("No results matching \"\(viewModel.searchText)\"")
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(AppColors.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.filteredStaff) { employee in
                        Button(action: {
                            router.push(BMRoute.staffDetail(employee))
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppColors.gold08)
                                        .frame(width: 44, height: 44)
                                    Text(String(employee.name.prefix(1)))
                                        .font(AppFonts.serif(size: 18, weight: .semibold))
                                        .foregroundStyle(AppColors.gold)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(employee.name)
                                        .font(AppFonts.serif(size: 18, weight: .medium))
                                        .foregroundStyle(AppColors.text)
                                    Text("\(employee.role.displayName) · \(employee.employeeId) · \(employee.phone)")
                                        .font(AppFonts.sansSerif(size: 12))
                                        .foregroundStyle(AppColors.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(AppFonts.sansSerif(size: 12))
                                    .foregroundStyle(AppColors.tertiary)
                            }
                            .padding(18)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}
