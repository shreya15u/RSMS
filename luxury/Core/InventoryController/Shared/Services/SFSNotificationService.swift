//
//  SFSNotificationService.swift
//  luxury
//

import Foundation
import Observation
import Supabase
import UserNotifications
import UIKit

@Observable
final class SFSNotificationService {
    var hasNewOrder: Bool = false
    var lastOrderMessage: String = ""
    
    private var channel: RealtimeChannelV2?
    
    func startListening() {
        channel = SupabaseManager.shared.client.realtimeV2.channel("sfs_notifications")
        
        Task {
            for await event in channel!.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "purchased_items"
            ) {
                if let status = event.record["status"]?.stringValue, status == "Pending" {
                    await MainActor.run {
                        let idRaw = event.record["id"]?.stringValue ?? "Unknown"
                        self.showAlert(idRaw: idRaw)
                    }
                }
            }
        }
        
        Task {
            for await event in channel!.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "purchased_items"
            ) {
                if let status = event.record["status"]?.stringValue, status == "Pending" {
                    await MainActor.run {
                        let idRaw = event.record["id"]?.stringValue ?? "Unknown"
                        self.showAlert(idRaw: idRaw)
                    }
                }
            }
        }
        
        Task {
            try? await channel?.subscribeWithError()
        }
    }
    
    private func showAlert(idRaw: String) {
        let prefix = idRaw.prefix(8).uppercased()
        lastOrderMessage = "SFS Order Ready: \(prefix)"
        hasNewOrder = true
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        NotificationCenter.default.post(name: NSNotification.Name("SFSOrderReceived"), object: nil)
        
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            await MainActor.run {
                self.hasNewOrder = false
            }
        }
    }
    
    func stopListening() {
        Task {
            if let channel = channel {
                await SupabaseManager.shared.client.removeChannel(channel)
            }
        }
    }
}
