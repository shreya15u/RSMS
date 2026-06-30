//
//  EditBoutiqueViewModel.swift
//  luxury
//

import SwiftUI
import Observation
import Supabase

@Observable
final class EditBoutiqueViewModel {
    var name: String = ""
    var address: String = ""
    var city: String = ""
    var pinCode: String = ""
    
    var isLoading = false
    var errorMessage: String?
    
    private let client = SupabaseManager.shared.client
    let boutiqueId: UUID
    
    init(boutique: CorporateBoutique) {
        self.boutiqueId = boutique.id
        self.name = boutique.name
        self.address = boutique.address
        self.city = boutique.city
        self.pinCode = boutique.pinCode
    }
    
    init(boutiqueId: UUID, name: String, address: String, city: String, pinCode: String) {
        self.boutiqueId = boutiqueId
        self.name = name
        self.address = address
        self.city = city
        self.pinCode = pinCode
    }
    
    func saveChanges(onSuccess: @escaping () -> Void) {
        guard !name.isEmpty, !address.isEmpty, !city.isEmpty, !pinCode.isEmpty else {
            errorMessage = String(localized: "Please fill in all fields")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                struct UpdateData: Encodable {
                    let name: String
                    let address: String
                    let city: String
                    let pin_code: String
                }
                
                let data = UpdateData(name: name, address: address, city: city, pin_code: pinCode)
                
                try await client.from("boutiques")
                    .update(data)
                    .eq("id", value: boutiqueId)
                    .execute()
                
                await MainActor.run {
                    self.isLoading = false
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(localized: "Failed to update boutique: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
}
