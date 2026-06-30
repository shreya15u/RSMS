import SwiftUI

struct CreateASTView: View {
    @State private var viewModel = ASTViewModel()
    let client: StoreClient
    let boutiqueId: UUID
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Client Information")) {
                    Text("Name: \(client.name)")
                    Text("Email: \(client.email)")
                }
                
                Section(header: Text("Select Product")) {
                    if viewModel.isLoading {
                        ProgressView("Loading purchased items...")
                    } else if viewModel.purchasedItems.isEmpty {
                        Text("No purchased items found for this client.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Product", selection: $viewModel.selectedProductId) {
                            Text("Select a Product").tag(UUID?.none)
                            ForEach(viewModel.purchasedItems) { item in
                                Text(item.productId.uuidString).tag(item.productId as UUID?)
                            }
                        }
                    }
                }
                
                Section(header: Text("Ticket Details")) {
                    Picker("Warranty Status", selection: $viewModel.warrantyStatus) {
                        Text("Valid").tag("valid")
                        Text("Expired").tag("expired")
                        Text("Unknown").tag("unknown")
                    }
                    
                    TextField("Description of Issue", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    TextField("Internal Remarks", text: $viewModel.remark, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(AppColors.error)
                    }
                }
                
                if let successMessage = viewModel.successMessage {
                    Section {
                        Text(successMessage)
                            .foregroundStyle(AppColors.success)
                    }
                }
            }
            .navigationTitle("New Service Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        viewModel.submitAST(boutiqueId: boutiqueId)
                    }
                    .disabled(viewModel.selectedProductId == nil || viewModel.isLoading)
                }
            }
            .onAppear {
                viewModel.fetchPurchasedItems(for: client)
            }
        }
    }
}
