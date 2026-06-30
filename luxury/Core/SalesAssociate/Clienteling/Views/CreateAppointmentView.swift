//
//  CreateAppointmentView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI
import Supabase
import Auth

struct CreateAppointmentView: View {
    @Environment(\.dismiss) private var dismiss
    var client: Client? = nil
    
    @State private var viewModel = ClientelingViewModel()
    @State private var selectedClient: Client? = nil
    @State private var selectedDate = Date()
    @State private var selectedTime = "10:00 AM"
    @State private var selectedType: AppointmentType = .inStore
    @State private var remarks: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    
    let times = ["10:00 AM", "11:30 AM", "01:00 PM", "02:30 PM", "04:00 PM", "05:30 PM"]
    let types = AppointmentType.allCases
    
    var availableTimes: [String] {
        if Calendar.current.isDateInToday(selectedDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "hh:mm a"
            let nowStr = formatter.string(from: Date())
            guard let nowTime = formatter.date(from: nowStr) else { return times }
            
            let futureTimes = times.filter { timeStr in
                if let t = formatter.date(from: timeStr) {
                    return t > nowTime
                }
                return true
            }
            return futureTimes
        }
        return times
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        Text("New Appointment")
                            .font(AppFonts.serif(size: 28, weight: .semibold))
                            .foregroundStyle(AppColors.text)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CLIENT")
                                .font(AppFonts.sansSerif(size: 10))
                                .foregroundStyle(AppColors.gold)
                                .kerning(2)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(AppColors.tertiary)
                                if let selected = selectedClient {
                                    Text(selected.name)
                                        .font(AppFonts.sansSerif(size: 14))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if self.client == nil {
                                        Button(action: { selectedClient = nil }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(AppColors.secondary)
                                        }
                                    }
                                } else {
                                    Menu {
                                        if viewModel.isLoading {
                                            Text("Loading clients...")
                                        } else {
                                            ForEach(viewModel.clients) { c in
                                                Button(c.name) {
                                                    selectedClient = c
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text("Select a client...")
                                                .font(AppFonts.sansSerif(size: 14))
                                                .foregroundStyle(AppColors.secondary)
                                            Spacer()
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundStyle(AppColors.gold)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DATE & TIME")
                                .font(AppFonts.sansSerif(size: 10))
                                .foregroundStyle(AppColors.gold)
                                .kerning(2)
                            
                            RSMSCalendarView(selectedDate: $selectedDate, disablePastDates: true)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(availableTimes, id: \.self) { time in
                                        let isSelected = selectedTime == time
                                        Text(time)
                                            .font(AppFonts.sansSerif(size: 12, weight: isSelected ? .medium : .light))
                                            .foregroundStyle(isSelected ? AppColors.background : AppColors.secondary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(isSelected ? AppColors.gold : AppColors.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.clear : AppColors.gold15, lineWidth: 0.5))
                                            .onTapGesture { selectedTime = time }
                                    }
                                }
                            }
                            .onChange(of: availableTimes) { _, newTimes in
                                if !newTimes.contains(selectedTime) {
                                    selectedTime = newTimes.first ?? "10:00 AM"
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CONSULTATION TYPE")
                                .font(AppFonts.sansSerif(size: 10))
                                .foregroundStyle(AppColors.gold)
                                .kerning(2)
                            
                            VStack(spacing: 1) {
                                ForEach(types, id: \.self) { type in
                                    let isSelected = selectedType == type
                                    HStack {
                                        Text(type.displayName)
                                            .font(AppFonts.sansSerif(size: 14))
                                            .foregroundStyle(isSelected ? AppColors.gold : AppColors.text)
                                        Spacer()
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(AppColors.gold)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .frame(height: 52)
                                    .background(AppColors.surface)
                                    .onTapGesture { selectedType = type }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("REMARKS (OPTIONAL)")
                                .font(AppFonts.sansSerif(size: 10))
                                .foregroundStyle(AppColors.gold)
                                .kerning(2)
                            
                            HStack {
                                TextField("Any special requests or notes...", text: $remarks)
                                    .font(AppFonts.sansSerif(size: 14))
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 60)
                    }
                }
                
                VStack(spacing: 0) {
                    if let error = errorMessage {
                        Text(error)
                            .font(AppFonts.sansSerif(size: 12))
                            .foregroundStyle(AppColors.error)
                            .padding(.bottom, 8)
                    }
                    
                    let isDisabled = selectedClient == nil || isSaving
                    
                    Button(action: {
                        Task { await saveAppointment() }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isDisabled ? AppColors.gold.opacity(0.5) : AppColors.gold)
                                .frame(height: 52)
                            
                            if isSaving {
                                ProgressView()
                                    .tint(AppColors.background)
                            } else {
                                Text("Confirm Appointment")
                                    .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                    .foregroundStyle(AppColors.background)
                            }
                        }
                    }
                    .disabled(isDisabled)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .background(AppColors.background)
            }
            .task {
                selectedClient = client
                if client == nil {
                    await viewModel.loadClients()
                }
            }
            .navigationTitle("Appointments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(AppFonts.sansSerif(size: 16, weight: .medium))
                            .foregroundStyle(AppColors.gold)
                    }
                }
            }
            }
        }
    }
    
    private func saveAppointment() async {
        isSaving = true
        errorMessage = nil
        
        do {
            let clientDb = SupabaseManager.shared.client
            guard let _ = try? await clientDb.auth.session else {
                throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "No session"])
            }
            
            let profileService = ProfileService()
            guard let (_, staffAny) = try await profileService.fetchCurrentProfile(),
                  let staff = staffAny as? StaffModel else {
                throw NSError(domain: "Auth", code: 403, userInfo: [NSLocalizedDescriptionKey: "Staff profile not found"])
            }
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            let timeDate = timeFormatter.date(from: selectedTime) ?? Date()
            
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: timeDate)
            let minute = calendar.component(.minute, from: timeDate)
            
            guard let combinedDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: selectedDate) else {
                throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid date/time combination"])
            }
            
            let isoFormatter = ISO8601DateFormatter()
            let timestampStr = isoFormatter.string(from: combinedDate)
            
            // Conflict Check
            let existingAppointments: [AppointmentEntity] = try await clientDb.from("appointment")
                .select()
                .eq("created_by", value: staff.id)
                .eq("timestamp", value: timestampStr)
                .execute()
                .value
            
            if !existingAppointments.isEmpty {
                throw NSError(domain: "Appointment", code: 409, userInfo: [NSLocalizedDescriptionKey: "You already have an appointment scheduled for this time"])
            }
            
            guard let boutiqueId = staff.boutiqueId else {
                throw NSError(domain: "Auth", code: 403, userInfo: [NSLocalizedDescriptionKey: "Staff does not have an assigned boutique"])
            }
            
            let appointment = AppointmentEntity(
                id: UUID(),
                clientId: selectedClient?.id,
                boutiqueId: boutiqueId,
                timestamp: timestampStr,
                appointmentType: selectedType,
                assignedTo: staff.id,
                createdBy: staff.id,
                status: .pending,
                createdAt: nil,
                remarks: remarks.isEmpty ? nil : remarks
            )
            
            try await clientDb.from("appointment").insert(appointment).execute()
            
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
        
        await MainActor.run {
            isSaving = false
        }
    }
}
