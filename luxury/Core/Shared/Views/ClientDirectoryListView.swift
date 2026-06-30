import SwiftUI

struct ClientDirectoryListView: View {
    let onClientTap: (Client) -> Void
    
    @State private var viewModel = ClientelingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header & Custom Search
                VStack(spacing: 16) {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "arrow.left")
                                .font(AppFonts.sansSerif(size: 20))
                                .foregroundStyle(.white)
                        }
                        .padding(.trailing, 8)
                        
                        Text("Client Directory")
                            .font(AppFonts.serif(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.secondary)
                            .font(.system(size: 16, weight: .medium))
                        
                        TextField("Search Clients", text: $viewModel.searchText)
                            .font(AppFonts.sansSerif(size: 16))
                            .foregroundStyle(.white)
                            .tint(AppColors.gold)
                        
                        if !viewModel.searchText.isEmpty {
                            Button(action: { viewModel.searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppColors.secondary)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                }
                .background(AppColors.background)
                
                if viewModel.isLoading && viewModel.clients.isEmpty {
                    Spacer()
                    ProgressView().tint(AppColors.gold)
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    Text(error).font(AppFonts.sansSerif(size: 14)).foregroundStyle(AppColors.error).padding(40)
                    Spacer()
                } else if viewModel.filteredClients.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.3.fill")
                            .font(AppFonts.sansSerif(size: 40))
                            .foregroundStyle(AppColors.tertiary)
                        Text(viewModel.searchText.isEmpty ? "No clients found" : "No clients match '\(viewModel.searchText)'")
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(AppColors.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.filteredClients, id: \.id) { client in
                                Button(action: {
                                    onClientTap(client)
                                }) {
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(client.name)
                                                .font(AppFonts.serif(size: 18, weight: .medium))
                                                .foregroundStyle(AppColors.text)
                                            Text(client.email ?? "No Email")
                                                .font(AppFonts.sansSerif(size: 12))
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                        Spacer()
                                        
                                        StatusBadge(text: LocalizedStringKey(client.tier.rawValue), status: client.tier.badgeStatus)
                                        
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
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadClients()
        }
        .refreshable {
            await viewModel.loadClients()
        }
    }
}
