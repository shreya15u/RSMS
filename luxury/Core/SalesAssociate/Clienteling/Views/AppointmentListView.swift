//
//  AppointmentListView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI
import Supabase
import PostgREST

struct AppointmentListView: View {
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AppointmentsViewModel()
    @State private var selectedDate = Date()
    
    @State private var selectedAppointment: AppointmentEntity?
    @State private var isShowingDetail = false
    @State private var showingAddSheet = false
    @State private var appointmentToDelete: AppointmentEntity?
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        RSMSCalendarView(selectedDate: $selectedDate) { date in
                            viewModel.hasAppointments(on: date)
                        }
                        .padding(.horizontal, 24)
                        
                        let dayAppointments = viewModel.appointmentsFor(date: selectedDate)
                        
                        if dayAppointments.isEmpty {
                            Text("No appointments for this day.")
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.secondary)
                                .padding(.top, 40)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            VStack(spacing: 30) {
                                ForEach(dayAppointments, id: \.timeBlock) { group in
                                    AppointmentGroupView(
                                        group: group,
                                        viewModel: viewModel,
                                        selectedAppointment: $selectedAppointment,
                                        isShowingDetail: $isShowingDetail,
                                        appointmentToDelete: $appointmentToDelete
                                    )
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
            }
            

        }
        .navigationTitle("Appointments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.fetchAppointments()
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showingAddSheet, onDismiss: {
            Task { await viewModel.fetchAppointments() }
        }) {
            CreateAppointmentView()
        }
        .alert(item: $appointmentToDelete) { a in
            Alert(
                title: Text("Delete Appointment"),
                message: Text("Are you sure you want to delete this appointment? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    Task {
                        await viewModel.deleteAppointment(a.id)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $isShowingDetail) {
            if let appt = selectedAppointment {
                AppointmentDetailSheet(appointment: appt, viewModel: viewModel)
            }
        }
    }
}

struct AppointmentGroupView: View {
    let group: (timeBlock: String, appointments: [AppointmentEntity])
    var viewModel: AppointmentsViewModel
    @Binding var selectedAppointment: AppointmentEntity?
    @Binding var isShowingDetail: Bool
    @Binding var appointmentToDelete: AppointmentEntity?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(group.timeBlock)
                .font(AppFonts.sansSerif(size: 10, weight: .bold))
                .foregroundStyle(AppColors.secondary)
                .kerning(1.8)
                .padding(.horizontal, 24)
            
            VStack(spacing: 10) {
                ForEach(group.appointments, id: \.id) { a in
                    Button(action: {
                        selectedAppointment = a
                        isShowingDetail = true
                    }) {
                        AppointmentRowView(a: a, viewModel: viewModel)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if a.createdBy == viewModel.currentStaffId && a.status == .pending {
                            Button(role: .destructive, action: {
                                appointmentToDelete = a
                            }) {
                                Label("Delete Appointment", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

struct AppointmentDetailSheet: View {
    let appointment: AppointmentEntity
    let viewModel: AppointmentsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(Router.self) private var router
    @State private var clientEntity: ClientEntity?
    @State private var isLoadingClient = false
    @State private var currentStatus: AppointmentStatus
    @State private var selectedDate: Date
    @State private var showingCalendarAlert = false
    @State private var calendarAlertMessage = ""
    
    init(appointment: AppointmentEntity, viewModel: AppointmentsViewModel) {
        self.appointment = appointment
        self.viewModel = viewModel
        _currentStatus = State(initialValue: appointment.status)
        let initialDate = ISO8601DateFormatter().date(from: appointment.timestamp) ?? Date()
        _selectedDate = State(initialValue: initialDate)
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Appointment Details")
                        .font(AppFonts.serif(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppColors.tertiary)
                    }
                }
                .padding(.top, 24)
                
                // Details Card
                VStack(spacing: 16) {
                    let canEdit = (viewModel.currentStaffId != nil && appointment.assignedTo == viewModel.currentStaffId)
                    
                    if canEdit {
                        DatePicker("Date & Time", selection: $selectedDate)
                            .datePickerStyle(.compact)
                            .tint(AppColors.gold)
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(AppColors.secondary)
                            .onChange(of: selectedDate) { _, newValue in
                                Task {
                                    await updateAppointmentDate(to: newValue)
                                }
                            }
                    } else {
                        detailRow(title: "Time", value: "\(appointment.formattedDate) at \(appointment.formattedTime)")
                    }
                    Divider().background(AppColors.border)
                    detailRow(title: "Type", value: appointment.displayAppointmentType)
                    Divider().background(AppColors.border)
                    
                    HStack {
                        Text("Status")
                            .font(AppFonts.sansSerif(size: 14))
                            .foregroundStyle(AppColors.secondary)
                        Spacer()
                        
                        if canEdit {
                            Picker("Status", selection: $currentStatus) {
                                ForEach(AppointmentStatus.allCases, id: \.self) { status in
                                    Text(status.displayStatus).tag(status)
                                }
                            }
                            .tint(AppColors.gold)
                            .onChange(of: currentStatus) { _, newValue in
                                Task {
                                    await viewModel.updateAppointmentStatus(appointmentId: appointment.id, newStatus: newValue)
                                    await MainActor.run {
                                        dismiss()
                                    }
                                }
                            }
                        } else {
                            Text(currentStatus.displayStatus)
                                .font(AppFonts.sansSerif(size: 14, weight: .medium))
                                .foregroundStyle(AppColors.gold)
                        }
                    }
                    
                    if let remarks = appointment.remarks, !remarks.isEmpty {
                        Divider().background(AppColors.border)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Remarks")
                                .font(AppFonts.sansSerif(size: 12))
                                .foregroundStyle(AppColors.secondary)
                            Text(remarks)
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(20)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                
                // Client Card
                if isLoadingClient {
                    ProgressView()
                        .tint(AppColors.gold)
                        .padding()
                } else if let ce = clientEntity {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("CLIENT")
                            .font(AppFonts.sansSerif(size: 10, weight: .bold))
                            .foregroundStyle(AppColors.secondary)
                            .kerning(1.5)
                        
                        HStack(spacing: 12) {
                            let clientModel = Client(entity: ce)
                            ZStack {
                                Circle().fill(AppColors.gold08).frame(width: 40, height: 40)
                                Text(clientModel.initial)
                                    .font(AppFonts.serif(size: 16, weight: .semibold))
                                    .foregroundStyle(AppColors.gold)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(clientModel.name)
                                    .font(AppFonts.sansSerif(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                Text(LocalizedStringKey(clientModel.tier.rawValue))
                                    .font(AppFonts.sansSerif(size: 12))
                                    .foregroundStyle(AppColors.gold)
                            }
                            Spacer()
                        }
                        
                        Button(action: {
                            dismiss()
                            // Slight delay to let sheet dismiss before pushing new view
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                let clientModel = Client(entity: ce)
                                router.push(SARoute.clientProfile(clientModel))
                            }
                        }) {
                            Text("Open Full Profile")
                                .font(AppFonts.sansSerif(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppColors.gold)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.gold15, lineWidth: 0.5))
                } else if appointment.clientId != nil {
                    Text("Could not load client details.")
                        .font(AppFonts.sansSerif(size: 14))
                        .foregroundStyle(AppColors.error)
                }
                
                Spacer()
                
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
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
        .alert("Calendar", isPresented: $showingCalendarAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(calendarAlertMessage)
        }
        .task {
            if let clientId = appointment.clientId {
                isLoadingClient = true
                do {
                    clientEntity = try await ClientService().fetchClient(id: clientId)
                } catch {
                    print("Error fetching client: \(error)")
                }
                isLoadingClient = false
            }
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AppFonts.sansSerif(size: 14))
                .foregroundStyle(AppColors.secondary)
            Spacer()
            Text(value)
                .font(AppFonts.sansSerif(size: 14, weight: .medium))
                .foregroundStyle(.white)
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
            await viewModel.fetchAppointments()
        } catch {
            print("Failed to update appointment date: \(error)")
        }
    }
}

struct AppointmentRowView: View {
    let a: AppointmentEntity
    var viewModel: AppointmentsViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Text(a.formattedTime)
                .font(AppFonts.sansSerif(size: 10, weight: .medium))
                .foregroundStyle(AppColors.gold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppColors.gold08)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.gold08)
                    .frame(width: 34, height: 34)
                Text("U")
                    .font(AppFonts.serif(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.gold)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(a.status.color)
                        .frame(width: 8, height: 8)
                        
                    if let cid = a.clientId, let ce = viewModel.clientsMap[cid] {
                        Text(Client(entity: ce).name)
                            .font(AppFonts.sansSerif(size: 13, weight: .medium))
                            .foregroundStyle(AppColors.text)
                    } else {
                        Text(a.clientId != nil ? "Client Appointment" : "Unknown Client")
                            .font(AppFonts.sansSerif(size: 13, weight: .medium))
                            .foregroundStyle(AppColors.text)
                    }
                }
                Text(a.displayAppointmentType)
                    .font(AppFonts.sansSerif(size: 11))
                    .foregroundStyle(AppColors.secondary)
            }
            
            Spacer()
            
            if a.status == .completed {
                ZStack {
                    Circle().fill(AppColors.success.opacity(0.15)).frame(width: 20, height: 20)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.success)
                }
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(a.status == .completed ? AppColors.surface.opacity(0.5) : AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(a.status == .completed ? AppColors.gold08 : AppColors.gold15, lineWidth: 0.5))
        .opacity(a.status == .completed ? 0.5 : 1.0)
    }
}
