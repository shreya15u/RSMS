//
//  SellingFlowViews.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI
import SafariServices

struct RemoteSellingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var appointmentLinked = true
    @State private var showingVideoOptions = false
    @State private var showingVideoCall = false
    @State private var isGeneratingLink = false
    @State private var currentMeetingLink: String = ""
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                FlowHeader(title: "Remote Selling", dismiss: dismiss)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        StatusBadge(text: appointmentLinked ? LocalizedStringKey("Appointment Linked") : LocalizedStringKey("Draft"), status: appointmentLinked ? .success : .pending)
                        

                        Toggle("Link to Unknown Client 2:30 PM appointment", isOn: $appointmentLinked)
                            .font(AppFonts.sansSerif(size: 13))
                            .foregroundStyle(AppColors.text)
                            .toggleStyle(LuxuryToggleStyle())
                            .padding(14)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        CustomButton(title: isGeneratingLink ? "Generating Secure Room..." : "Create Remote Appointment", icon: AnyView(Image(systemName: isGeneratingLink ? "arrow.2.circlepath" : "video.fill"))) {
                            if !isGeneratingLink {
                                generateMeetingLink()
                            }
                        }
                        .disabled(isGeneratingLink)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .confirmationDialog("Video Consultation Setup", isPresented: $showingVideoOptions, titleVisibility: .visible) {
            Button("Join Call Now") {
                if URL(string: currentMeetingLink) != nil {
                    showingVideoCall = true
                }
            }
            Button("Copy Link") {
                UIPasteboard.general.string = currentMeetingLink
            }
            Button("Send via Email") {
                if let subject = "Your RSMS Remote Consultation".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let body = "Please click the link below to join your secure remote consultation:\n\n\(currentMeetingLink)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: "mailto:?subject=\(subject)&body=\(body)") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Meeting Link: \(currentMeetingLink)")
        }
        .fullScreenCover(isPresented: $showingVideoCall) {
            if let url = URL(string: currentMeetingLink) {
                ZStack(alignment: .topTrailing) {
                    JitsiWebView(url: url)
                        .ignoresSafeArea()
                    
                    Button(action: { showingVideoCall = false }) {
                        Text("Close")
                            .font(AppFonts.sansSerif(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.text)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding()
                }
            }
        }
    }
    
    private func generateMeetingLink() {
        if !currentMeetingLink.isEmpty {
            showingVideoOptions = true
            return
        }
        
        let roomName = "RSMS-Consultation-\(UUID().uuidString.prefix(8))"
        currentMeetingLink = "https://meet.element.io/\(roomName)#config.prejoinPageEnabled=false&config.disableDeepLinking=true"
        showingVideoOptions = true
    }
}

private struct FlowHeader: View {
    let title: String
    let dismiss: DismissAction
    
    var body: some View {
    }
}

