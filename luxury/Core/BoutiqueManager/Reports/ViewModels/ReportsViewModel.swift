//
//  ReportsViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation

@Observable
final class ReportsViewModel {
    var reportCategories: [ReportItem] = [
        ReportItem(title: "Sales Analytics", subtitle: "Target vs Actual, Daily Trends", icon: "chart.xyaxis.line"),
        ReportItem(title: "Inventory", subtitle: "Total Value, Variance Trends, Write-offs", icon: "archivebox"),
        ReportItem(title: "Client Insights", subtitle: "LTV, Tiers, Wishlist Conversions", icon: "person.2.badge.gearshape")
    ]
}
