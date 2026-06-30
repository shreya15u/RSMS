//
//  SalesAnalyticsViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation
import Supabase

@Observable
final class SalesAnalyticsViewModel {
    var todaySales: String = "\(CurrencyManager.shared.symbol)0"
    var todayTarget: String = "\(CurrencyManager.shared.symbol)0"
    var wtdSales: String = "\(CurrencyManager.shared.symbol)0"
    var mtdSales: String = "\(CurrencyManager.shared.symbol)0"
    
    var categories: [SalesCategory] = []
    var isLoading = false
    
    func fetchData() async {
        await MainActor.run { isLoading = true }
            guard let profileTuple = try? await ProfileService().fetchCurrentProfile() else {
                await MainActor.run { isLoading = false }
                return
            }
            
            let bId: UUID?
            var staffTarget: Double? = nil
            
            if let staff = profileTuple.1 as? StaffModel, let boutiqueId = staff.boutiqueId {
                bId = boutiqueId
                staffTarget = staff.dailySalesTarget
            } else if let boutique = profileTuple.1 as? CorporateBoutique {
                bId = boutique.id
                // Boutique managers might not have personal daily sales targets, they use the boutique's target
            } else if profileTuple.0 == .corporateAdmin {
                bId = nil
            } else {
                await MainActor.run { isLoading = false }
                return
            }
            
            // 1. Fetch all transactions for this boutique
            var txQuery = SupabaseManager.shared.client.from("transaction").select()
            if let boutiqueId = bId {
                txQuery = txQuery.eq("boutique_id", value: boutiqueId)
            }
            let txs: [SATransactionEntity] = (try? await txQuery.execute().value) ?? []
                
            // 2. Fetch boutique daily target
            struct BoutiqueTarget: Codable {
                let dailySalesTarget: Double?
                enum CodingKeys: String, CodingKey {
                    case dailySalesTarget = "daily_sales_target"
                }
            }
            
            var targetQuery = SupabaseManager.shared.client.from("boutiques").select("daily_sales_target")
            if let boutiqueId = bId {
                targetQuery = targetQuery.eq("id", value: boutiqueId)
            }
            
            let boutiqueTargets: [BoutiqueTarget] = (try? await targetQuery.execute().value) ?? []
            let bTarget = boutiqueTargets.compactMap { $0.dailySalesTarget }.reduce(0, +)

                
            // 3. Calculate time-based revenue (Today, WTD, MTD)
            let now = Date()
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            
            let startOfToday = calendar.startOfDay(for: now)
            
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            components.weekday = calendar.firstWeekday
            let startOfWeek = calendar.date(from: components) ?? startOfToday
            
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? startOfToday
            
            var tSales = 0.0
            var wSales = 0.0
            var mSales = 0.0
            
            for tx in txs {
                guard let d = tx.dateOfTransaction else { continue }
                if d >= startOfToday {
                    tSales += tx.transactionAmount
                }
                if d >= startOfWeek {
                    wSales += tx.transactionAmount
                }
                if d >= startOfMonth {
                    mSales += tx.transactionAmount
                }
            }
            
            // 4. Fetch purchased_items for this boutique to get category-level breakdown
            struct PurchasedItemMin: Codable {
                let productId: UUID
                enum CodingKeys: String, CodingKey {
                    case productId = "product_id"
                }
            }
            
            var purchasedQuery = SupabaseManager.shared.client.from("purchased_items").select("product_id")
            if let boutiqueId = bId {
                purchasedQuery = purchasedQuery.eq("boutique_id", value: boutiqueId)
            }
            
            let purchasedItems: [PurchasedItemMin] = (try? await purchasedQuery.execute().value) ?? []
            
            // 5. Fetch catalogs to map product_id -> category + amount
            let catalogs: [CatalogEntity] = (try? await SupabaseManager.shared.client
                .from("catalogs")
                .select()
                .execute()
                .value) ?? []
            let catalogDict = Dictionary(uniqueKeysWithValues: catalogs.map { ($0.id, $0) })
            
            // 6. Calculate revenue per category from purchased items
            var categoryRevenue: [String: Double] = [:]
            for item in purchasedItems {
                if let catalog = catalogDict[item.productId] {
                    let catName = catalog.category.rawValue
                    categoryRevenue[catName, default: 0] += catalog.amount
                }
            }
            
            // 7. Build category list sorted by revenue (descending)
            let totalCatRevenue = categoryRevenue.values.reduce(0, +)
            var newCategories: [SalesCategory] = []
            
            if totalCatRevenue > 0 {
                // Real data from purchased_items
                let sorted = categoryRevenue.sorted { $0.value > $1.value }
                for (name, revenue) in sorted {
                    let pct = revenue / totalCatRevenue
                    newCategories.append(SalesCategory(
                        name: name,
                        revenue: CurrencyManager.shared.format(amount: revenue),
                        percentage: pct
                    ))
                }
            } else {
                // Fallback: use all CatalogCategory cases with zero
                for cat in CatalogCategory.allCases {
                    newCategories.append(SalesCategory(
                        name: cat.rawValue,
                        revenue: CurrencyManager.shared.format(amount: 0),
                        percentage: 0
                    ))
                }
            }
            
            await MainActor.run {
                self.todaySales = CurrencyManager.shared.format(amount: tSales)
                self.wtdSales = CurrencyManager.shared.format(amount: wSales)
                self.mtdSales = CurrencyManager.shared.format(amount: mSales)
                self.todayTarget = CurrencyManager.shared.format(amount: staffTarget ?? bTarget)
                self.categories = newCategories
                self.isLoading = false
            }
    }
}
