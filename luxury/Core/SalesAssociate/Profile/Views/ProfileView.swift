//
//  ProfileView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(SalesAssociateAppState.self) private var saAppState
    @Environment(Router.self) private var router
    @State private var viewModel = SAProfileViewModel()
    @State private var showLogoutAlert = false
    
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: Date()).uppercased()
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("\(viewModel.store) · \(formattedDate)")
                                    .font(AppFonts.sansSerif(size: 10))
                                    .foregroundStyle(AppColors.gold)
                                    .kerning(2)
                                    .textCase(.uppercase)
                                Text(viewModel.greeting)
                                    .font(AppFonts.serif(size: 30, weight: .light).italic())
                                    .foregroundStyle(AppColors.text)
                                Text(viewModel.name)
                                    .font(AppFonts.serif(size: 30, weight: .semibold))
                                    .foregroundStyle(AppColors.text)
                            }
                            
                            Spacer()
                            
                            if let avatar = viewModel.avatarUrl, !avatar.isEmpty, let url = URL(string: avatar) {
                                CachedAsyncImage(url: url) { image in
                                    image.resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundStyle(AppColors.gold)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 18)
                        
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("MONTHLY REVENUE")
                                        .font(AppFonts.sansSerif(size: 10))
                                        .foregroundStyle(AppColors.secondary)
                                        .kerning(1.5)
                                    Text(CurrencyManager.shared.format(amount: viewModel.revenue))
                                        .font(AppFonts.serif(size: 36, weight: .medium))
                                        .foregroundStyle(AppColors.gold)
                                        .kerning(-0.5)
                                    Text("of \(CurrencyManager.shared.format(amount: viewModel.target)) target")
                                        .font(AppFonts.sansSerif(size: 11))
                                        .foregroundStyle(AppColors.secondary)
                                        .padding(.top, 2)
                                }
                                Spacer()
                                Text(viewModel.progress.formatted(.percent.precision(.fractionLength(0))))
                                    .font(AppFonts.sansSerif(size: 13, weight: .medium))
                                    .foregroundStyle(AppColors.gold)
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 5)
                                    .background(AppColors.gold08)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(AppColors.gold15, lineWidth: 0.5))
                            }
                            ProgressView(value: viewModel.progress)
                                .progressViewStyle(LuxuryProgressStyle())
                        }
                        .padding(18)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                        .padding(.horizontal, 24)
                        .padding(.top, 18)
                        
                        HStack(spacing: 10) {
                            StatChip(value: viewModel.statClients, label: "Clients")
                                .onTapGesture {
                                    saAppState.selectedTab = .clients
                                }
                            StatChip(value: viewModel.statTransactions, label: "Transactions")
                                .onTapGesture {
                                    router.push(SARoute.transactionList(viewModel.recentTransactions))
                                }
                            StatChip(value: viewModel.statAppts, label: "Appts")
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        
                        

                            // MARK: - Quick Links
                            VStack(alignment: .leading, spacing: 16) {
                                Text("QUICK LINKS")
                                    .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1.5)
                                    .padding(.horizontal, 24)
                                
                                VStack(spacing: 12) {
                                    Button(action: {
                                        router.push(SARoute.appointmentList)
                                    }) {
                                        HStack {
                                            Image(systemName: "calendar")
                                                .font(AppFonts.sansSerif(size: 18))
                                                .foregroundStyle(AppColors.gold)
                                                .frame(width: 24, alignment: .center)
                                            Text("My Appointments")
                                                .font(AppFonts.sansSerif(size: 15))
                                                .foregroundStyle(.white)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.tertiary)
                                        }
                                        .padding(16)
                                        .background(AppColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button(action: {
                                        if let bId = viewModel.boutiqueId {
                                            router.push(SARoute.planogramGallery(boutiqueId: bId))
                                        } else {
                                            router.push(SARoute.planogramGallery(boutiqueId: UUID()))
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "photo.artframe")
                                                .font(AppFonts.sansSerif(size: 18))
                                                .foregroundStyle(AppColors.gold)
                                                .frame(width: 24, alignment: .center)
                                            Text("Visual Merchandising")
                                                .font(AppFonts.sansSerif(size: 15))
                                                .foregroundStyle(.white)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.tertiary)
                                        }
                                        .padding(16)
                                        .background(AppColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 24)
                            }
                            .padding(.top, 18)
                            
                            // MARK: - Settings
                            VStack(alignment: .leading, spacing: 16) {
                                Text("SETTINGS")
                                    .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1.5)
                                    .padding(.horizontal, 24)
                                
                                VStack(spacing: 12) {
                                    Button(action: {
                                        router.push(SARoute.editProfile)
                                    }) {
                                        HStack {
                                            Image(systemName: "person.crop.circle")
                                                .font(AppFonts.sansSerif(size: 18))
                                                .foregroundStyle(AppColors.gold)
                                                .frame(width: 24, alignment: .center)
                                            Text("Edit Profile")
                                                .font(AppFonts.sansSerif(size: 15))
                                                .foregroundStyle(.white)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.tertiary)
                                        }
                                        .padding(16)
                                        .background(AppColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    NavigationLink(destination: LanguageSettingsView()) {
                                        HStack {
                                            Image(systemName: "globe")
                                                .font(AppFonts.sansSerif(size: 18))
                                                .foregroundStyle(AppColors.gold)
                                                .frame(width: 24, alignment: .center)
                                            Text("Language Settings")
                                                .font(AppFonts.sansSerif(size: 15))
                                                .foregroundStyle(.white)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.tertiary)
                                        }
                                        .padding(16)
                                        .background(AppColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    NavigationLink(destination: SecuritySettingsView()) {
                                        HStack {
                                            Image(systemName: "lock.shield.fill")
                                                .font(AppFonts.sansSerif(size: 18))
                                                .foregroundStyle(AppColors.gold)
                                                .frame(width: 24, alignment: .center)
                                            Text("Security Settings")
                                                .font(AppFonts.sansSerif(size: 15))
                                                .foregroundStyle(.white)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.tertiary)
                                        }
                                        .padding(16)
                                        .background(AppColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 24)
                            }
                            .padding(.top, 18)
                            
                            
                            
                            // MARK: - Support & Policies
                            VStack(alignment: .leading, spacing: 16) {
                                Text("SUPPORT & POLICIES")
                                    .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1.5)
                                    .padding(.horizontal, 24)
                                
                                Button(action: {
                                    router.push(SARoute.exchangePolicy)
                                }) {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .font(AppFonts.sansSerif(size: 18))
                                            .foregroundStyle(AppColors.gold)
                                        Text("Exchange Policy")
                                            .font(AppFonts.sansSerif(size: 15))
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(AppFonts.sansSerif(size: 12))
                                            .foregroundStyle(AppColors.tertiary)
                                    }
                                    .padding(16)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 24)
                            }
                            .padding(.top, 18)
                            
                            CustomButton(title: "Logout", action: { showLogoutAlert = true })
                                .padding(.horizontal, 24)
                                .padding(.top, 30)
                                .padding(.bottom, 60)
                        }
                    }
                    .refreshable {
                        await viewModel.fetchAppointments()
                    }
                }
            }
            .task {
                await viewModel.fetchAppointments()
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Logout", role: .destructive) {
                    coordinator.logout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
    
    private struct StatChip: View {
        let value: String
        let label: String
        
        var body: some View {
            VStack(spacing: 4) {
                Text(value)
                    .font(AppFonts.serif(size: 27, weight: .medium))
                    .foregroundStyle(AppColors.text)
                Text(label)
                    .font(AppFonts.sansSerif(size: 10))
                    .foregroundStyle(AppColors.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
        }
}
