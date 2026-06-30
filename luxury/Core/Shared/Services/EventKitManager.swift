import Foundation
import EventKit
import EventKitUI
import Combine

@MainActor
class EventKitManager: NSObject, ObservableObject {
    static let shared = EventKitManager()
    let eventStore = EKEventStore()
    
    @Published var permissionGranted = false
    
    private override init() {
        super.init()
        checkPermission()
    }
    
    func checkPermission() {
        let status = EKEventStore.authorizationStatus(for: .event)
        permissionGranted = (status == .fullAccess || status == .writeOnly)
    }
    
    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            self.permissionGranted = granted
            return granted
        } catch {
            print("Failed to request calendar access: \(error)")
            return false
        }
    }
    
    func addEventToCalendar(title: String, startDate: Date, durationMinutes: Int = 60, notes: String? = nil, location: String? = nil) {
        guard permissionGranted else { return }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(TimeInterval(durationMinutes * 60))
        event.notes = notes
        event.location = location
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("Successfully added event to calendar.")
        } catch {
            print("Failed to save event: \(error)")
        }
    }
}
