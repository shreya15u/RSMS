//
//  NotesService.swift
//  luxury
//
//  Created by Nalinish Ranjan on 26/05/26.
//

import Foundation
import Supabase

struct DBClientNote: Codable {
    let id: UUID
    let clientId: UUID
    let note: String
    let date: String
    let salesAssociateId: UUID
    let authorName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case note
        case date
        case salesAssociateId = "sales_associate_id"
        case authorName = "author_name"
    }
}

final class NotesService {
    static let shared = NotesService()
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    private func localKey(for clientId: UUID) -> String {
        return "luxury_notes_\(clientId.uuidString)"
    }
    
    func fetchNotes(clientId: UUID) -> [ClientNote] {
        let key = localKey(for: clientId)
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                return try JSONDecoder().decode([ClientNote].self, from: data)
            } catch {
                print("Error decoding local notes: \(error)")
            }
        }
        return []
    }
    
    func saveLocalNotes(_ notes: [ClientNote], for clientId: UUID) {
        let key = localKey(for: clientId)
        do {
            let data = try JSONEncoder().encode(notes)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Error encoding local notes: \(error)")
        }
    }
    
    func syncNotes(clientId: UUID) async {
        do {
            let response = try await client
                .from("client_notes")
                .select()
                .eq("client_id", value: clientId.uuidString)
                .execute()
            
            let dbNotes = try JSONDecoder().decode([DBClientNote].self, from: response.data)
            let clientNotes = dbNotes.map { ClientNote(id: $0.id, note: $0.note, date: $0.date, salesAssociateId: $0.salesAssociateId, authorName: $0.authorName) }
            // Sort by date (assuming date string is sortable or just rely on DB order if we added .order, but for now just reverse if needed, or DB order)
            saveLocalNotes(clientNotes, for: clientId)
        } catch {
            print("Error syncing notes from Supabase: \(error)")
        }
    }
    
    func addNote(clientId: UUID, noteText: String) async {
        guard let session = try? await client.auth.session else {
            print("No active session, cannot add note.")
            return
        }
        let saId = session.user.id
        var saName = session.user.userMetadata["full_name"]?.stringValue ?? "Sales Associate"
        
        if let staff: StaffModel = try? await client.from("staff").select().eq("auth_user_id", value: saId).single().execute().value {
            saName = staff.name.isEmpty ? saName : staff.name
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        let dateStr = formatter.string(from: Date())
        
        let newNote = ClientNote(note: noteText, date: dateStr, salesAssociateId: saId, authorName: saName)
        
        var current = fetchNotes(clientId: clientId)
        current.insert(newNote, at: 0)
        saveLocalNotes(current, for: clientId)
        
        do {
            let dbNote = DBClientNote(id: newNote.id, clientId: clientId, note: noteText, date: dateStr, salesAssociateId: saId, authorName: saName)
            try await client
                .from("client_notes")
                .insert(dbNote)
                .execute()
        } catch {
            print("Error adding note to Supabase: \(error)")
        }
    }
    
    func deleteNote(clientId: UUID, noteId: UUID) async {
        // 1. Update local storage immediately for responsive UI
        var current = fetchNotes(clientId: clientId)
        current.removeAll { $0.id == noteId }
        saveLocalNotes(current, for: clientId)
        
        // 2. Perform background synchronization
        do {
            try await client
                .from("client_notes")
                .delete()
                .eq("id", value: noteId.uuidString)
                .execute()
        } catch {
            print("Error deleting note from Supabase: \(error)")
        }
    }
    
    func updateNote(clientId: UUID, noteId: UUID, noteText: String) async {
        // 1. Update local storage
        var current = fetchNotes(clientId: clientId)
        if let idx = current.firstIndex(where: { $0.id == noteId }) {
            current[idx].note = noteText
            saveLocalNotes(current, for: clientId)
        }
        
        // 2. Perform background sync
        do {
            struct UpdateNoteRequest: Codable {
                let note: String
            }
            try await client
                .from("client_notes")
                .update(UpdateNoteRequest(note: noteText))
                .eq("id", value: noteId.uuidString)
                .execute()
        } catch {
            print("Error updating note in Supabase: \(error)")
        }
    }
}
