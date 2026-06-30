import SwiftUI
import Supabase
import PostgREST

struct EmployeeDetailView: View {
    let employee: StaffModel
    @State private var boutiqueManagerName: String?
    @Environment(Router.self) private var router
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("Staff Details")
                        .font(AppFonts.serif(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        HStack(spacing: 16) {
                            if let url = URL(string: employee.avatarUrl) {
                                CachedAsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    ZStack {
                                        AppColors.gold08
                                        ProgressView().tint(AppColors.gold).scaleEffect(0.8)
                                    }
                                }
                                .frame(width: 72, height: 72)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(AppColors.gold15, lineWidth: 1))
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(AppColors.gold08)
                                        .frame(width: 72, height: 72)
                                    Text(String(employee.name.prefix(1)))
                                        .font(AppFonts.serif(size: 28, weight: .semibold))
                                        .foregroundStyle(AppColors.gold)
                                }
                                .overlay(Circle().stroke(AppColors.gold15, lineWidth: 1))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(employee.role.displayName.uppercased())
                                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                    .foregroundStyle(AppColors.gold)
                                    .kerning(2)
                                Text(employee.name)
                                    .font(AppFonts.serif(size: 28, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        VStack(spacing: 0) {
                            let details = [
                                ("Employee ID", employee.employeeId),
                                ("Email", employee.email),
                                ("Phone", employee.phone),
                                ("Address", employee.address),
                                ("Location", employee.location),
                                ("City", employee.city),
                                ("Pin Code", employee.pinCode)
                            ]
                            
                            ForEach(0..<details.count, id: \.self) { i in
                                HStack {
                                    Text(details[i].0)
                                        .font(AppFonts.sansSerif(size: 13))
                                        .foregroundStyle(AppColors.secondary)
                                    Spacer()
                                    Text(details[i].1)
                                        .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                        .foregroundStyle(.white)
                                }
                                .padding(.vertical, 16)
                                
                                    if i < details.count - 1 {
                                        Divider().background(AppColors.gold15)
                                    }
                                }
                                
                                if employee.role != .inventoryController {
                                    Divider().background(AppColors.gold15)
                                    
                                    HStack {
                                        Text("Daily Target")
                                            .font(AppFonts.sansSerif(size: 13))
                                            .foregroundStyle(AppColors.secondary)
                                        Spacer()
                                        if let target = employee.dailySalesTarget {
                                            Text(CurrencyManager.shared.format(amount: target))
                                                .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                                .foregroundStyle(AppColors.gold)
                                        } else {
                                            Text("Not Set")
                                                .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .padding(.vertical, 16)
                                }
                                
                                if let manager = boutiqueManagerName {
                                    Divider().background(AppColors.gold15)
                                    
                                    HStack {
                                        Text("Boutique Manager")
                                            .font(AppFonts.sansSerif(size: 13))
                                            .foregroundStyle(AppColors.secondary)
                                        Spacer()
                                        Text(manager)
                                            .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                            .foregroundStyle(AppColors.gold)
                                    }
                                    .padding(.vertical, 16)
                                }
                            }
                        .padding(20)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                        .padding(.horizontal, 24)
                        
                        if let url = URL(string: employee.resumeUrl) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("RESUME")
                                    .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                    .foregroundStyle(AppColors.secondary)
                                    .kerning(1.5)
                                
                                CachedAsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    HStack {
                                        Spacer()
                                        ProgressView().tint(AppColors.gold)
                                        Spacer()
                                    }
                                    .frame(height: 200)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            if let boutiqueId = employee.boutiqueId {
                if let boutique: [CorporateBoutique] = try? await SupabaseManager.shared.client.from("boutiques")
                    .select()
                    .eq("id", value: boutiqueId)
                    .execute().value, let first = boutique.first {
                    await MainActor.run {
                        self.boutiqueManagerName = first.managerName
                    }
                }
            }
        }
    }
}
