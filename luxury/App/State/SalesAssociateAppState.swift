//
//  SalesAssociateAppState.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation

@Observable
final class SalesAssociateAppState: @unchecked Sendable {
    @MainActor static let shared = SalesAssociateAppState()
    var selectedTab: SATab = .clients
}
