//
//  AppointmentsViewModel.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import Foundation
import Observation
import Supabase

@Observable
final class AppointmentsViewModel {
    var appointments: [AppointmentEntity] = []
    var clientsMap: [UUID: ClientEntity] = [:]
    var isLoading = false
    var errorMessage: String?
    var currentStaffId: UUID?
    
    private let client = SupabaseManager.shared.client
    private let profileService = ProfileService()
    
    var currentMonthDays: [(Int, String, String)] = {
        let calendar = Calendar.current
        let today = Date()
        let range = calendar.range(of: .day, in: .month, for: today)!
        let month = calendar.component(.month, from: today)
        let year = calendar.component(.year, from: today)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        
        return range.map { day -> (Int, String, String) in
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            let date = calendar.date(from: components)!
            let weekdayStr = formatter.string(from: date)
            return (day, weekdayStr, "\(day)")
        }
    }()
    
    var remainingCount: Int {
        appointments.filter { $0.status != .completed }.count
    }
    
    func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    func weeksInMonth(for date: Date) -> [[Date?]] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var weeks: [[Date?]] = []
        var currentWeekStart = monthFirstWeek.start
        
        while currentWeekStart < monthInterval.end {
            var week: [Date?] = []
            for dayOffset in 0..<7 {
                if let day = calendar.date(byAdding: .day, value: dayOffset, to: currentWeekStart) {
                    if calendar.isDate(day, equalTo: date, toGranularity: .month) {
                        week.append(day)
                    } else {
                        week.append(nil)
                    }
                } else {
                    week.append(nil)
                }
            }
            weeks.append(week)
            
            guard let nextWeek = calendar.date(byAdding: .weekOfMonth, value: 1, to: currentWeekStart) else {
                break
            }
            currentWeekStart = nextWeek
        }
        
        return weeks
    }
    
    func hasAppointments(on date: Date) -> Bool {
        let calendar = Calendar.current
        return appointments.contains { appt in
            guard let apptDate = ISO8601DateFormatter().date(from: appt.timestamp) else { return false }
            return calendar.isDate(apptDate, inSameDayAs: date)
        }
    }
    
    func appointmentsFor(date: Date) -> [(timeBlock: String, appointments: [AppointmentEntity])] {
        let calendar = Calendar.current
        
        let filtered = appointments.filter { appt in
            guard let apptDate = ISO8601DateFormatter().date(from: appt.timestamp) else { return false }
            return calendar.isDate(apptDate, inSameDayAs: date)
        }
        
        var morning: [AppointmentEntity] = []
        var afternoon: [AppointmentEntity] = []
        var evening: [AppointmentEntity] = []
        
        for appt in filtered {
            guard let date = ISO8601DateFormatter().date(from: appt.timestamp) else { continue }
            let hour = calendar.component(.hour, from: date)
            if hour < 12 {
                morning.append(appt)
            } else if hour < 17 {
                afternoon.append(appt)
            } else {
                evening.append(appt)
            }
        }
        
        var result: [(timeBlock: String, appointments: [AppointmentEntity])] = []
        if !morning.isEmpty { result.append(("MORNING", morning.sorted { $0.timestamp < $1.timestamp })) }
        if !afternoon.isEmpty { result.append(("AFTERNOON", afternoon.sorted { $0.timestamp < $1.timestamp })) }
        if !evening.isEmpty { result.append(("EVENING", evening.sorted { $0.timestamp < $1.timestamp })) }
        
        return result
    }
    
    @MainActor
    func fetchAppointments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let session = try? await client.auth.session else {
                throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])
            }
            
            // First fetch the staff profile
            let staff: StaffModel = try await client.from("staff")
                .select()
                .eq("auth_user_id", value: session.user.id)
                .single()
                .execute()
                .value
            
            self.currentStaffId = staff.id
            
            // Fetch appointments where the SA is the creator OR the assigned staff
            let fetched: [AppointmentEntity] = try await client.from("appointment")
                .select("*, client(*)")
                .or("created_by.eq.\(staff.id),assigned_to.eq.\(staff.id)")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.appointments = fetched
            
            // Fetch associated clients
            let clientIds = Array(Set(fetched.compactMap { $0.clientId }))
            if !clientIds.isEmpty {
                let fetchedClients: [ClientEntity] = try await client.from("client")
                    .select()
                    .in("id", values: clientIds)
                    .execute()
                    .value
                
                for c in fetchedClients {
                    self.clientsMap[c.id] = c
                }
            }
        } catch {
            print("Failed to fetch appointments: \(error)")
            self.errorMessage = error.localizedDescription
            self.appointments = []
        }
        isLoading = false
    }
    
    @MainActor
    func updateAppointmentStatus(appointmentId: UUID, newStatus: AppointmentStatus) async {
        struct UpdateStatusRequest: Encodable {
            let status: String
        }
        
        do {
            try await client.from("appointment")
                .update(UpdateStatusRequest(status: newStatus.rawValue))
                .eq("id", value: appointmentId)
                .execute()
            
            // Refresh local data after update
            await fetchAppointments()
        } catch {
            print("Failed to update status: \(error)")
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func deleteAppointment(_ id: UUID) async {
        do {
            try await client.from("appointment")
                .delete()
                .eq("id", value: id)
                .execute()
            NotificationCenter.default.post(name: Notification.Name("RefreshAppointments"), object: nil)
            await fetchAppointments()
        } catch {
            print("Failed to delete appointment: \(error)")
            self.errorMessage = error.localizedDescription
        }
    }
}
