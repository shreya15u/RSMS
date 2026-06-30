import SwiftUI

struct ASTQueueView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(Router.self) private var router
    @State private var viewModel = ASTQueueViewModel()
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppColors.gold)
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundStyle(AppColors.error)
                        Text(errorMessage)
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(AppColors.secondary)
                            .multilineTextAlignment(.center)
                        
                        CustomOutlineButton(
                            title: "Retry",
                            icon: AnyView(Image(systemName: "arrow.clockwise")),
                            action: { viewModel.fetchQueue() }
                        )
                        .frame(width: 150)
                    }
                    .padding(24)
                } else if viewModel.asts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundStyle(AppColors.tertiary)
                        Text("No After Sales Tickets in queue")
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(AppColors.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(viewModel.asts) { ast in
                                ASTQueueRowView(
                                    ast: ast,
                                    clientName: viewModel.clientNames[ast.clientId ?? UUID()] ?? "Unknown Client",
                                    productName: viewModel.productNames[ast.productId] ?? "Unknown Product"
                                )
                                .onTapGesture {
                                    router.push(BMRoute.astApproval(ast))
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                    }
                }
            }
        }
        .navigationTitle("After Sales Tickets")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            viewModel.fetchQueue()
        }
    }
}

struct ASTQueueRowView: View {
    let ast: AST
    let clientName: String
    let productName: String
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(productName)
                    .font(AppFonts.serif(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.text)
                    .lineLimit(1)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Client: \(clientName)")
                    Text("Advisor: \(ast.metadata?.createdBy ?? "Unknown")")
                }
                .font(AppFonts.sansSerif(size: 12))
                .foregroundStyle(AppColors.secondary)
            }
            
            Spacer()
            
            let badgeStatus: BadgeStatus = {
                switch ast.status.lowercased() {
                case "open": return .warning
                case "approved": return .success
                case "rejected": return .error
                default: return .neutral
                }
            }()
                              
            StatusBadge(text: LocalizedStringKey(ast.status.capitalized), status: badgeStatus)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.tertiary)
                .padding(.leading, 8)
        }
        .padding(18)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.gold15, lineWidth: 0.5)
        )
    }
}
