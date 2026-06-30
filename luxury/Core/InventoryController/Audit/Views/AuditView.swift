import SwiftUI

struct AuditView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(Router.self) private var router
    @State private var viewModel = AuditViewModel()
    @State private var showUpcomingToast = false
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Inventory Audit")
                
                if viewModel.isLoading {
                    List {
                        Section {
                            ForEach(0..<2, id: \.self) { _ in
                                SkeletonAuditRow()
                                    .listRowBackground(AppColors.surface)
                            }
                        } header: {
                            Text("SCHEDULED COUNTS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                        }
                        
                        Section {
                            ForEach(0..<3, id: \.self) { _ in
                                SkeletonAuditRow()
                                    .listRowBackground(AppColors.surface)
                            }
                        } header: {
                            Text("RECENT SIGN-OFFS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(AppColors.background)
                    .refreshable {
                        await viewModel.loadData()
                    }
                } else {
                    List {
                        Section {
                            let counts = viewModel.scheduledCounts
                            if counts.isEmpty {
                                HStack {
                                    Spacer()
                                    Text("No current scheduled")
                                        .font(AppFonts.sansSerif(size: 13))
                                        .foregroundStyle(AppColors.secondary)
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .listRowBackground(AppColors.surface)
                            } else {
                                ForEach(counts, id: \.id) { count in
                                    Button(action: {
                                        if count.status == "UPCOMING" {
                                            withAnimation { showUpcomingToast = true }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                                withAnimation { showUpcomingToast = false }
                                            }
                                        } else if count.status == "SIGNED OFF" || count.status == "Signed Off" || count.status == "Submitted" {
                                            router.push(ICRoute.varianceReport(count))
                                        } else {
                                            router.presentFullScreen(ICRoute.auditDetail(count))
                                        }
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(count.title)
                                                    .font(AppFonts.serif(size: 17, weight: .medium))
                                                    .foregroundStyle(AppColors.text)
                                                HStack(spacing: 8) {
                                                    Text(count.scope)
                                                    Text("•")
                                                    Text(count.date)
                                                }
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.secondary)
                                            }
                                            Spacer()
                                            StatusBadge(text: LocalizedStringKey(count.status), status: count.badgeStatus)
                                        }
                                    }
                                    .listRowBackground(AppColors.surface)
                                }
                            }
                        } header: {
                            Text("SCHEDULED COUNTS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                        }
                        
                        Section {
                            let audits = viewModel.recentAudits
                            ForEach(audits, id: \.id) { count in
                                Button(action: { router.push(ICRoute.varianceReport(count)) }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(count.title)
                                                .font(AppFonts.serif(size: 17, weight: .medium))
                                                .foregroundStyle(AppColors.text)
                                            Text(count.date)
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                        Spacer()
                                        StatusBadge(text: LocalizedStringKey(count.status), status: count.badgeStatus)
                                    }
                                }
                                .listRowBackground(AppColors.surface)
                            }
                        } header: {
                            Text("RECENT SIGN-OFFS")
                                .font(AppFonts.sansSerif(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                        }

                    }
                    .scrollContentBackground(.hidden)
                    .background(AppColors.background)
                    .refreshable {
                        await viewModel.loadData()
                    }
                }
            }
            
            if showUpcomingToast {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppColors.warning)
                        Text("Audit locked until scheduled date.")
                            .font(AppFonts.sansSerif(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.warning, lineWidth: 1))
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .onAppear {
            viewModel.refreshData()
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct SkeletonAuditRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.surface2)
                    .frame(width: 120, height: 18)
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.surface2)
                    .frame(width: 180, height: 12)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.surface2)
                .frame(width: 80, height: 24)
        }
        .padding(.vertical, 4)
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}
