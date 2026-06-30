import SwiftUI
import Supabase
import PostgREST

struct BoutiqueManagerProfileView: View {
    @Environment(BoutiqueManagerAppState.self) private var bmAppState
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(Router.self) private var router
    @State private var viewModel = SharedProfileViewModel()
    @State private var showLogoutAlert = false
    @State private var currencyManager = CurrencyManager.shared

    
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
                                Text("\(viewModel.roleName.isEmpty ? "BOUTIQUE MANAGER" : viewModel.roleName.uppercased()) · \(formattedDate)")
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
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("MANAGEMENT")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                Button(action: {
                                    router.push(BMRoute.reportsAnalytics)
                                }) {
                                    HStack {
                                        Image(systemName: "chart.bar.doc.horizontal.fill")
                                            .font(AppFonts.sansSerif(size: 18))
                                            .foregroundStyle(AppColors.gold)
                                            .frame(width: 24, alignment: .center)
                                        Text("Reports & Analytics")
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
                                    router.push(BMRoute.salesTargets)
                                }) {
                                    HStack {
                                        Image(systemName: "target")
                                            .font(AppFonts.sansSerif(size: 18))
                                            .foregroundStyle(AppColors.gold)
                                            .frame(width: 24, alignment: .center)
                                        Text("Sales Targets")
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
                        
                        // Settings
                        VStack(alignment: .leading, spacing: 16) {
                            Text("SETTINGS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                Button(action: {
                                    router.push(BMRoute.editProfile)
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

                                HStack {
                                    Image(systemName: "banknote.fill")
                                        .font(AppFonts.sansSerif(size: 18))
                                        .foregroundStyle(AppColors.gold)
                                        .frame(width: 24, alignment: .center)
                                    Text("Global Currency")
                                        .font(AppFonts.sansSerif(size: 15))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Picker("Currency", selection: $currencyManager.currentCurrency) {
                                        ForEach(currencyManager.availableCurrencies, id: \.self) { code in
                                            Text("\(code) (\(currencyManager.symbol(for: code)))").tag(code)
                                        }
                                    }
                                    .tint(AppColors.gold)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                
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
                            
                            Button(action: {
                                router.push(BMRoute.storePolicies)
                            }) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .font(AppFonts.sansSerif(size: 18))
                                        .foregroundStyle(AppColors.gold)
                                    Text("Store Policies")
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
                        .padding(.top, 24)
                        
                        // Removed redundant PREFERENCES section
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
            await fetchCurrency()
        }
        .onChange(of: currencyManager.currentCurrency) { _, newCurrency in
            Task {
                await saveCurrency(newCurrency)
            }
        }
    }

    
    private func fetchCurrency() async {
        do {
            if let (_, profileData) = try await ProfileService().fetchCurrentProfile(),
               let boutique = profileData as? CorporateBoutique {
                if let currencyCode = boutique.currency, !currencyCode.isEmpty {
                    await MainActor.run {
                        currencyManager.currentCurrency = currencyCode
                    }
                }
            }
        } catch {
            print("Failed to fetch currency: \(error)")
        }
    }
    
    private func saveCurrency(_ code: String) async {
        do {
            if let (_, profileData) = try await ProfileService().fetchCurrentProfile(),
               let boutique = profileData as? CorporateBoutique {
                struct UpdateCurrencyRequest: Encodable {
                    let currency: String
                }
                try await SupabaseManager.shared.client
                    .from("boutiques")
                    .update(UpdateCurrencyRequest(currency: code))
                    .eq("id", value: boutique.id)
                    .execute()
            }
        } catch {
            print("Failed to save currency: \(error)")
        }
    }
}
