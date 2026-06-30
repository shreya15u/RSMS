import SwiftUI

struct ClientSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var clients: [StoreClient] = []
    @State private var isLoading = true
    @State private var searchText = ""
    
    var filteredClients: [StoreClient] {
        if searchText.isEmpty {
            return clients
        } else {
            return clients.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.email.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var onSelect: (StoreClient) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                Group {
                    if isLoading {
                        ProgressView("Loading clients...")
                            .tint(AppColors.gold)
                            .foregroundStyle(AppColors.secondary)
                    } else if clients.isEmpty {
                        Text("No clients found.")
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(AppColors.secondary)
                    } else if filteredClients.isEmpty {
                        Text("No matching clients.")
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(AppColors.secondary)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredClients) { client in
                                    Button(action: {
                                        onSelect(client)
                                        dismiss()
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(client.name)
                                                    .font(AppFonts.serif(size: 16, weight: .semibold))
                                                    .foregroundStyle(.white)
                                                Text(client.email)
                                                    .font(AppFonts.sansSerif(size: 12))
                                                    .foregroundStyle(AppColors.secondary)
                                            }
                                            Spacer()
                                            if let tier = client.tier {
                                                StatusBadge(text: LocalizedStringKey(tier), status: .success)
                                            }
                                        }
                                        .padding()
                                        .background(AppColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                        }
                    }
                }
            }
            .navigationTitle("Select Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search clients")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColors.gold)
                }
            }
            .task {
                do {
                    let fetchedClients = try await ClientService().fetchClients()
                    let formatter = ISO8601DateFormatter()
                    self.clients = fetchedClients.map { entity in
                        StoreClient(
                            id: entity.id,
                            name: entity.name,
                            email: entity.email,
                            phone: entity.phone,
                            dob: entity.dob.flatMap { formatter.date(from: $0) },
                            tier: entity.tier,
                            productsPurchased: entity.productsPurchased,
                            createdAt: entity.createdAt,
                            updatedAt: entity.updatedAt
                        )
                    }
                    self.isLoading = false
                } catch {
                    print("Error fetching clients: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
}
