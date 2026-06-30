//
//  DiscountApprovalViewModel.swift
//  luxury
//
//  Created by Kaushiki Rai on 22/05/26.
//

import Foundation
import Observation

@Observable
final class DiscountApprovalViewModel {

    var requests: [DiscountRequest] = [
        DiscountRequest(client: "Meera Kapoor",    total: "\(CurrencyManager.shared.symbol)2,45,000", discount: (0.15).formatted(.percent.precision(.fractionLength(0))), advisor: "Rahul Sharma",  time: "2 min ago"),
        DiscountRequest(client: "Vikram Malhotra", total: "\(CurrencyManager.shared.symbol)85,000",   discount: (0.12).formatted(.percent.precision(.fractionLength(0))), advisor: "Anjali Pathak", time: "10 min ago"),
        DiscountRequest(client: "Sarah John",      total: "\(CurrencyManager.shared.symbol)1,20,000", discount: (0.20).formatted(.percent.precision(.fractionLength(0))), advisor: "Rahul Sharma",  time: "15 min ago")
    ]

    func approve(_ request: DiscountRequest) {
        requests.removeAll { $0.id == request.id }
    }

    func reject(_ request: DiscountRequest) {
        requests.removeAll { $0.id == request.id }
    }
}
