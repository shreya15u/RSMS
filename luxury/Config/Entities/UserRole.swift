//
//  UserRole.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation

enum UserRole: String, Codable {
    case salesAssociate = "Sales Associate"
    case boutiqueManager = "Boutique Manager"
    case inventoryController = "Inventory Controller"
    case corporateAdmin = "Corporate Admin"
}
