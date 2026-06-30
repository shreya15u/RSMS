//
//  AuditSignoffViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation

@Observable
final class AuditSignoffViewModel {
    var variances: [RSMSVarianceItem] = [
        RSMSVarianceItem(name: "Diamond Ring 18K Gold", expected: 5, actual: 4, reason: "Missing / Under Investigation"),
        RSMSVarianceItem(name: "Silk Scarf (Print A)", expected: 10, actual: 12, reason: "Found Elsewhere (Zone B)"),
        RSMSVarianceItem(name: "Men's Wallet Brown", expected: 8, actual: 7, reason: "Damaged / Scrapped")
    ]
    
    var netVariance: String = "-1"
    var accuracy: String = (0.982).formatted(.percent.precision(.fractionLength(1)))
}
