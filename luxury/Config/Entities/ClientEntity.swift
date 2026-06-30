//
//  ClientEntity.swift
//  luxury
//
//  Created by Nalinish Ranjan on 21/05/26.
//

import Foundation

struct ClientEntity: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    var name: String
    var email: String
    var phone: String?
    var dob: String?
    var tier: String?
    var productsPurchased: [UUID]?
    let createdAt: Date
    var updatedAt: Date
    var maritalStatus: String?
    var dateOfAnniversary: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, dob, tier
        case productsPurchased = "products_purchased"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case maritalStatus = "marital_status"
        case dateOfAnniversary = "date_of_anniversary"
    }
}

extension ClientEntity {
    func toUIModel() -> Client {
        let parsedTier: ClientTier
        switch (self.tier ?? "").lowercased() {
        case "platinum": parsedTier = .platinum
        case "gold": parsedTier = .gold
        case "silver": parsedTier = .silver
        default: parsedTier = .silver
        }
        
        return Client(
            id: self.id,
            name: self.name,
            tier: parsedTier,
            lastVisit: "Unknown", // Can be dynamically calculated or fetched separately
            ltv: 0.0, // Should ideally be calculated from transactions
            initial: String(self.name.prefix(1)),
            phone: self.phone,
            email: self.email,
            dob: self.dob,
            maritalStatus: self.maritalStatus,
            dateOfAnniversary: self.dateOfAnniversary,
            createdAt: self.createdAt
        )
    }
}
