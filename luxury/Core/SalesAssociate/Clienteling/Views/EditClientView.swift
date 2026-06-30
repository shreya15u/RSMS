//
//  EditClientView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct EditClientView: View {
    @Environment(\.dismiss) private var dismiss
    let client: Client
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var mobile: String = ""
    @State private var email: String = ""
    @State private var selectedTier: String = ""
    
    @State private var dobDate: Date = Date()
    @State private var hasDobSet: Bool = false
    @State private var maritalStatus: String = "Single"
    @State private var anniversaryDate: Date = Date()
    @State private var hasAnniversarySet: Bool = false
    
    @State private var ringSize: String = ""
    @State private var wristSize: String = ""
    @State private var apparelSize: String = ""
    @State private var shoeSize: String = ""
    
    @State private var marketingConsent: Bool = true
    @State private var dataConsent: Bool = true
    @State private var thirdPartyConsent: Bool = false
    
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    @State private var showDeleteAlert = false
    @State private var clientEntity: ClientEntity? = nil
    
    private let clientService = ClientService()
    
    init(client: Client) {
        self.client = client
        let nameParts = client.name.components(separatedBy: " ")
        _firstName = State(initialValue: nameParts.first ?? "")
        _lastName = State(initialValue: nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : "")
        _selectedTier = State(initialValue: client.tier.rawValue)
        
        let initialSizes = SizePreferenceService.shared.fetchSizePreference(clientId: client.id)
        _ringSize = State(initialValue: initialSizes.ringSize)
        _wristSize = State(initialValue: initialSizes.wristSize)
        _apparelSize = State(initialValue: initialSizes.apparelSize)
        _shoeSize = State(initialValue: initialSizes.shoeSize)
        
        if let clientEmail = client.email, !clientEmail.isEmpty {
            _email = State(initialValue: clientEmail)
        } else {
            let emailPrefix = nameParts.first?.lowercased() ?? "client"
            _email = State(initialValue: "\(emailPrefix)@example.com")
        }
        
        if let clientPhone = client.phone, !clientPhone.isEmpty {
            _mobile = State(initialValue: clientPhone)
        } else {
            _mobile = State(initialValue: "+91 98210 54321")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let dobStr = client.dob, let date = dateFormatter.date(from: dobStr) {
            _dobDate = State(initialValue: date)
            _hasDobSet = State(initialValue: true)
        } else {
            _dobDate = State(initialValue: Date())
            _hasDobSet = State(initialValue: false)
        }
        
        _maritalStatus = State(initialValue: client.maritalStatus ?? "Single")
        
        if let annivStr = client.dateOfAnniversary, let date = dateFormatter.date(from: annivStr) {
            _anniversaryDate = State(initialValue: date)
            _hasAnniversarySet = State(initialValue: true)
        } else {
            _anniversaryDate = State(initialValue: Date())
            _hasAnniversarySet = State(initialValue: false)
        }
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Edit Client")
                            .font(AppFonts.serif(size: 28, weight: .semibold))
                            .foregroundStyle(AppColors.text)
                            .padding(.bottom, 20)
                            .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PERSONAL INFORMATION")
                                .font(AppFonts.sansSerif(size: 10))
                                .foregroundStyle(AppColors.gold)
                                .kerning(2)
                            
                            HStack(spacing: 10) {
                                RSMSField(label: "First Name", placeholder: "e.g. Rahul", text: $firstName)
                                RSMSField(label: "Last Name", placeholder: "e.g. Bajaj", text: $lastName)
                            }
                            
                            RSMSField(label: "Mobile", placeholder: "+91 98XXX XXXXX", text: $mobile)
                            RSMSField(label: "Email", placeholder: "client@email.com", text: $email)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ADDITIONAL PROFILE INFO")
                                .font(AppFonts.sansSerif(size: 10))
                                .foregroundStyle(AppColors.gold)
                                .kerning(2)
                                .padding(.top, 4)
                            
                            RSMSDatePicker(label: "Date of Birth", date: $dobDate, isSet: $hasDobSet)
                            
                            Text("MARITAL STATUS")
                                .font(AppFonts.sansSerif(size: 10))
                                .foregroundStyle(AppColors.gold)
                                .kerning(2)
                                .padding(.top, 4)
                            
                            HStack(spacing: 8) {
                                let statuses = ["Single", "Married", "Other"]
                                ForEach(statuses, id: \.self) { s in
                                    let isSelected = maritalStatus == s
                                    Text(s)
                                        .font(AppFonts.sansSerif(size: 13, weight: isSelected ? .medium : .light))
                                        .foregroundStyle(isSelected ? AppColors.background : AppColors.secondary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                        .background(isSelected ? AppColors.gold : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.clear : AppColors.gold15, lineWidth: 0.5))
                                        .onTapGesture {
                                            withAnimation { maritalStatus = s }
                                        }
                                }
                            }
                            
                            if maritalStatus == "Married" {
                                RSMSDatePicker(label: "Anniversary Date", date: $anniversaryDate, isSet: $hasAnniversarySet)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TIER")
                                .font(AppFonts.sansSerif(size: 10))
                                .foregroundStyle(AppColors.gold)
                                .kerning(2)
                                .padding(.top, 4)
                            
                            HStack(spacing: 8) {
                                let tiers = ["Silver", "Gold", "Platinum"]
                                ForEach(tiers, id: \.self) { t in
                                    let isSelected = selectedTier == t
                                    Text(t)
                                        .font(AppFonts.sansSerif(size: 13, weight: isSelected ? .medium : .light))
                                        .foregroundStyle(isSelected ? AppColors.background : AppColors.secondary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                        .background(isSelected ? AppColors.gold : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.clear : AppColors.gold15, lineWidth: 0.5))
                                        .onTapGesture {
                                            withAnimation { selectedTier = t }
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SIZE PREFERENCES")
                                .font(AppFonts.sansSerif(size: 10))
                                .foregroundStyle(AppColors.gold)
                                .kerning(2)
                                .padding(.top, 4)
                            
                            HStack(spacing: 10) {
                                RSMSField(label: "Ring Size", placeholder: "e.g. 9", text: $ringSize)
                                RSMSField(label: "Wrist Size", placeholder: "e.g. 18.5 cm", text: $wristSize)
                            }
                            
                            HStack(spacing: 10) {
                                RSMSField(label: "Apparel Size", placeholder: "e.g. L", text: $apparelSize)
                                RSMSField(label: "Shoe Size", placeholder: "e.g. 43", text: $shoeSize)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PRIVACY CONSENTS")
                                .font(AppFonts.sansSerif(size: 10))
                                .foregroundStyle(AppColors.gold)
                                .kerning(2)
                            
                            VStack(spacing: 8) {
                                Group {
                                    Toggle(isOn: $marketingConsent) {
                                        Text("Marketing Communications")
                                            .font(AppFonts.sansSerif(size: 13))
                                            .foregroundStyle(AppColors.text)
                                    }
                                    Toggle(isOn: $dataConsent) {
                                        Text("Data Processing & Storage")
                                            .font(AppFonts.sansSerif(size: 13))
                                            .foregroundStyle(AppColors.text)
                                    }
                                    Toggle(isOn: $thirdPartyConsent) {
                                        Text("Third-Party Sharing")
                                            .font(AppFonts.sansSerif(size: 13))
                                            .foregroundStyle(AppColors.text)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.gold15, lineWidth: 0.5))
                                .toggleStyle(LuxuryToggleStyle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)


                    }
                }
                
                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            Text("Delete")
                                .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                .foregroundStyle(AppColors.error)
                                .frame(height: 52)
                                .frame(maxWidth: .infinity)
                                .background(AppColors.error.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.error.opacity(0.3), lineWidth: 1))
                        }
                        
                        CustomButton(title: "Save", isLoading: isLoading, action: { updateClient() })
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .padding(.bottom, 38)
                }
                .background(AppColors.background)
            }
        }
        .alert("Delete Client", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await clientService.deleteClient(id: client.id)
                        NotificationCenter.default.post(name: NSNotification.Name("ClientDeleted"), object: nil, userInfo: ["clientId": client.id])
                        dismiss()
                    } catch {
                        errorMessage = String(localized: "Cannot delete client: \(error.localizedDescription)")
                        showErrorAlert = true
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete \(client.name)? This action cannot be undone.")
        }
        .navigationTitle("Client Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await loadClientData()
        }
        .alert("Error Saving Client", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func loadClientData() async {
        isLoading = true
        do {
            let entity = try await clientService.fetchClient(id: client.id)
            await MainActor.run {
                self.clientEntity = entity
                self.firstName = entity.name.components(separatedBy: " ").first ?? ""
                self.lastName = entity.name.components(separatedBy: " ").dropFirst().joined(separator: " ")
                self.email = entity.email
                self.mobile = entity.phone ?? ""
                self.selectedTier = entity.tier ?? "Standard"
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                if let dobStr = entity.dob, let date = dateFormatter.date(from: dobStr) {
                    self.dobDate = date
                    self.hasDobSet = true
                } else {
                    self.hasDobSet = false
                }
                
                self.maritalStatus = entity.maritalStatus ?? "Single"
                
                if let annivStr = entity.dateOfAnniversary, let date = dateFormatter.date(from: annivStr) {
                    self.anniversaryDate = date
                    self.hasAnniversarySet = true
                } else {
                    self.hasAnniversarySet = false
                }
                
                let localSizes = SizePreferenceService.shared.fetchSizePreference(clientId: client.id)
                self.ringSize = localSizes.ringSize
                self.wristSize = localSizes.wristSize
                self.apparelSize = localSizes.apparelSize
                self.shoeSize = localSizes.shoeSize
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                print("Error loading client from database: \(error)")
            }
        }
    }
    
    private func updateClient() {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMobile = mobile.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedFirst.isEmpty else {
            errorMessage = String(localized: "First name is required.")
            showErrorAlert = true
            return
        }
        
        guard !trimmedEmail.isEmpty else {
            errorMessage = String(localized: "Email is required.")
            showErrorAlert = true
            return
        }
        
        let fullName = trimmedLast.isEmpty ? trimmedFirst : "\(trimmedFirst) \(trimmedLast)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let dobStr = hasDobSet ? dateFormatter.string(from: dobDate) : nil
        let anniversaryStr = (maritalStatus == "Married" && hasAnniversarySet) ? dateFormatter.string(from: anniversaryDate) : nil
        
        let updatedEntity = ClientEntity(
            id: client.id,
            name: fullName,
            email: trimmedEmail,
            phone: trimmedMobile.isEmpty ? nil : trimmedMobile,
            dob: dobStr,
            tier: selectedTier,
            productsPurchased: clientEntity?.productsPurchased ?? [],
            createdAt: clientEntity?.createdAt ?? Date(),
            updatedAt: Date(),
            maritalStatus: maritalStatus,
            dateOfAnniversary: anniversaryStr
        )
        
        // Save size preferences locally
        let newSizes = ClientSizePreference(
            id: client.id,
            ringSize: ringSize,
            wristSize: wristSize,
            apparelSize: apparelSize,
            shoeSize: shoeSize
        )
        SizePreferenceService.shared.saveSizePreference(newSizes, for: client.id)
        
        isLoading = true
        Task {
            do {
                try await clientService.updateClient(updatedEntity)
                await MainActor.run {
                    isLoading = false
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshClients"), object: nil)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

private struct RSMSField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AppFonts.sansSerif(size: 10))
                .foregroundStyle(AppColors.secondary)
                .kerning(0.8)
                .textCase(.uppercase)
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(AppColors.tertiary))
                .font(AppFonts.sansSerif(size: 14))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
        }
    }
}
