//
//  TransferPersistence.swift
//  luxury
//
//  Created by Nalinish Ranjan on 27/05/26.
//

import Foundation

final class TransferPersistence {
    static let shared = TransferPersistence()
    
    private let key = "rsms_stock_transfers"
    
    private init() {}
    
    func loadTransfers() -> [TransferRequest] {
        if let data = UserDefaults.standard.data(forKey: key),
           let list = try? JSONDecoder().decode([TransferRequest].self, from: data) {
            return list
        }
        return []
    }
    
    func saveTransfer(_ transfer: TransferRequest) {
        var current = loadTransfers()
        current.insert(transfer, at: 0)
        saveAll(current)
    }
    
    func saveAll(_ list: [TransferRequest]) {
        do {
            let data = try JSONEncoder().encode(list)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Error encoding transfer requests: \(error)")
        }
    }
}
