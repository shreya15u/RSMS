//
//  BMPendingAppointmentsListView.swift
//  luxury
//
//  Created by AutoAgent on 03/06/26.
//

import SwiftUI
import Supabase
import PostgREST

struct BMPendingAppointmentsListView: View {
    @Environment(Router.self) private var router
    @State private var localAppointments: [AppointmentEntity]
    
    @State private var searchText = ""
    
    init(appointments: [AppointmentEntity]) {
        self._localAppointments = State(initialValue: appointments)
    }
    
    var filteredAppointments: [AppointmentEntity] {
        if searchText.isEmpty {
            return localAppointments
        } else {
            return localAppointments.filter {
                ($0.client?.name.localizedCaseInsensitiveContains(searchText) == true) ||
                $0.displayAppointmentType.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header & Search
                VStack(spacing: 16) {
                    HStack {
                        Button(action: {
                            router.pop()
                        }) {
                            Image(systemName: "arrow.left")
                                .font(AppFonts.sansSerif(size: 20))
                                .foregroundStyle(.white)
                        }
                        .padding(.trailing, 8)
                        
                        Text("Pending Appointments")
                            .font(AppFonts.serif(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.secondary)
                            .font(.system(size: 16, weight: .medium))
                        
                        TextField("Search by client or type", text: $searchText)
                            .font(AppFonts.sansSerif(size: 16))
                            .foregroundStyle(.white)
                            .tint(AppColors.gold)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppColors.tertiary)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 1))
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if filteredAppointments.isEmpty {
                            Text("No pending appointments found.")
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(AppColors.tertiary)
                                .padding(.horizontal, 24)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredAppointments) { appointment in
                                    Button(action: {
                                        router.push(BMRoute.appointmentDetail(appointment))
                                    }) {
                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(appointment.formattedTime)
                                                    .font(AppFonts.sansSerif(size: 14, weight: .bold))
                                                    .foregroundStyle(AppColors.gold)
                                                Text(appointment.displayAppointmentType.uppercased())
                                                    .font(AppFonts.sansSerif(size: 8, weight: .bold))
                                                    .foregroundStyle(AppColors.tertiary)
                                            }
                                            .frame(width: 65, alignment: .leading)
                                            
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(appointment.client?.name ?? "Unknown Client")
                                                    .font(AppFonts.serif(size: 17, weight: .medium))
                                                    .foregroundStyle(AppColors.text)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.8)
                                                
                                                Text("Unassigned")
                                                    .font(AppFonts.sansSerif(size: 10, weight: .semibold))
                                                    .foregroundStyle(AppColors.warning)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(AppColors.warning.opacity(0.15))
                                                    .clipShape(Capsule())
                                            }
                                            
                                            Spacer(minLength: 8)
                                            
                                            Text("Review")
                                                .font(AppFonts.sansSerif(size: 12, weight: .bold))
                                                .foregroundStyle(AppColors.background)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(AppColors.gold)
                                                .clipShape(Capsule())
                                        }
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 16)
                                        .background(AppColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(AppColors.gold15, lineWidth: 0.5)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("RefreshAppointments"))) { _ in
            Task {
                await fetchPendingAppointments()
            }
        }
    }
    
    private func fetchPendingAppointments() async {
        do {
            if let (_, profile) = try await ProfileService().fetchCurrentProfile(),
               let boutique = profile as? CorporateBoutique {
                
                let fetched: [AppointmentEntity] = try await SupabaseManager.shared.client
                    .from("appointment")
                    .select("*, client(*)")
                    .eq("boutique_id", value: boutique.id)
                    .eq("status", value: "pending")
                    .order("timestamp", ascending: true)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.localAppointments = fetched
                    if fetched.isEmpty {
                        router.pop() // Automatically go back if no more pending
                    }
                }
            }
        } catch {
            print("Failed to fetch pending appointments: \(error)")
        }
    }
}
