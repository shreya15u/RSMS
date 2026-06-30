//
//  CreateEventView.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var eventTitle: String = ""
    @State private var eventDate = Date()
    @State private var selectedType = "Trunk Show"
    @State private var eventDescription: String = ""
    
    // VIP Preview fields
    @State private var featuredCollection: String = ""
    @State private var venue: String = "VIP Salon"
    @State private var hostAssociate: String = "Sarah Connor"
    @State private var rsvpDeadline = Date().addingTimeInterval(86400 * 3) // default 3 days out
    @State private var reminderWindowHours: Int = 24
    
    let eventTypes = ["Trunk Show", "VIP Preview", "Product Launch", "Private Sale"]
    let venues = ["VIP Salon", "Milan Suite", "Garden Terrace", "Private Gallery", "Main Showroom"]
    let hostAssociates = ["Sarah Connor", "Alex Mercer", "Elena Fisher", "James Bond"]
    let reminderOptions = [12, 24, 48, 72]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppColors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        Text("Create Event")
                            .font(AppFonts.serif(size: 28, weight: .semibold))
                            .foregroundStyle(AppColors.text)
                            .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("EVENT TITLE")
                                .font(AppFonts.sansSerif(size: 10))
                                .foregroundStyle(AppColors.gold)
                                .kerning(2)
                            
                            TextField("e.g. Winter High Jewelry Gala", text: $eventTitle)
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("EVENT TYPE")
                                .font(AppFonts.sansSerif(size: 10))
                                .foregroundStyle(AppColors.gold)
                                .kerning(2)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(eventTypes, id: \.self) { type in
                                        let isSelected = selectedType == type
                                        Button(action: {
                                            selectedType = type
                                        }) {
                                            Text(type)
                                                .font(AppFonts.sansSerif(size: 12, weight: isSelected ? .medium : .light))
                                                .foregroundStyle(isSelected ? AppColors.background : AppColors.secondary)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(isSelected ? AppColors.gold : AppColors.surface)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.clear : AppColors.gold15, lineWidth: 0.5))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        if selectedType == "VIP Preview" || selectedType == "Trunk Show" || selectedType == "Product Launch" {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("FEATURED COLLECTION")
                                    .font(AppFonts.sansSerif(size: 10))
                                    .foregroundStyle(AppColors.gold)
                                    .kerning(2)
                                
                                TextField("e.g. Winter High Jewelry Collection", text: $featuredCollection)
                                    .font(AppFonts.sansSerif(size: 14))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .frame(height: 50)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("VENUE")
                                    .font(AppFonts.sansSerif(size: 10))
                                    .foregroundStyle(AppColors.gold)
                                    .kerning(2)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(venues, id: \.self) { item in
                                            let isSelected = venue == item
                                            Button(action: {
                                                venue = item
                                            }) {
                                                Text(item)
                                                    .font(AppFonts.sansSerif(size: 12, weight: isSelected ? .medium : .light))
                                                    .foregroundStyle(isSelected ? AppColors.background : AppColors.secondary)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .background(isSelected ? AppColors.gold : AppColors.surface)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.clear : AppColors.gold15, lineWidth: 0.5))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("ASSIGNED HOST ASSOCIATE")
                                    .font(AppFonts.sansSerif(size: 10))
                                    .foregroundStyle(AppColors.gold)
                                    .kerning(2)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(hostAssociates, id: \.self) { item in
                                            let isSelected = hostAssociate == item
                                            Button(action: {
                                                hostAssociate = item
                                            }) {
                                                Text(item)
                                                    .font(AppFonts.sansSerif(size: 12, weight: isSelected ? .medium : .light))
                                                    .foregroundStyle(isSelected ? AppColors.background : AppColors.secondary)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .background(isSelected ? AppColors.gold : AppColors.surface)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.clear : AppColors.gold15, lineWidth: 0.5))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("RSVP DEADLINE")
                                    .font(AppFonts.sansSerif(size: 10))
                                    .foregroundStyle(AppColors.gold)
                                    .kerning(2)
                                
                                HStack {
                                    Text("Select Deadline")
                                        .font(AppFonts.sansSerif(size: 14))
                                        .foregroundStyle(AppColors.text)
                                    Spacer()
                                    DatePicker("", selection: $rsvpDeadline, in: Date()...)
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                        .tint(AppColors.gold)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("AUTOMATIC REMINDER WINDOW")
                                    .font(AppFonts.sansSerif(size: 10))
                                    .foregroundStyle(AppColors.gold)
                                    .kerning(2)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(reminderOptions, id: \.self) { hours in
                                            let isSelected = reminderWindowHours == hours
                                            Button(action: {
                                                reminderWindowHours = hours
                                            }) {
                                                Text("\(hours)h before")
                                                    .font(AppFonts.sansSerif(size: 12, weight: isSelected ? .medium : .light))
                                                    .foregroundStyle(isSelected ? AppColors.background : AppColors.secondary)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .background(isSelected ? AppColors.gold : AppColors.surface)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.clear : AppColors.gold15, lineWidth: 0.5))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DATE & TIME")
                                .font(AppFonts.sansSerif(size: 10))
                                .foregroundStyle(AppColors.gold)
                                .kerning(2)
                            
                            RSMSCalendarView(selectedDate: $eventDate, disablePastDates: true)
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DESCRIPTION")
                                .font(AppFonts.sansSerif(size: 10))
                                .foregroundStyle(AppColors.gold)
                                .kerning(2)
                            
                            TextEditor(text: $eventDescription)
                                .font(AppFonts.sansSerif(size: 14))
                                .foregroundStyle(.white)
                                .padding(12)
                                .frame(height: 120)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gold15, lineWidth: 0.5))
                                .scrollContentBackground(.hidden)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 140)
                    }
                }
                
                // Pinned bottom button with gradient overlay
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [AppColors.background.opacity(0), AppColors.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 24)
                    
                    VStack(spacing: 0) {
                        CustomButton(title: "Launch Event", action: {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "dd MMMM yyyy"
                            let dateString = formatter.string(from: eventDate)
                            
                            let guestsList: [VIPGuest]? = nil
                            var featured: String? = nil
                            var vVenue: String? = nil
                            var assignedHost: String? = nil
                            var deadlineVal: Date? = nil
                            var windowHoursVal: Int? = nil
                            
                            if selectedType == "VIP Preview" || selectedType == "Trunk Show" || selectedType == "Product Launch" {
                                featured = featuredCollection.isEmpty ? (selectedType == "Trunk Show" ? "Exclusive Seasonal Collection" : (selectedType == "Product Launch" ? "Exclusive Product Launch" : "Exclusive Winter Preview")) : featuredCollection
                                vVenue = venue
                                assignedHost = hostAssociate
                                deadlineVal = rsvpDeadline
                                windowHoursVal = reminderWindowHours
                            }
                            
                            let newEvent = StoreEvent(
                                title: eventTitle.isEmpty ? (selectedType == "Trunk Show" ? "New Trunk Show" : (selectedType == "Product Launch" ? "New Product Launch" : "New VIP Preview")) : eventTitle,
                                date: dateString,
                                rsvpCount: 0,
                                type: selectedType == "VIP Preview" ? "VIP PREVIEW" : (selectedType == "Trunk Show" ? "TRUNK SHOW" : (selectedType == "Product Launch" ? "PRODUCT LAUNCH" : selectedType.uppercased())),
                                featuredCollection: featured,
                                venue: vVenue,
                                hostAssociate: assignedHost,
                                guests: guestsList,
                                deadline: deadlineVal,
                                reminderWindowHours: windowHoursVal,
                                remindersSent: false
                            )
                            
                            let viewModel = StoreViewModel()
                            viewModel.addEvent(newEvent)
                            
                            dismiss()
                        })
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                    .background(AppColors.background)
                }
            }
            .navigationTitle("Store Operations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(AppFonts.sansSerif(size: 20, weight: .semibold))
                            .foregroundStyle(AppColors.gold)
                    }
                }
            }
        }
    }
}
