import SwiftUI
import Supabase

struct ICProfileView: View {
    @Environment(InventoryControllerAppState.self) private var icAppState
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(Router.self) private var router
    @State private var viewModel = SharedProfileViewModel()
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
                                Text("\(viewModel.roleName.isEmpty ? "INVENTORY CONTROLLER" : viewModel.roleName.uppercased()) · \(formattedDate)")
                                    .font(AppFonts.sansSerif(size: 10))
                                    .foregroundStyle(AppColors.gold)
                                    .kerning(2)
                                    .textCase(.uppercase)
                                Text("Welcome,")
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
                        
                        // Settings
                        VStack(alignment: .leading, spacing: 16) {
                            Text("SETTINGS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                Button(action: {
                                    router.push(ICRoute.editProfile)
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
                        .padding(.top, 24)
                        
                        CustomButton(title: "Logout", action: { showLogoutAlert = true })
                            .padding(.horizontal, 24)
                            .padding(.top, 40)
                            .padding(.bottom, 60)
                    }
                }
                .refreshable {
                    await viewModel.fetchProfile()
                }
            }
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
        .task {
            await viewModel.fetchProfile()
        }
    }
}
