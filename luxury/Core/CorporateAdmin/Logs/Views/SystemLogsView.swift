//
//  SystemLogsView.swift
//  luxury
//
//  Created by Aditya Chauhan on 18/05/26.
//

import SwiftUI

struct SystemLogsView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(Router.self) private var router
    @State private var viewModel = SystemLogsViewModel()
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: viewModel.selectedCategory == nil) {
                                withAnimation { viewModel.selectedCategory = nil }
                            }
                            
                            ForEach(LogCategory.allCases, id: \.self) { category in
                                FilterChip(label: LocalizedStringKey(category.rawValue), isSelected: viewModel.selectedCategory == category) {
                                    withAnimation { viewModel.selectedCategory = category }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    ScrollView(showsIndicators: false) {
                        if viewModel.isLoading {
                            ProgressView().tint(AppColors.gold).padding(.top, 40)
                        } else if let error = viewModel.errorMessage {
                            Text(error)
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.error)
                                .padding(40)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, minHeight: 200)
                        } else if viewModel.filteredLogs.isEmpty {
                            Text("No logs found for this category.")
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.secondary)
                                .padding(.top, 40)
                                .frame(maxWidth: .infinity, minHeight: 200)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(viewModel.filteredLogs) { log in
                                    LogRow(log: log)
                                    if log.id != viewModel.filteredLogs.last?.id {
                                        Divider().background(AppColors.gold15).padding(.leading, 64)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                            .padding(.horizontal, 24)
                            .padding(.bottom, 60)
                        }
                    }
                    .refreshable {
                        viewModel.fetchData()
                    }
                }
                .padding(.top, 20)
            }
        }
        .navigationTitle("System Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            viewModel.fetchData()
        }
    }
}

private struct FilterChip: View {
    let label: LocalizedStringKey
    let isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppFonts.sansSerif(size: 11, weight: isSelected ? .medium : .light))
                .foregroundStyle(isSelected ? AppColors.background : AppColors.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.gold : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : AppColors.gold15, lineWidth: 0.5)
                )
        }
    }
}

private struct LogRow: View {
    let log: SystemLogEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(severityColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: categoryIcon)
                    .font(AppFonts.sansSerif(size: 14))
                    .foregroundStyle(severityColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(LocalizedStringKey(log.category.rawValue)).textCase(.uppercase)
                        .font(AppFonts.sansSerif(size: 9, weight: .bold))
                        .foregroundStyle(severityColor)
                        .kerning(1)
                    Spacer()
                    Text(timeString)
                        .font(AppFonts.sansSerif(size: 10))
                        .foregroundStyle(AppColors.tertiary)
                }
                
                Text(LocalizedStringKey(log.message))
                    .font(AppFonts.sansSerif(size: 13, weight: .light))
                    .foregroundStyle(.white)
                    .lineSpacing(2)
                
                if let boutique = log.boutiqueName {
                    Text(boutique)
                        .font(AppFonts.sansSerif(size: 11))
                        .foregroundStyle(AppColors.gold)
                        .padding(.top, 2)
                }
            }
        }
        .padding(16)
    }
    
    private var severityColor: Color {
        switch log.severity {
        case .critical: return AppColors.error
        case .warning: return AppColors.warning
        case .info: return AppColors.gold
        }
    }
    
    private var categoryIcon: String {
        switch log.category {
        case .security: return "shield.fill"
        case .inventory: return "box.truck.fill"
        case .access: return "key.fill"
        case .system: return "gearshape.fill"
        }
    }
    
    private var timeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: log.timestamp, relativeTo: Date())
    }
}
