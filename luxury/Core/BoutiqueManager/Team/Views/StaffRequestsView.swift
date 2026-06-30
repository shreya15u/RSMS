import SwiftUI

struct StaffRequestsView: View {
    @State private var viewModel = TeamViewModel()
    @State private var selectedStaff: StaffModel?
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("STAFF APPLICATIONS")
                    .font(AppFonts.sansSerif(size: 10, weight: .bold))
                    .foregroundStyle(AppColors.gold)
                    .kerning(1.5)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(AppColors.gold).frame(maxWidth: .infinity)
                    Spacer()
                } else if viewModel.pendingStaff.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(AppFonts.sansSerif(size: 40))
                            .foregroundStyle(AppColors.tertiary)
                        Text("No pending staff requests")
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(AppColors.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(viewModel.pendingStaff) { request in
                                staffRequestRow(name: request.name, role: request.role.displayName, date: request.createdAt, request: request)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            viewModel.fetchData()
        }
        .sheet(item: $selectedStaff) { staff in
            RequestDetailSheet(
                title: LocalizedStringKey(staff.name),
                subtitle: LocalizedStringKey(staff.role.displayName),
                details: [
                    ("Email", staff.email),
                    ("Address", staff.address),
                    ("Status", staff.status.rawValue.capitalized)
                ],
                avatarUrl: staff.avatarUrl,
                resumeUrl: staff.resumeUrl,
                isApproving: viewModel.actionStaffId == staff.id,
                isRejecting: viewModel.actionStaffId == staff.id,
                onApprove: {
                    viewModel.approveStaffMember(staff) {
                        selectedStaff = nil
                    }
                },
                onReject: {
                    viewModel.rejectStaffMember(staff) {
                        selectedStaff = nil
                    }
                }
            )
        }
    }
    
    private func staffRequestRow(name: String, role: String, date: Date, request: StaffModel) -> some View {
        Button(action: {
            selectedStaff = request
        }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.gold08)
                        .frame(width: 44, height: 44)
                    Text(String(name.prefix(1)))
                        .font(AppFonts.serif(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.gold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(AppFonts.serif(size: 18, weight: .medium))
                        .foregroundStyle(AppColors.text)
                    Text("\(role) · \(RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date()))")
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
