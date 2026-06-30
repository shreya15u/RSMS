//
//  NewClientView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct NewClientView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var mobile: String = ""
    @State private var email: String = ""
    @State private var selectedTier: String = "Gold"
    @State private var dobDate: Date = Date()
    @State private var hasDobSet: Bool = false
    @State private var maritalStatus: String = "Single"
    @State private var anniversaryDate: Date = Date()
    @State private var hasAnniversarySet: Bool = false
    
    @State private var marketingConsent = true
    @State private var dataConsent = true
    @State private var thirdPartyConsent = false
    
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    
    private let clientService = ClientService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("New Client")
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
                        .padding(.bottom, 40)
                    }
                }
                
                VStack(spacing: 0) {
                    CustomButton(title: "Create Profile", isLoading: isLoading, action: { saveClient() })
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .padding(.bottom, 38)
                }
                .background(AppColors.background)
            }
        }
        .navigationTitle("Clients")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(AppFonts.sansSerif(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.gold)
                }
            }
        }
        }
        .alert("Error Saving Client", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func saveClient() {
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
        
        let clientEntity = ClientEntity(
            id: UUID(),
            name: fullName,
            email: trimmedEmail,
            phone: trimmedMobile.isEmpty ? nil : trimmedMobile,
            dob: dobStr,
            tier: selectedTier,
            productsPurchased: [],
            createdAt: Date(),
            updatedAt: Date(),
            maritalStatus: maritalStatus,
            dateOfAnniversary: anniversaryStr
        )
        
        isLoading = true
        Task {
            do {
                try await clientService.createClient(clientEntity)
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

