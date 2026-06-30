import SwiftUI

struct WishlistCatalogView: View {
    let viewModel: ClientDetailViewModel
    @Binding var isPresented: Bool
    
    @State private var searchVM = SellingViewModel()
    
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar & Filter Section
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(AppColors.tertiary)
                            
                            TextField("Search by name, brand, or SKU...", text: $searchVM.searchText)
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.text)
                                .textFieldStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                        
                        // Category pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                categoryChip(title: "All", active: searchVM.selectedCategory == nil) {
                                    searchVM.selectedCategory = nil
                                }
                                
                                ForEach(searchVM.categories, id: \.self) { cat in
                                    categoryChip(title: cat.rawValue, active: searchVM.selectedCategory == cat) {
                                        searchVM.selectedCategory = cat
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .padding(.top, 16)
                
                // Product Grid or Empty/Loading State
                if searchVM.isLoading {
                    Spacer()
                    ProgressView("Loading catalogs...")
                        .tint(AppColors.gold)
                        .foregroundStyle(AppColors.secondary)
                    Spacer()
                } else if searchVM.filteredCatalogs.isEmpty {
                    Spacer()
                    Text("No products found")
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(AppColors.secondary)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                            spacing: 16
                        ) {
                            ForEach(searchVM.filteredCatalogs) { product in
                                WishlistGridCard(catalog: product) {
                                    Task {
                                        do {
                                            try await viewModel.addProductToWishlist(
                                                productId: product.id,
                                                brand: product.brand,
                                                name: product.name,
                                                price: product.amount
                                            )
                                            showToastMessage("Added \(product.name) to wishlist")
                                        } catch {
                                            print("Wishlist Catalog Add Error: \(error)")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            
            // Toast notification overlay
            if showToast {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                        Text(toastMessage)
                            .font(AppFonts.sansSerif(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppColors.success.opacity(0.95))
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 30)
                }
                .animation(.spring(), value: showToast)
            }
        }
        .navigationTitle("Add to Wishlist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundStyle(AppColors.gold)
            }
        }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            searchVM.fetchData()
        }
    }
    
    private func categoryChip(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Text(title)
            .font(AppFonts.sansSerif(size: 11, weight: active ? .medium : .light))
            .foregroundStyle(active ? AppColors.background : AppColors.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(active ? AppColors.gold : Color.clear)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(active ? Color.clear : AppColors.gold15, lineWidth: 0.5))
            .onTapGesture {
                withAnimation { action() }
            }
    }
    
    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}

private struct WishlistGridCard: View {
    let catalog: CatalogEntity
    let onAdd: () -> Void

    private let imageHeight: CGFloat = 120
    private let textHeight:  CGFloat = 120

    private var firstURL: URL? {
        catalog.productImages?.first.flatMap { URL(string: $0) }
    }

    private var inStock: Bool {
        true // Assume true for now to display button
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    AppColors.surface2
                    if let url = firstURL {
                        CachedAsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: w, height: imageHeight)
                                    .clipped()
                            case .empty:
                                ProgressView().tint(AppColors.gold)
                            default:
                                Image(systemName: "photo")
                                    .font(AppFonts.sansSerif(size: 28))
                                    .foregroundStyle(AppColors.gold.opacity(0.35))
                            }
                        }
                    } else {
                        Image(systemName: "photo")
                            .font(AppFonts.sansSerif(size: 28))
                            .foregroundStyle(AppColors.gold.opacity(0.35))
                    }
                }
                .frame(width: w, height: imageHeight)
                .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text(catalog.brand.uppercased())
                        .font(AppFonts.sansSerif(size: 9, weight: .bold))
                        .foregroundStyle(AppColors.gold)
                        .kerning(1.5)
                        .lineLimit(1)
                        .frame(height: 12)
                    
                    Text(catalog.name)
                        .font(AppFonts.serif(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .frame(height: 16)
                    
                    HStack {
                        Text(catalog.formattedPrice)
                            .font(AppFonts.sansSerif(size: 12, weight: .semibold))
                            .foregroundStyle(AppColors.gold)
                            .lineLimit(1)
                            .frame(height: 16)
                        
                        Spacer()
                        
                        HStack(spacing: 3) {
                            Circle()
                                .fill(inStock ? AppColors.success : AppColors.error)
                                .frame(width: 5, height: 5)
                            Text(inStock ? "In Stock" : "Out")
                                .font(AppFonts.sansSerif(size: 8))
                                .foregroundStyle(inStock ? AppColors.success : AppColors.error)
                                .lineLimit(1)
                        }
                        .frame(height: 16)
                    }
                    .frame(height: 16)
                    
                    Spacer(minLength: 0)
                    
                    Button(action: onAdd) {
                        Text("Add to Wishlist")
                            .font(AppFonts.sansSerif(size: 11, weight: .bold))
                            .foregroundStyle(AppColors.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(AppColors.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .frame(width: w, height: textHeight, alignment: .topLeading)
            }
            .frame(width: w, height: imageHeight + textHeight)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
        }
        .frame(height: imageHeight + textHeight)
    }
}
