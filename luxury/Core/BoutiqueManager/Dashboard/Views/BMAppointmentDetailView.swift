//
//  BMAppointmentDetailView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI
import Supabase
import PostgREST

struct BMAppointmentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let appointment: AppointmentEntity
    
    @State private var availableStaff: [StaffModel] = []
    @State private var selectedStaffId: UUID?
    @State private var isSaving = false
    @State private var showingDeleteAlert = false
    @State private var currentStatus: AppointmentStatus
    @State private var selectedDate: Date
    @State private var showingCalendarAlert = false
    @State private var calendarAlertMessage = ""
    
    init(appointment: AppointmentEntity) {
        self.appointment = appointment
        _selectedStaffId = State(initialValue: appointment.assignedTo)
        _currentStatus = State(initialValue: appointment.status)
        
        let initialDate = ISO8601DateFormatter().date(from: appointment.timestamp) ?? Date()
        _selectedDate = State(initialValue: initialDate)
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {

                CustomHeader(title: "Appointment Details", showBackButton: true, backAction: { dismiss() }, isInline: true)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {

                        VStack(alignment: .leading, spacing: 20) {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppColors.gold08)
                                        .frame(width: 50, height: 50)
                                    let clientInitial = appointment.client?.name.prefix(1).uppercased() ?? "U"
                                    Text(clientInitial)
                                        .font(AppFonts.serif(size: 20, weight: .bold))
                                        .foregroundStyle(AppColors.gold)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    let clientName = appointment.client?.name ?? "Unknown Client"
                                    Text(clientName)
                                        .font(AppFonts.serif(size: 22, weight: .medium))
                                        .foregroundStyle(AppColors.text)
                                    Text(appointment.displayAppointmentType)
                                        .font(AppFonts.sansSerif(size: 13))
                                        .foregroundStyle(AppColors.secondary)
                                }
                            }

                            Divider().background(AppColors.gold15)

                            VStack(alignment: .leading, spacing: 16) {
                                DetailRow(label: "STATUS",  value: currentStatus.rawValue.capitalized, icon: "circle.fill")
                                DetailRow(label: "TIME",    value: appointment.formattedTime,        icon: "clock")
                                DetailRow(label: "ADVISOR", value: advisorName(for: selectedStaffId), icon: "person.fill")
                                DetailRow(label: "CREATED BY", value: advisorName(for: appointment.createdBy), icon: "person.text.rectangle.fill")
                                DetailRow(label: "STORE",   value: "Maison Mumbai",         icon: "building.2.fill")
                            }
                        }
                        .padding(24)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                        .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 16) {
                            Text("CHANGE DATE & TIME")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)

                            DatePicker("Date & Time", selection: $selectedDate)
                                .datePickerStyle(.compact)
                                .tint(AppColors.gold)
                                .font(AppFonts.sansSerif(size: 14))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                .padding(.horizontal, 24)
                        }
                        VStack(alignment: .leading, spacing: 16) {
                            Text("REASSIGN ADVISOR")
                                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.secondary)
                                .kerning(1.5)
                                .padding(.horizontal, 24)

                            Menu {
                                ForEach(availableStaff) { staff in
                                    Button(staff.name) {
                                        selectedStaffId = staff.id
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedStaffId == nil ? "Select new advisor..." : advisorName(for: selectedStaffId))
                                        .font(AppFonts.sansSerif(size: 14))
                                        .foregroundStyle(selectedStaffId == nil ? AppColors.tertiary : AppColors.text)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(AppColors.gold)
                                }
                                .padding(.horizontal, 20)
                                .frame(height: 52)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.top, 8)
                    
                    Button(action: {
                        Task {
                            let granted = await EventKitManager.shared.requestAccess()
                            if granted {
                                let title = "RSMS: \(appointment.displayAppointmentType)"
                                let date = ISO8601DateFormatter().date(from: appointment.timestamp) ?? Date()
                                let notes = appointment.remarks ?? ""
                                EventKitManager.shared.addEventToCalendar(title: title, startDate: date, durationMinutes: 60, notes: notes)
                                
                                await MainActor.run {
                                    calendarAlertMessage = "Appointment added to your iOS Calendar!"
                                    showingCalendarAlert = true
                                }
                            } else {
                                await MainActor.run {
                                    calendarAlertMessage = "Permission denied. Please enable Calendar access in iOS Settings."
                                    showingCalendarAlert = true
                                }
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Add to Apple Calendar")
                        }
                        .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }

                VStack {
                    HStack(spacing: 16) {
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.error, lineWidth: 1)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.surface))
                                    .frame(height: 52)
                                
                                Text("Delete")
                                    .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                    .foregroundStyle(AppColors.error)
                            }
                        }
                        .disabled(isSaving)
                        
                        Button(action: {
                            Task {
                                isSaving = true
                                let initialDate = ISO8601DateFormatter().date(from: appointment.timestamp)
                                if let initial = initialDate, selectedDate != initial {
                                    await updateAppointmentDate(to: selectedDate)
                                } else if initialDate == nil {
                                    await updateAppointmentDate(to: selectedDate)
                                }
                                
                                if let newStaffId = selectedStaffId, newStaffId != appointment.assignedTo {
                                    await assignStaff(to: appointment.id, staffId: newStaffId)
                                }
                                isSaving = false
                                dismiss()
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isSaving ? AppColors.gold.opacity(0.5) : AppColors.gold)
                                    .frame(height: 52)
                                
                                if isSaving {
                                    ProgressView().tint(AppColors.background)
                                } else {
                                    Text("Assign")
                                        .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                        .foregroundStyle(AppColors.background)
                                }
                            }
                        }
                        .disabled(isSaving)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .padding(.top, 20)
                
            }
            .background(AppColors.background)
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .alert("Delete Appointment", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    isSaving = true
                    await deleteAppointment(appointmentId: appointment.id)
                    isSaving = false
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this appointment? This action cannot be undone.")
        }
        .alert("Calendar", isPresented: $showingCalendarAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(calendarAlertMessage)
        }
        .task {
            await fetchAvailableStaff()
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    private func fetchAvailableStaff() async {
        do {
            if let (_, profile) = try await ProfileService().fetchCurrentProfile(),
               let boutique = profile as? CorporateBoutique {
                
                let fetched: [StaffModel] = try await SupabaseManager.shared.client
                    .from("staff")
                    .select()
                    .eq("boutique_id", value: boutique.id)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.availableStaff = fetched
                }
            }
        } catch {
            print("Failed to fetch available staff: \(error)")
        }
    }
    
    private func advisorName(for staffId: UUID?) -> String {
        guard let staffId = staffId else { return "Unassigned" }
        return availableStaff.first(where: { $0.id == staffId })?.name ?? "Unknown"
    }
    
    private func assignStaff(to appointmentId: UUID, staffId: UUID) async {
        struct UpdateStaffRequest: Encodable {
            let assigned_to: UUID
            let status: String
        }
        do {
            try await SupabaseManager.shared.client
                .from("appointment")
                .update(UpdateStaffRequest(assigned_to: staffId, status: AppointmentStatus.upcoming.rawValue))
                .eq("id", value: appointmentId)
                .execute()
            
            await MainActor.run {
                self.currentStatus = .upcoming
            }
            
            NotificationCenter.default.post(name: Notification.Name("RefreshAppointments"), object: nil)
        } catch {
            print("Failed to assign staff: \(error)")
        }
    }
    
    private func updateAppointmentDate(to newDate: Date) async {
        struct UpdateDateRequest: Encodable {
            let timestamp: String
        }
        
        let dateString = ISO8601DateFormatter().string(from: newDate)
        
        do {
            try await SupabaseManager.shared.client
                .from("appointment")
                .update(UpdateDateRequest(timestamp: dateString))
                .eq("id", value: appointment.id)
                .execute()
            
            NotificationCenter.default.post(name: Notification.Name("RefreshAppointments"), object: nil)
        } catch {
            print("Failed to update appointment date: \(error)")
        }
    }

    
    private func deleteAppointment(appointmentId: UUID) async {
        do {
            try await SupabaseManager.shared.client
                .from("appointment")
                .delete()
                .eq("id", value: appointmentId)
                .execute()
            NotificationCenter.default.post(name: Notification.Name("RefreshAppointments"), object: nil)
        } catch {
            print("Failed to delete appointment: \(error)")
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    let icon:  String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(AppFonts.sansSerif(size: 14))
                .foregroundStyle(AppColors.gold)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppFonts.sansSerif(size: 9, weight: .bold))
                    .foregroundStyle(AppColors.tertiary)
                    .kerning(1)
                Text(value)
                    .font(AppFonts.sansSerif(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.text)
            }
        }
    }
}

